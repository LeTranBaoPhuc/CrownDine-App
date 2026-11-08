import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/table_provider.dart';
import '../../customer/reservation/payos_payment_screen.dart';

class OrderSettlementScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderSettlementScreen({super.key, required this.orderId});
  @override
  ConsumerState<OrderSettlementScreen> createState() =>
      _OrderSettlementScreenState();
}

class _OrderSettlementScreenState extends ConsumerState<OrderSettlementScreen> {
  Map<String, dynamic>? _quote;
  Map<String, dynamic>? _payment;
  String _method = 'CASH';
  String? _error;
  bool _loading = false;
  bool _busy = false;
  bool _uncertain = false;
  bool get _paid =>
      _quote?['status'] == 'COMPLETED' &&
      _payment?['status'] == 'SUCCESS' &&
      _payment?['orderCode'] == _quote?['orderCode'];
  bool get _pending => _payment?['status'] == 'PENDING';
  bool get _closed => ['COMPLETED', 'CANCELLED'].contains(_quote?['status']);
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
      final repo = ref.read(orderRepositoryProvider);
      // Reconcile pending PayOS before reloading the order status.
      final payment = await repo.latestPayment(widget.orderId);
      final quote = await repo.getCheckout(widget.orderId);
      if (!mounted) return;
      if (payment != null && payment['orderCode'] != quote['orderCode'])
        throw const FormatException('Giao dịch không khớp đơn.');
      setState(() {
        _quote = quote;
        _payment = payment;
        if (['FAILED', 'CANCELLED', 'EXPIRED'].contains(payment?['status']))
          _uncertain = false;
        _loading = false;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = apiErrorMessage(error);
        });
    }
  }

  Future<void> _submit() async {
    if (_busy ||
        _loading ||
        _pending ||
        _closed ||
        _paid ||
        _quote == null ||
        _uncertain) return;
    final reviewed = Map<String, dynamic>.from(_quote!);
    if (_method == 'CASH') {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Xác nhận thu tiền'),
                  content: Text(
                      'Đã nhận đủ ${CurrencyFormatter.format(reviewed['finalAmount'])} cho đơn ${reviewed['orderCode']}?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Chưa nhận')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Đã nhận đủ tiền'))
                  ]));
      if (confirm != true || !mounted) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    bool creating = false;
    try {
      final repo = ref.read(orderRepositoryProvider);
      final current = await repo.getCheckout(widget.orderId);
      if (current['finalAmount'] != reviewed['finalAmount'] ||
          current['orderCode'] != reviewed['orderCode']) {
        if (mounted) setState(() => _quote = current);
        throw StateError(
            'Số tiền đã thay đổi. Vui lòng kiểm tra lại trước khi xác nhận.');
      }
      creating = true;
      await repo.createSettlement(current['orderCode'] as String, _method);
      await _load();
      if (!mounted) return;
      if (_method == 'PAYOS') await _openPayOS();
      if (mounted && _paid) {
        await ref.read(orderProvider.notifier).loadOrders();
        if (mounted) await ref.read(tableProvider.notifier).loadLayout();
      }
    } catch (error) {
      final ambiguous = creating &&
          (error is! DioException ||
              error.response == null ||
              (error.response?.statusCode ?? 500) >= 500);
      if (mounted)
        setState(() {
          _uncertain = ambiguous;
          _error = ambiguous
              ? 'Chưa xác định kết quả thu tiền. Kiểm tra giao dịch trước khi thu lại.'
              : apiErrorMessage(error);
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPayOS() async {
    final url = Uri.tryParse('${_payment?['checkoutUrl'] ?? ''}');
    if (url == null ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty) return;
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: url.toString()));
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Đã sao chép link PayOS. Mở ở tab khác rồi kiểm tra trạng thái.')));
    } else {
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PayOSPaymentScreen(checkoutUrl: url)));
      if (mounted) await _load();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Thanh toán đơn hàng'), actions: [
          IconButton(
              tooltip: 'Kiểm tra trạng thái',
              onPressed: _busy || _loading ? null : _load,
              icon: const Icon(Icons.refresh))
        ]),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          if (_busy || _loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          if (_quote != null)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Đơn ${_quote!['orderCode']}',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          for (final row in const [
                            ['totalAmount', 'Tiền món'],
                            ['voucherDiscount', 'Giảm voucher'],
                            ['orderDepositPaidAmount', 'Cọc món đã trả'],
                            ['finalAmount', 'Còn phải thu']
                          ])
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Row(children: [
                                  Expanded(child: Text(row[1])),
                                  Text(
                                      CurrencyFormatter.format(_quote![row[0]]),
                                      style: TextStyle(
                                          fontWeight: row[0] == 'finalAmount'
                                              ? FontWeight.bold
                                              : FontWeight.normal)),
                                ])),
                          const Text(
                              'Cọc bàn được nhà hàng giữ theo chính sách đặt chỗ.'),
                        ]))),
          const SizedBox(height: 20),
          if (_paid)
            const Card(
                child: ListTile(
                    leading: Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Đã thanh toán thành công'),
                    subtitle:
                        Text('Server đã ghi nhận giao dịch và hoàn tất đơn.')))
          else ...[
            if (_payment != null)
              Card(
                  child: ListTile(
                      title: Text('Giao dịch #${_payment!['code']}'),
                      subtitle: Text(
                          'Trạng thái: ${_payment!['status']} • ${_payment!['method']}'))),
            if (_pending && _payment?['checkoutUrl'] != null)
              OutlinedButton.icon(
                  onPressed: _busy ? null : _openPayOS,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(kIsWeb ? 'Sao chép link PayOS' : 'Mở lại PayOS')),
            const SizedBox(height: 12),
            SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'CASH', label: Text('Tiền mặt')),
                  ButtonSegment(value: 'PAYOS', label: Text('PayOS'))
                ],
                selected: {
                  _method
                },
                onSelectionChanged: _busy || _pending
                    ? null
                    : (value) => setState(() => _method = value.first)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _busy ||
                        _loading ||
                        _pending ||
                        _closed ||
                        _uncertain ||
                        _quote == null ||
                        _error != null
                    ? null
                    : _submit,
                child: Text(_busy
                    ? 'Đang xử lý…'
                    : _method == 'CASH'
                        ? 'Xác nhận thu tiền'
                        : 'Tạo thanh toán PayOS')),
            TextButton(
                onPressed: _busy || _loading ? null : _load,
                child: const Text('Kiểm tra giao dịch')),
          ],
        ]),
      ));
}
