import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/admin_voucher_model.dart';
import '../../../../data/repositories/admin_voucher_repository.dart';

class AdminVoucherScreen extends StatefulWidget {
  final AdminVoucherRepository? repository;
  const AdminVoucherScreen({super.key, this.repository});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  late final AdminVoucherRepository _repo =
      widget.repository ?? AdminVoucherRepository();
  final _search = TextEditingController();
  AdminVoucherPage? _page;
  AdminVoucherType? _type;
  bool _loading = false;
  bool _saving = false;
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  @override
  void dispose() {
    _request++;
    _search.dispose();
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
    return 'Không xử lý được voucher. Vui lòng thử lại.';
  }

  Future<void> _load(int page) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result =
          await _repo.list(page: page, search: _search.text, type: _type);
      if (mounted && request == _request) {
        setState(() {
          _page = result;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = _message(error);
        });
      }
    }
  }

  Future<void> _edit([AdminVoucherModel? voucher]) async {
    if (_saving) return;
    AdminVoucherModel? current = voucher;
    if (voucher != null) {
      setState(() => _saving = true);
      try {
        current = await _repo.get(voucher.id);
      } catch (error) {
        if (mounted) _showError(error);
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
    if (!mounted) return;
    final draft = await showModalBottomSheet<AdminVoucherDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VoucherForm(initial: current),
    );
    if (draft == null || !mounted) return;
    setState(() => _saving = true);
    try {
      if (voucher == null) {
        await _repo.create(draft);
      } else {
        await _repo.update(voucher.id, draft);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(voucher == null ? 'Đã tạo voucher.' : 'Đã cập nhật voucher.'),
        backgroundColor: AppColors.success,
      ));
      await _load(voucher == null ? 1 : (_page?.page ?? 1));
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(AdminVoucherModel voucher) async {
    if (_saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa voucher?'),
        content: Text(
            'Xóa ${voucher.code}? Voucher đã cấp hoặc được dùng sẽ không thể xóa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _repo.delete(voucher.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa voucher.')),
      );
      final page = _page?.page ?? 1;
      await _load((_page?.items.length == 1 && page > 1) ? page - 1 : page);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(Object error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_message(error))),
      );

  String _discount(AdminVoucherModel voucher) {
    if (voucher.type == AdminVoucherType.fixedAmount) {
      return CurrencyFormatter.format(voucher.discountValue);
    }
    final percent = '${voucher.discountValue.toStringAsFixed(0)}%';
    return voucher.maxDiscountValue == null
        ? percent
        : '$percent · tối đa ${CurrencyFormatter.format(voucher.maxDiscountValue)}';
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _load(page?.page ?? 1),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            const Expanded(
                child: Text('Quản lý voucher',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            FilledButton.icon(
              onPressed: _saving ? null : () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Tạo mới'),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(1),
            decoration: InputDecoration(
              hintText: 'Tìm theo mã hoặc tên',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                  onPressed: () => _load(1),
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Tìm'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<AdminVoucherType?>(
            initialValue: _type,
            decoration: const InputDecoration(
                labelText: 'Loại voucher', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: null, child: Text('Tất cả')),
              DropdownMenuItem(
                  value: AdminVoucherType.percentage,
                  child: Text('Giảm theo %')),
              DropdownMenuItem(
                  value: AdminVoucherType.fixedAmount,
                  child: Text('Giảm số tiền')),
            ],
            onChanged: (value) {
              _type = value;
              _load(1);
            },
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                TextButton(
                    onPressed: () => _load(page?.page ?? 1),
                    child: const Text('Thử lại')),
              ]),
            ),
          if (!_loading && _error == null && page != null) ...[
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('${page.totalItems} voucher')),
            if (page.items.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Chưa có voucher nào.'))),
            ...page.items.map((voucher) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(voucher.code,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary))),
                            IconButton(
                                onPressed:
                                    _saving ? null : () => _edit(voucher),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Sửa voucher'),
                            IconButton(
                                onPressed:
                                    _saving ? null : () => _delete(voucher),
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Xóa voucher'),
                          ]),
                          Text(voucher.name),
                          if (voucher.description.isNotEmpty)
                            Text(voucher.description),
                          const SizedBox(height: 6),
                          Text('Giảm: ${_discount(voucher)}'),
                          if (voucher.minValue != null)
                            Text(
                                'Đơn tối thiểu: ${CurrencyFormatter.format(voucher.minValue)}'),
                        ],
                      )),
                )),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  onPressed: _loading || page.page <= 1
                      ? null
                      : () => _load(page.page - 1),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Trang trước'),
              Text(
                  'Trang ${page.page}/${page.totalPages == 0 ? 1 : page.totalPages}'),
              IconButton(
                  onPressed: _loading || page.page >= page.totalPages
                      ? null
                      : () => _load(page.page + 1),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Trang sau'),
            ]),
          ],
        ]),
      ),
    );
  }
}

