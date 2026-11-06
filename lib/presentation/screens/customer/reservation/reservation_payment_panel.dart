import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../providers/reservation_checkout_provider.dart';
import '../../../../providers/reservation_provider.dart';
import 'payos_payment_screen.dart';

class ReservationPaymentPanel extends ConsumerStatefulWidget {
  final int reservationId;
  const ReservationPaymentPanel({super.key, required this.reservationId});

  @override
  ConsumerState<ReservationPaymentPanel> createState() =>
      _ReservationPaymentPanelState();
}

class _ReservationPaymentPanelState
    extends ConsumerState<ReservationPaymentPanel> {
  final _voucher = TextEditingController();
  bool _verifying = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref
            .read(reservationCheckoutProvider(widget.reservationId).notifier)
            .refresh();
      }
    });
  }

  @override
  void dispose() {
    _voucher.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _notice = 'Đang chờ máy chủ xác nhận giao dịch…';
    });
    for (var attempt = 0; attempt < 10 && mounted; attempt++) {
      await ref
          .read(reservationCheckoutProvider(widget.reservationId).notifier)
          .verifyPayment(code);
      if (!mounted) return;
      final state = ref.read(reservationCheckoutProvider(widget.reservationId));
      if (state.paid ||
          state.payment?.status == 'FAILED' ||
          state.error != null) {
        break;
      }
      if (attempt < 9) await Future<void>.delayed(const Duration(seconds: 2));
    }
    if (!mounted) return;
    final paid =
        ref.read(reservationCheckoutProvider(widget.reservationId)).paid;
    if (paid) ref.invalidate(reservationHistoryProvider);
    setState(() {
      _verifying = false;
      _notice = paid
          ? null
          : 'Chưa nhận được xác nhận thành công. Nếu đã chuyển khoản, hãy kiểm tra lại trạng thái, không thanh toán thêm.';
    });
  }

  Future<void> _pay() async {
    final url = await ref
        .read(reservationCheckoutProvider(widget.reservationId).notifier)
        .startPayment();
    if (!mounted || url == null) return;
    final callback = await Navigator.of(context).push<PayOSCallback>(
      MaterialPageRoute(builder: (_) => PayOSPaymentScreen(checkoutUrl: url)),
    );
    if (!mounted) return;
    if (callback != null) {
      await _verify(callback.paymentCode);
    } else {
      setState(() => _notice =
          'Bạn đã đóng trang PayOS. Giao dịch chưa được xác nhận; có thể mở lại cùng liên kết thanh toán.');
    }
  }

  Widget _price(String label, double amount, {bool emphasis = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(CurrencyFormatter.format(amount),
              style: TextStyle(
                  fontWeight: emphasis ? FontWeight.bold : FontWeight.w500)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reservationCheckoutProvider(widget.reservationId));
    final notifier =
        ref.read(reservationCheckoutProvider(widget.reservationId).notifier);
    final checkout = state.checkout;
    final busy = state.busy || _verifying;
    final supported = !kIsWeb &&
        [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS]
            .contains(defaultTargetPlatform);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const Expanded(
            child: Text('Thanh toán cọc',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
        IconButton(
            onPressed: busy || state.paymentStarted ? null : notifier.refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Cập nhật số tiền'),
      ]),
      if (busy) const LinearProgressIndicator(),
      if (state.error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      if (checkout == null && !busy)
        OutlinedButton(
            onPressed: notifier.refresh,
            child: const Text('Tải lại thông tin thanh toán')),
      if (checkout != null) ...[
        Text('Mã đặt bàn: ${checkout.reservationCode}'),
        const SizedBox(height: 16),
        TextField(
            controller: _voucher,
            enabled: !busy && !state.paymentStarted && checkout.canApplyVoucher,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Mã ưu đãi / Voucher',
                hintText: 'Nhập mã giảm giá')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: OutlinedButton(
            onPressed: busy || state.paymentStarted || !checkout.canApplyVoucher
                ? null
                : () => notifier.changeVoucher(_voucher.text),
            child: const Text('Áp dụng mã'),
          )),
          if (state.voucherCode != null || checkout.discountAmount > 0) ...[
            const SizedBox(width: 8),
            TextButton(
                onPressed:
                    busy || state.paymentStarted || !checkout.canApplyVoucher
                        ? null
                        : () async {
                            await notifier.changeVoucher(null);
                            if (mounted &&
                                ref
                                        .read(reservationCheckoutProvider(
                                            widget.reservationId))
                                        .error ==
                                    null) {
                              _voucher.clear();
                            }
                          },
                child: const Text('Gỡ mã')),
          ],
        ]),
        if (checkout.orderId == null || checkout.itemsTotal <= 0)
          const Text(
              'Voucher áp dụng cho món ăn đặt trước. Đặt bàn chưa có món vẫn có thể thanh toán cọc bàn.'),
        if (state.voucherCode != null)
          Text('Mã đã áp dụng: ${state.voucherCode}'),
        const SizedBox(height: 16),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  _price('Tổng tiền món', checkout.itemsTotal),
                  _price('Giảm voucher', -checkout.discountAmount),
                  _price('Tiền món sau giảm', checkout.finalAmount),
                  _price('Cọc giữ bàn', checkout.tableDeposit),
                  const Divider(),
                  _price('Cọc cần thanh toán', checkout.depositAmount,
                      emphasis: true),
                  _price('Tiền món còn lại', checkout.remainingAmount),
                ]))),
        const SizedBox(height: 8),
        const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.qr_code_2),
            title: Text('PayOS · QR / Chuyển khoản'),
            subtitle:
                Text('Cọc gồm tiền giữ bàn và 20% tiền món sau giảm giá.')),
        if (!checkout.canPay && !state.paymentStarted)
          Text(checkout.isExpired
              ? 'Đã hết thời gian giữ bàn. Vui lòng kiểm tra lại đặt bàn.'
              : 'Đặt bàn không còn ở trạng thái chờ thanh toán.'),
        if (!supported)
          const Text(
              'Vui lòng dùng ứng dụng Android hoặc iOS để thanh toán PayOS.'),
        if (state.paid) ...[
          const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Thanh toán cọc thành công'),
              subtitle: Text('Máy chủ đã ghi nhận giao dịch.')),
          _price('Đã thanh toán', state.payment!.amount, emphasis: true),
          FilledButton(
              onPressed: () {
                ref.read(reservationProvider.notifier).reset();
                ref.read(checkoutReservationIdProvider.notifier).state = null;
              },
              child: const Text('Hoàn tất')),
        ] else ...[
          FilledButton.icon(
            onPressed: busy ||
                    state.paymentUncertain ||
                    !supported ||
                    (!checkout.canPay && !state.paymentStarted)
                ? null
                : _pay,
            icon: const Icon(Icons.payment),
            label: Text(state.paymentStarted
                ? 'Mở lại PayOS'
                : 'Thanh toán cọc qua PayOS'),
          ),
          if (state.paymentCode != null)
            OutlinedButton(
                onPressed: busy ? null : () => _verify(state.paymentCode!),
                child: const Text('Kiểm tra kết quả thanh toán')),
        ],
      ],
      if (_notice != null)
        Padding(padding: const EdgeInsets.only(top: 12), child: Text(_notice!)),
    ]);
  }
}
