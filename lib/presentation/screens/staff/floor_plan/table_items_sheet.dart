import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/item_model.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/table_model.dart';
import '../../../../data/repositories/order_repository.dart';
import '../../../../providers/menu_provider.dart';
import '../../../../providers/order_provider.dart';

class TableItemsSheet extends ConsumerStatefulWidget {
  final TableModel table;
  const TableItemsSheet({super.key, required this.table});
  @override
  ConsumerState<TableItemsSheet> createState() => _TableItemsSheetState();
}

class _TableItemsSheetState extends ConsumerState<TableItemsSheet> {
  List<ItemModel> _items = [];
  OrderModel? _order;
  final _quantities = <String, int>{};
  final _notes = <String, String>{};
  bool _loading = true;
  bool _saving = false;
  bool _uncertain = false;
  String? _error;
  String _search = '';

  String _key(ItemModel item) =>
      '${item.isCombo ? 'combo' : 'item'}:${item.id}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Independent catalog; customer tab filters cannot hide staff's menu.
      final catalog = ref.read(menuRepositoryProvider);
      final results = await Future.wait<Object?>([
        ref.read(orderRepositoryProvider).getActiveTableOrder(widget.table.id),
        catalog.getItems(),
      ]);
      if (!mounted) return;
      setState(() {
        _order = results[0] as OrderModel?;
        _items = (results[1] as List<ItemModel>)
            .where((item) => item.isAvailable)
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = apiErrorMessage(error);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_saving || _loading || _uncertain || _error != null) return;
    final lines = [
      for (final item in _items)
        if ((_quantities[_key(item)] ?? 0) > 0)
          TableOrderLine(
              item: item,
              quantity: _quantities[_key(item)]!,
              note: _notes[_key(item)])
    ];
    if (lines.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .addItemsAtTable(widget.table.id, lines, expectedOrderId: _order?.id);
      if (mounted) Navigator.pop(context, order);
    } catch (error) {
      if (!mounted) return;
      final ambiguous = error is! DioException ||
          error.response == null ||
          (error.response?.statusCode ?? 500) >= 500;
      setState(() {
        _saving = false;
        _uncertain = ambiguous;
        _error = ambiguous
            ? 'Chưa xác định được kết quả gửi món. Đóng và kiểm tra đơn/bếp trước khi gọi lại để tránh trùng món.'
            : apiErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _quantities.values.fold<int>(0, (sum, qty) => sum + qty);
    final visible = _items
        .where(
            (item) => item.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return PopScope(
        canPop: !_saving,
        child: SafeArea(
          child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.88,
                  child: Column(children: [
                    ListTile(
                        title: Text('Gọi món • ${widget.table.name}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_loading
                            ? 'Đang kiểm tra đơn và thực đơn…'
                            : _order == null
                                ? 'Tạo đơn mới khi gửi món'
                                : 'Đơn ${_order!.code}'),
                        trailing: IconButton(
                            tooltip: 'Đóng',
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.close))),
                    if (_loading || _saving) const LinearProgressIndicator(),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(children: [
                            Text(_error!,
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.error)),
                            if (!_uncertain)
                              TextButton(
                                  onPressed: _saving ? null : _load,
                                  child: const Text('Tải lại đơn & thực đơn'))
                          ])),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                            enabled: !_saving,
                            decoration: const InputDecoration(
                                labelText: 'Tìm món hoặc combo',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder()),
                            onChanged: (value) =>
                                setState(() => _search = value))),
                    Expanded(
                        child: _loading
                            ? const SizedBox.shrink()
                            : visible.isEmpty
                                ? const Center(
                                    child: Text(
                                        'Không có món còn phục vụ phù hợp.'))
                                : ListView.builder(
                                    itemCount: visible.length,
                                    itemBuilder: (context, index) {
                                      final item = visible[index];
                                      final key = _key(item);
                                      final qty = _quantities[key] ?? 0;
                                      final disabled = _saving ||
                                          _uncertain ||
                                          _error != null;
                                      return Card(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        '${item.isCombo ? 'Combo • ' : ''}${item.name}',
                                                        style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    Row(children: [
                                                      Expanded(
                                                          child: Text(
                                                              CurrencyFormatter
                                                                  .format(item
                                                                      .displayPrice))),
                                                      IconButton(
                                                          tooltip:
                                                              'Giảm ${item.name}',
                                                          onPressed: disabled ||
                                                                  qty == 0
                                                              ? null
                                                              : () => setState(() =>
                                                                  _quantities[
                                                                          key] =
                                                                      qty - 1),
                                                          icon: const Icon(Icons
                                                              .remove_circle_outline)),
                                                      Text('$qty',
                                                          key: ValueKey(
                                                              'quantity-$key')),
                                                      IconButton(
                                                          tooltip:
                                                              'Thêm ${item.name}',
                                                          onPressed: disabled ||
                                                                  qty >= 99
                                                              ? null
                                                              : () => setState(() =>
                                                                  _quantities[
                                                                          key] =
                                                                      qty + 1),
                                                          icon: const Icon(Icons
                                                              .add_circle_outline)),
                                                    ]),
                                                    if (qty > 0)
                                                      TextFormField(
                                                          key: ValueKey(
                                                              'note-$key'),
                                                          initialValue:
                                                              _notes[key],
                                                          enabled: !disabled,
                                                          maxLength: 250,
                                                          decoration:
                                                              const InputDecoration(
                                                                  labelText:
                                                                      'Ghi chú cho bếp'),
                                                          onChanged: (value) =>
                                                              _notes[key] =
                                                                  value),
                                                  ])));
                                    })),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                                key: const ValueKey('send-table-items'),
                                onPressed: _saving ||
                                        _loading ||
                                        _uncertain ||
                                        _error != null ||
                                        selected == 0
                                    ? null
                                    : _submit,
                                icon: const Icon(Icons.send),
                                label: Text(_saving
                                    ? 'Đang gửi…'
                                    : 'Gửi $selected món vào bếp')))),
                  ]))),
        ));
  }
}
