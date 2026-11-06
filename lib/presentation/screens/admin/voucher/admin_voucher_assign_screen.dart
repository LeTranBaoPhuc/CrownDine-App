import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/admin_voucher_model.dart';
import '../../../../data/models/voucher_assignment_model.dart';
import '../../../../data/repositories/admin_voucher_repository.dart';

class AdminVoucherAssignScreen extends StatefulWidget {
  final AdminVoucherModel voucher;
  final AdminVoucherRepository? repository;
  const AdminVoucherAssignScreen(
      {super.key, required this.voucher, this.repository});

  @override
  State<AdminVoucherAssignScreen> createState() =>
      _AdminVoucherAssignScreenState();
}

class _AdminVoucherAssignScreenState extends State<AdminVoucherAssignScreen> {
  late final AdminVoucherRepository _repo =
      widget.repository ?? AdminVoucherRepository();
  final _search = TextEditingController();
  final _limit = TextEditingController(text: '1');
  final _selected = <int>{};
  List<VoucherCustomerModel>? _customers;
  List<VoucherAssignmentModel>? _assignments;
  DateTime? _expiry;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _limit.dispose();
    super.dispose();
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Không kết nối được máy chủ. Vui lòng thử lại.';
    }
    if (error is FormatException) return error.message;
    return 'Không thể cấp voucher. Vui lòng thử lại.';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final customers = await _repo.customers();
      final assignments = await _repo.assignments(widget.voucher.id);
      if (!mounted) return;
      setState(() {
        _customers = customers;
        _assignments = assignments;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _message(error);
        });
      }
    }
  }

  Future<void> _chooseExpiry() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 10),
      initialDate: _expiry ?? today.add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      setState(
          () => _expiry = DateTime(date.year, date.month, date.day, 23, 59));
    }
  }

  Future<void> _assign() async {
    if (_saving || _selected.isEmpty) return;
    final limit = int.tryParse(_limit.text.trim());
    if (limit == null || limit <= 0) {
      setState(() => _error = 'Số lượt cấp phải lớn hơn 0.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.assign(widget.voucher.id,
          userIds: _selected.toList(), usageLimit: limit, expiredAt: _expiry);
      if (!mounted) return;
      final count = _selected.length;
      _selected.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cấp voucher cho $count khách.')),
      );
      await _load();
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = _customers ?? [];
    final query = _search.text.trim().toLowerCase();
    final filtered = customers
        .where((c) =>
            query.isEmpty ||
            c.name.toLowerCase().contains(query) ||
            c.username.toLowerCase().contains(query) ||
            (c.phone?.contains(query) ?? false) ||
            (c.email?.toLowerCase().contains(query) ?? false))
        .toList();
    final assignedByCustomer = {
      for (final item in _assignments ?? <VoucherAssignmentModel>[])
        item.customerId: item,
    };
    return Scaffold(
      appBar: AppBar(title: Text('Cấp ${widget.voucher.code}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text('Voucher: ${widget.voucher.name}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Khách đã có voucher sẽ được cộng thêm số lượt cấp.'),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Tìm khách theo tên, tài khoản, email hoặc SĐT',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (_error != null && _customers == null)
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          if (!_loading && _customers != null) ...[
            const SizedBox(height: 12),
            Text('Chọn khách (${_selected.length})',
                style: Theme.of(context).textTheme.titleSmall),
            if (filtered.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Không tìm thấy khách hàng.')),
            ...filtered.map((customer) {
              final existing = assignedByCustomer[customer.id];
              return CheckboxListTile(
                value: _selected.contains(customer.id),
                onChanged: _saving
                    ? null
                    : (selected) => setState(() {
                          if (selected == true) {
                            _selected.add(customer.id);
                          } else {
                            _selected.remove(customer.id);
                          }
                        }),
                title: Text(customer.name),
                subtitle: Text('${customer.username}'
                    '${customer.phone == null ? '' : ' · ${customer.phone}'}'
                    '${existing == null ? '' : ' · Còn ${existing.remaining ?? '∞'} lượt'}'),
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _limit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Số lượt cấp cho mỗi khách',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: Text(_expiry == null
                      ? 'Không giới hạn ngày hết hạn'
                      : 'Hết hạn: ${_expiry!.day}/${_expiry!.month}/${_expiry!.year}')),
              TextButton(
                  onPressed: _chooseExpiry, child: const Text('Chọn ngày')),
              if (_expiry != null)
                IconButton(
                    onPressed: () => setState(() => _expiry = null),
                    icon: const Icon(Icons.clear),
                    tooltip: 'Bỏ ngày hết hạn'),
            ]),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving || _selected.isEmpty ? null : _assign,
              icon: const Icon(Icons.card_giftcard),
              label: Text(
                  _saving ? 'Đang cấp…' : 'Cấp cho ${_selected.length} khách'),
            ),
            const SizedBox(height: 20),
            Text('Đã cấp (${_assignments?.length ?? 0})',
                style: Theme.of(context).textTheme.titleMedium),
            if (_assignments?.isEmpty == true)
              const Text('Chưa cấp cho khách nào.'),
            ...?_assignments?.map((assignment) => ListTile(
                  title: Text(assignment.name),
                  subtitle: Text(
                      '${assignment.username} · Đã dùng ${assignment.usageCount}'
                      ' / ${assignment.usageLimit ?? '∞'}'
                      '${assignment.expiredAt == null ? '' : ' · Hết hạn ${assignment.expiredAt!.day}/${assignment.expiredAt!.month}/${assignment.expiredAt!.year}'}'),
                  trailing: Text('Còn ${assignment.remaining ?? '∞'}'),
                )),
          ],
        ]),
      ),
    );
  }
}
