import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/admin_payment_model.dart';
import '../../../../data/repositories/admin_payment_repository.dart';

String paymentLabel(String value) => switch (value) {
      'PENDING' => 'Đang chờ',
      'SUCCESS' => 'Thành công',
      'FAILED' => 'Thất bại',
      'PAYOS' => 'PayOS',
      'MOMO' => 'MoMo',
      'CASH' => 'Tiền mặt',
      'ZALOPAY' => 'ZaloPay',
      'DEPOSIT' => 'Đặt cọc',
      'SETTLEMENT' => 'Thanh toán đơn',
      'REFUND' => 'Hoàn tiền',
      'RESERVATION' => 'Đặt bàn',
      'ORDER' => 'Đơn hàng',
      'CLIENT_APP' => 'Ứng dụng khách',
      'POS_COUNTER' => 'Quầy POS',
      'UNKNOWN' => 'Chưa rõ',
      _ => value,
    };

String paymentError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Không kết nối được máy chủ. Vui lòng thử lại.';
  }
  if (error is FormatException) return error.message;
  return 'Không tải được giao dịch. Vui lòng thử lại.';
}

class AdminPaymentScreen extends StatefulWidget {
  final AdminPaymentRepository? repository;
  const AdminPaymentScreen({super.key, this.repository});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen> {
  late final AdminPaymentRepository _repo =
      widget.repository ?? AdminPaymentRepository();
  final _search = TextEditingController();
  AdminPaymentFilter _filter = const AdminPaymentFilter();
  AdminPaymentPage? _page;
  bool _loading = true;
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

  Future<void> _load(int page) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.list(page: page, filter: _filter);
      if (!mounted || request != _request) return;
      setState(() {
        _page = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = paymentError(error);
        _loading = false;
      });
    }
  }

  void _searchNow() {
    _filter = AdminPaymentFilter(
      search: _search.text,
      status: _filter.status,
      method: _filter.method,
      type: _filter.type,
      target: _filter.target,
      source: _filter.source,
      fromDate: _filter.fromDate,
      toDate: _filter.toDate,
    );
    _load(1);
  }

  Future<void> _showFilters() async {
    final next = await showModalBottomSheet<AdminPaymentFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PaymentFilterSheet(current: _filter),
    );
    if (next == null || !mounted) return;
    _filter = AdminPaymentFilter(
      search: _search.text,
      status: next.status,
      method: next.method,
      type: next.type,
      target: next.target,
      source: next.source,
      fromDate: next.fromDate,
      toDate: next.toDate,
    );
    _load(1);
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý giao dịch')),
      body: RefreshIndicator(
        onRefresh: () => _load(page?.page ?? 1),
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchNow(),
                    decoration: InputDecoration(
                      hintText: 'Mã, khách, đơn hoặc đặt bàn',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Tìm kiếm',
                        onPressed: _searchNow,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Bộ lọc giao dịch',
                  onPressed: _showFilters,
                  icon: const Icon(Icons.filter_list),
                ),
              ]),
              const SizedBox(height: 8),
              if (_filter.status != null ||
                  _filter.method != null ||
                  _filter.fromDate != null ||
                  _filter.toDate != null ||
                  _filter.type != null ||
                  _filter.target != null ||
                  _filter.source != null)
                TextButton.icon(
                  onPressed: () {
                    _filter = AdminPaymentFilter(search: _search.text);
                    _load(1);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Xóa bộ lọc'),
                ),
              if (_loading && page == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    OutlinedButton(
                        onPressed: () => _load(page?.page ?? 1),
                        child: const Text('Thử lại')),
                  ]),
                )
              else if (page != null) ...[
                Text('${page.totalItems} giao dịch',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (page.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: Text('Không có giao dịch phù hợp.')),
                  ),
                for (final payment in page.items)
                  Card(
                    child: ListTile(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AdminPaymentDetailScreen(
                            paymentId: payment.id, repository: _repo),
                      )),
                      title: Row(children: [
                        Expanded(child: Text('GD #${payment.code}')),
                        Text(CurrencyFormatter.format(payment.amount),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${paymentLabel(payment.status)} · '
                              '${paymentLabel(payment.method)} · '
                              '${paymentLabel(payment.type)}'),
                          Text(payment.reservationCode ??
                              payment.orderCode ??
                              payment.username ??
                              'Không có mã tham chiếu'),
                          Text(DateFormat('dd/MM/yyyy HH:mm')
                              .format(payment.createdAt)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                if (page.totalPages > 1)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(
                        tooltip: 'Trang trước',
                        onPressed: _loading || page.page <= 1
                            ? null
                            : () => _load(page.page - 1),
                        icon: const Icon(Icons.chevron_left)),
                    Text('Trang ${page.page}/${page.totalPages}'),
                    IconButton(
                        tooltip: 'Trang sau',
                        onPressed: _loading || page.page >= page.totalPages
                            ? null
                            : () => _load(page.page + 1),
                        icon: const Icon(Icons.chevron_right)),
                  ]),
              ],
            ]),
      ),
    );
  }
}

class AdminPaymentDetailScreen extends StatefulWidget {
  final int paymentId;
  final AdminPaymentRepository repository;
  const AdminPaymentDetailScreen({
    super.key,
    required this.paymentId,
    required this.repository,
  });

  @override
  State<AdminPaymentDetailScreen> createState() =>
      _AdminPaymentDetailScreenState();
}

