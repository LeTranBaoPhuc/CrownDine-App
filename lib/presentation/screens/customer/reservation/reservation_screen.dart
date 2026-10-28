import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/reservation_provider.dart';
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
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : Text(
                                  '$stepNum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent ? Colors.white : AppColors.textSecondary,
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
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (stepNum < 4)
                        Container(
                          width: 14,
                          height: 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: isCompleted ? AppColors.success : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Current Step View
          Expanded(
            child: IndexedStack(
              index: resState.currentStep - 1,
              children: const [
                Step1DateTimeView(),
                Step2TableMapView(),
                Step3FoodPreorderView(),
                Step4ConfirmationView(),
              ],
            ),
          ),

          // Bottom Navigation Buttons (Quay lại / Tiếp tục / Hoàn tất)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                      onPressed: () => notifier.prevStep(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Quay lại', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (resState.currentStep > 1) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: resState.isSubmitting
                        ? null
                        : () async {
                            if (resState.currentStep == 2 && resState.selectedTable == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng chọn 1 bàn còn trống để tiếp tục!'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            if (resState.currentStep < 4) {
                              notifier.nextStep();
                            } else {
                              // Submit reservation
                              final success = await notifier.submitReservation();
                              if (success && context.mounted) {
                                _showSuccessDialog(context, ref);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: resState.isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            resState.currentStep == 4 ? 'Xác nhận đặt bàn' : 'Tiếp theo',
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

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    final res = ref.read(reservationProvider).completedReservation;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 54),
            ),
            const SizedBox(height: 18),
            const Text(
              'Đặt bàn thành công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Mã đặt bàn: ${res?.code ?? "CR-8892"}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            // PayOS QR Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text('Mã QR VietQR / PayOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 140,
                    height: 140,
                    color: Colors.white,
                    padding: const EdgeInsets.all(6),
                    child: Image.network(
                      'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=CROWNDINE_DEPOSIT_${res?.code ?? "CR8892"}',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.qr_code_2, size: 100, color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nội dung: ${res?.code ?? "CR-8892"}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Thông tin xác nhận đã được lưu trữ. Hân hạnh được đón tiếp bạn tại CrownDine!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(reservationProvider.notifier).reset();
                  Navigator.of(dialogCtx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hoàn tất & Về trang chủ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
