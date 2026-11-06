import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/reservation_checkout_provider.dart';
import '../../../../providers/reservation_provider.dart';
import 'reservation_payment_panel.dart';

class Step4ConfirmationView extends ConsumerWidget {
  const Step4ConfirmationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(reservationProvider);
    final checkoutId = ref.watch(checkoutReservationIdProvider);
    final user = ref.watch(authProvider).user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Bước 4: Xác nhận & Thanh toán cọc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${DateFormatter.format(form.selectedDate)} · ${form.selectedTime} · ${form.guestNumber} khách'),
                    const SizedBox(height: 8),
                    Text('Bàn: ${form.selectedTable?.name ?? "Chưa chọn"}'),
                    const SizedBox(height: 8),
                    Text('Người đặt: ${user?.fullName ?? ""}'),
                    if (user?.phone?.isNotEmpty == true)
                      Text('Số điện thoại: ${user!.phone}'),
                    if (form.note.isNotEmpty) Text('Ghi chú: ${form.note}'),
                  ],
                ))),
        const SizedBox(height: 16),
        if (form.currentStep == 4 && checkoutId != null)
          ReservationPaymentPanel(
              key: ValueKey(checkoutId), reservationId: checkoutId)
        else if (checkoutId == null)
          const Text(
              'Thông tin đặt bàn chưa sẵn sàng. Vui lòng quay lại bước đặt món và tiếp tục.'),
      ]),
    );
  }
}
