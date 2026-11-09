import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/reservation_provider.dart';
import '../../../../providers/reservation_checkout_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import 'step1_datetime_view.dart';
import 'step2_table_map_view.dart';
import 'step3_food_preorder_view.dart';
import 'step4_confirmation_view.dart';

class ReservationScreen extends ConsumerWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resState = ref.watch(reservationProvider);
    final notifier = ref.read(reservationProvider.notifier);
    final checkoutId = ref.watch(checkoutReservationIdProvider);
    final checkoutState = checkoutId == null
        ? null
        : ref.watch(reservationCheckoutProvider(checkoutId));
    final checkoutLocked = checkoutState?.paymentStarted == true ||
        checkoutState?.busy == true ||
        resState.isSubmitting;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final steps = [
      {'num': 1, 'title': 'Ngày & Giờ'},
      {'num': 2, 'title': 'Chọn bàn'},
      {'num': 3, 'title': 'Đặt món'},
      {'num': 4, 'title': 'Thanh toán'},
    ];

    return Scaffold(
      appBar: const CrownAppBar(title: 'Đặt bàn CrownDine'),
      body: Column(
        children: [
          // Stepper Progress Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: Row(
              children: steps.map((s) {
                final stepNum = s['num'] as int;
                final isCurrent = resState.currentStep == stepNum;
                final isCompleted = resState.currentStep > stepNum;

                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.success
                              : isCurrent
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s['title'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (stepNum < 4)
                        Container(
                          width: 14,
                          height: 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: isCompleted
                              ? AppColors.success
                              : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          if (resState.errorMessage != null)
            Padding(
                padding: const EdgeInsets.all(12),
                child: Text(resState.errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          // Current Step View
          Expanded(
            child: AbsorbPointer(
                absorbing: resState.isSubmitting,
                child: IndexedStack(
                  index: resState.currentStep - 1,
                  children: const [
                    Step1DateTimeView(),
                    Step2TableMapView(),
                    Step3FoodPreorderView(),
                    Step4ConfirmationView(),
                  ],
                )),
          ),

          // Bottom Navigation Buttons (Quay lại / Tiếp tục / Hoàn tất)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                if (resState.currentStep > 1)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: checkoutLocked
                          ? null
                          : () async {
                              if (resState.currentStep == 3 &&
                                  resState.backendReservationId != null) {
                                final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                          title: const Text(
                                              'Đổi thông tin đặt bàn?'),
                                          content: const Text(
                                              'Đặt bàn đang giữ sẽ được hủy trước khi bạn chọn lại ngày, giờ hoặc bàn.'),
                                          actions: [
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    dialogContext, false),
                                                child:
                                                    const Text('Giữ nguyên')),
                                            TextButton(
                                                onPressed: () => Navigator.pop(
                                                    dialogContext, true),
                                                child: const Text(
                                                    'Hủy giữ chỗ và sửa')),
                                          ],
                                        ));
                                if (confirmed != true || !context.mounted) {
                                  return;
                                }
                                if (!await notifier.releaseHeldReservation()) {
                                  return;
                                }
                              }
                              ref
                                  .read(checkoutReservationIdProvider.notifier)
                                  .state = null;
                              notifier.prevStep();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quay lại',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (resState.currentStep > 1 && resState.currentStep < 4)
                  const SizedBox(width: 12),
                if (resState.currentStep < 4)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: resState.isSubmitting ||
                              resState.creationUncertain
                          ? null
                          : () async {
                              if (resState.currentStep == 2 &&
                                  resState.selectedTable == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Vui lòng chọn 1 bàn còn trống để tiếp tục!'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              if (resState.currentStep == 3) {
                                if (!ref.read(authProvider).isAuthenticated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Vui lòng đăng nhập trước khi đặt bàn.')));
                                  return;
                                }
                                ref
                                    .read(
                                        checkoutReservationIdProvider.notifier)
                                    .state = null;
                                final ready = await notifier.prepareCheckout();
                                if (ready && context.mounted) {
                                  ref.invalidate(reservationHistoryProvider);
                                  ref
                                          .read(checkoutReservationIdProvider
                                              .notifier)
                                          .state =
                                      ref
                                          .read(reservationProvider)
                                          .backendReservationId;
                                }
                              } else if (resState.currentStep == 1) {
                                if (resState.selectedTime.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vui lòng chọn khung giờ hợp lệ để tiếp tục!'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                if (Step1DateTimeView.isSlotPast(resState.selectedDate, resState.selectedTime)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Khung giờ đã chọn đã qua. Vui lòng chọn khung giờ khác!'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                notifier.nextStep();
                              } else {
                                notifier.nextStep();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: resState.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Tiếp theo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