class _VoucherForm extends StatefulWidget {
  final AdminVoucherModel? initial;
  const _VoucherForm({this.initial});

  @override
  State<_VoucherForm> createState() => _VoucherFormState();
}

class _VoucherFormState extends State<_VoucherForm> {
  final _form = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.initial?.code ?? '');
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _value = TextEditingController(
      text: widget.initial?.discountValue.toString() ?? '');
  late final _max = TextEditingController(
      text: widget.initial?.maxDiscountValue?.toString() ?? '');
  late final _min =
      TextEditingController(text: widget.initial?.minValue?.toString() ?? '');
  late final _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late AdminVoucherType _type =
      widget.initial?.type ?? AdminVoucherType.percentage;

  @override
  void dispose() {
    for (final controller in [_code, _name, _value, _max, _min, _description]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Không được để trống';
    if (value.trim().length > 100) return 'Tối đa 100 ký tự';
    return null;
  }

  String? _amount(String? value,
      {bool optional = false, bool percentage = false}) {
    if (optional && (value == null || value.trim().isEmpty)) {
      return null;
    }
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || !number.isFinite || number <= 0) {
      return 'Nhập số lớn hơn 0';
    }
    if (percentage && number > 100) return 'Không vượt quá 100%';
    return null;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.85),
            child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(widget.initial == null ? 'Tạo voucher' : 'Sửa voucher',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _code,
                        validator: _requiredText,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                            labelText: 'Mã voucher',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _name,
                        validator: _requiredText,
                        decoration: const InputDecoration(
                            labelText: 'Tên voucher',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AdminVoucherType>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                          labelText: 'Loại giảm', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(
                            value: AdminVoucherType.percentage,
                            child: Text('Theo phần trăm')),
                        DropdownMenuItem(
                            value: AdminVoucherType.fixedAmount,
                            child: Text('Theo số tiền')),
                      ],
                      onChanged: (value) =>
                          setState(() => _type = value ?? _type),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _value,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) => _amount(value,
                            percentage: _type == AdminVoucherType.percentage),
                        decoration: InputDecoration(
                            labelText: _type == AdminVoucherType.percentage
                                ? 'Mức giảm (%)'
                                : 'Số tiền giảm (₫)',
                            border: const OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _max,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) => _amount(value, optional: true),
                        decoration: const InputDecoration(
                            labelText: 'Giảm tối đa (₫, tùy chọn)',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _min,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) => _amount(value, optional: true),
                        decoration: const InputDecoration(
                            labelText: 'Đơn tối thiểu (₫, tùy chọn)',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _description,
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Mô tả', border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: () {
                          if (!_form.currentState!.validate()) return;
                          Navigator.pop(
                              context,
                              AdminVoucherDraft(
                                code: _code.text,
                                name: _name.text,
                                type: _type,
                                discountValue: double.parse(_value.text.trim()),
                                maxDiscountValue: _max.text.trim().isEmpty
                                    ? null
                                    : double.parse(_max.text.trim()),
                                minValue: _min.text.trim().isEmpty
                                    ? null
                                    : double.parse(_min.text.trim()),
                                description: _description.text,
                              ));
                        },
                        child: Text(widget.initial == null
                            ? 'Tạo voucher'
                            : 'Lưu thay đổi')),
                  ],
                )),
          ),
        ),
      );
}
