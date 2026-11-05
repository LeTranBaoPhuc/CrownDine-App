import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../providers/reservation_checkout_provider.dart';
import 'reservation_payment_panel.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/reservation_provider.dart';
import '../../../widgets/app_text_field.dart';

class Step4ConfirmationView extends ConsumerStatefulWidget {
  const Step4ConfirmationView({super.key});

  @override
  ConsumerState<Step4ConfirmationView> createState() =>
      _Step4ConfirmationViewState();
}

class _Step4ConfirmationViewState extends ConsumerState<Step4ConfirmationView> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final resState = ref.read(reservationProvider);

    _nameController = TextEditingController(
      text: resState.guestName.isNotEmpty
          ? resState.guestName
          : (user?.fullName ?? ''),
    );
    _phoneController = TextEditingController(
      text: resState.guestPhone.isNotEmpty
          ? resState.guestPhone
          : (user?.phone ?? ''),
    );
    _noteController = TextEditingController(text: resState.note);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _syncContact() {
    ref.read(reservationProvider.notifier).setCustomerInfo(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          note: _noteController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final resState = ref.watch(reservationProvider);
    final checkoutId = ref.watch(checkoutReservationIdProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bước 4: Xác nhận thông tin & Thanh toán cọc',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kiểm tra lại thông tin đặt bàn của bạn và hoàn tất thủ tục giữ chỗ.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Booking Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  Icons.calendar_today,
                  'Ngày dùng bữa:',
                  '${DateFormatter.friendly(resState.selectedDate)} (${DateFormatter.format(resState.selectedDate)})',
                ),
                const Divider(height: 18),
                _buildSummaryRow(
                  Icons.access_time,
                  'Khung giờ:',
                  resState.selectedTime,
                ),
                const Divider(height: 18),
                _buildSummaryRow(
                  Icons.people_outline,
                  'Số lượng khách:',
                  '${resState.guestNumber} người',
                ),
                const Divider(height: 18),
                _buildSummaryRow(
                  Icons.table_restaurant,
                  'Bàn đã chọn:',
                  resState.selectedTable != null
                      ? '${resState.selectedTable!.name} (${resState.selectedTable!.areaName ?? ''})'
                      : 'Chưa chọn bàn',
                  isHighlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Contact Information Form
          const Text('Thông tin người đặt',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Họ và tên khách hàng *',
            hint: 'Nguyễn Văn An',
            controller: _nameController,
            prefixIcon: Icons.person_outline,
            onChanged: (_) => _syncContact(),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Số điện thoại nhận xác nhận *',
            hint: '0901234567',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            onChanged: (_) => _syncContact(),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Yêu cầu đặc biệt (Ghi chú)',
            hint: 'Ví dụ: Cần ghế trẻ em, trang trí hoa mừng sinh nhật...',
            controller: _noteController,
            prefixIcon: Icons.notes_outlined,
            maxLines: 2,
            onChanged: (_) => _syncContact(),
          ),
          const SizedBox(height: 24),

          // Pre-ordered food list (if any)
          if (resState.preOrderItems.isNotEmpty) ...[
            const Text('Món ăn đặt trước',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: resState.preOrderItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantity}x ${item.item.name}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (resState.currentStep == 4 && checkoutId != null)
            ReservationPaymentPanel(
                key: ValueKey(checkoutId), reservationId: checkoutId)
          else if (checkoutId == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Thông tin đặt bàn chưa sẵn sàng để thanh toán. '
                    'Vui lòng hoàn tất đặt bàn và đồng bộ món ăn trước khi tiếp tục.'),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value,
      {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 20,
            color: isHighlight ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}