class _AdminPaymentDetailScreenState extends State<AdminPaymentDetailScreen> {
  late Future<AdminPayment> _payment =
      widget.repository.detail(widget.paymentId);

  void _refresh() => setState(() {
        _payment = widget.repository.detail(widget.paymentId);
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Giao dịch #${widget.paymentId}'), actions: [
          IconButton(
              tooltip: 'Làm mới giao dịch',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh)),
        ]),
        body: FutureBuilder<AdminPayment>(
          future: _payment,
          builder: (context, snapshot) {
            if (!snapshot.hasData && !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(paymentError(snapshot.error!),
                      textAlign: TextAlign.center),
                  OutlinedButton(
                      onPressed: _refresh, child: const Text('Thử lại')),
                ]),
              );
            }
            final payment = snapshot.data!;
            return ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Text(CurrencyFormatter.format(payment.amount),
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(paymentLabel(payment.status),
                        style: TextStyle(
                            color: payment.status == 'SUCCESS'
                                ? AppColors.success
                                : AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
              _line('Mã PayOS', '${payment.code}'),
              _line('Mã giao dịch ngân hàng', payment.transactionCode),
              _line('Khách hàng', payment.username),
              _line('Đặt bàn', payment.reservationCode),
              _line('Đơn hàng', payment.orderCode),
              _line('Phương thức', paymentLabel(payment.method)),
              _line('Loại giao dịch', paymentLabel(payment.type)),
              _line('Đối tượng', paymentLabel(payment.target)),
              _line('Nguồn', paymentLabel(payment.source)),
              _line('Tạo lúc',
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(payment.createdAt)),
              if (payment.updatedAt != null)
                _line(
                    'Cập nhật lúc',
                    DateFormat('dd/MM/yyyy HH:mm:ss')
                        .format(payment.updatedAt!)),
            ]);
          },
        ),
      );

  Widget _line(String label, String? value) => ListTile(
        title: Text(label),
        subtitle: Text(value?.isNotEmpty == true ? value! : '—'),
      );
}

class _PaymentFilterSheet extends StatefulWidget {
  final AdminPaymentFilter current;
  const _PaymentFilterSheet({required this.current});

  @override
  State<_PaymentFilterSheet> createState() => _PaymentFilterSheetState();
}

class _PaymentFilterSheetState extends State<_PaymentFilterSheet> {
  late String? _status = widget.current.status;
  late String? _method = widget.current.method;
  late String? _type = widget.current.type;
  late String? _target = widget.current.target;
  late String? _source = widget.current.source;
  late DateTime? _from = widget.current.fromDate;
  late DateTime? _to = widget.current.toDate;

  Widget _dropdown(String label, String? value, List<String> options,
      ValueChanged<String?> change) {
    return DropdownButtonFormField<String>(
      initialValue: value ?? '',
      decoration: InputDecoration(labelText: label),
      items: [
        const DropdownMenuItem(value: '', child: Text('Tất cả')),
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(paymentLabel(option))),
      ],
      onChanged: (next) => change(next == '' ? null : next),
    );
  }

  Future<void> _pickDate(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(shrinkWrap: true, children: [
            Text('Lọc giao dịch',
                style: Theme.of(context).textTheme.titleLarge),
            _dropdown('Trạng thái', _status, ['PENDING', 'SUCCESS', 'FAILED'],
                (value) => setState(() => _status = value)),
            _dropdown(
                'Phương thức',
                _method,
                ['PAYOS', 'MOMO', 'CASH', 'ZALOPAY'],
                (value) => setState(() => _method = value)),
            _dropdown('Loại', _type, ['DEPOSIT', 'SETTLEMENT', 'REFUND'],
                (value) => setState(() => _type = value)),
            _dropdown('Đối tượng', _target, ['RESERVATION', 'ORDER'],
                (value) => setState(() => _target = value)),
            _dropdown('Nguồn', _source, ['CLIENT_APP', 'POS_COUNTER'],
                (value) => setState(() => _source = value)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(true),
                  child: Text(_from == null
                      ? 'Từ ngày'
                      : DateFormat('dd/MM/yyyy').format(_from!)),
                ),
              ),
              IconButton(
                  tooltip: 'Xóa từ ngày',
                  onPressed:
                      _from == null ? null : () => setState(() => _from = null),
                  icon: const Icon(Icons.close)),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickDate(false),
                  child: Text(_to == null
                      ? 'Đến ngày'
                      : DateFormat('dd/MM/yyyy').format(_to!)),
                ),
              ),
              IconButton(
                  tooltip: 'Xóa đến ngày',
                  onPressed:
                      _to == null ? null : () => setState(() => _to = null),
                  icon: const Icon(Icons.close)),
            ]),
            if (_from != null && _to != null && _from!.isAfter(_to!))
              const Text('Từ ngày phải trước hoặc bằng đến ngày.',
                  style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _from != null && _to != null && _from!.isAfter(_to!)
                  ? null
                  : () => Navigator.pop(
                        context,
                        AdminPaymentFilter(
                          status: _status,
                          method: _method,
                          type: _type,
                          target: _target,
                          source: _source,
                          fromDate: _from,
                          toDate: _to,
                        ),
                      ),
              child: const Text('Áp dụng bộ lọc'),
            ),
          ]),
        ),
      );
}
