import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/reservation_provider.dart';
import '../../../widgets/app_text_field.dart';

class Step4ConfirmationView extends ConsumerStatefulWidget {
  const Step4ConfirmationView({super.key});

  @override
  ConsumerState<Step4ConfirmationView> createState() => _Step4ConfirmationViewState();
}

class _Step4ConfirmationViewState extends ConsumerState<Step4ConfirmationView> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _noteController;
  final _voucherController = TextEditingController();
  int _paymentMethod = 1; // 1: PayOS QR, 2: Tiền mặt/Thẻ

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final resState = ref.read(reservationProvider);

    _nameController = TextEditingController(
      text: resState.guestName.isNotEmpty ? resState.guestName : (user?.fullName ?? ''),
    );
    _phoneController = TextEditingController(
      text: resState.guestPhone.isNotEmpty ? resState.guestPhone : (user?.phone ?? ''),
    );
    _noteController = TextEditingController(text: resState.note);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    _voucherController.dispose();
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
    final notifier = ref.read(reservationProvider.notifier);
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
          const Text('Thông tin người đặt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
            const Text('Món ăn đặt trước', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          CurrencyFormatter.format(item.totalPrice),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Voucher Box
          const Text('Mã ưu đãi / Voucher', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voucherController,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã: CROWNDINE50, VIPGOLD10...',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final code = _voucherController.text.trim().toUpperCase();
                  final found = MockData.vouchers.where((v) => v.code.toUpperCase() == code).firstOrNull;
                  if (found != null) {
                    notifier.applyVoucher(found);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã áp dụng voucher: ${found.name}'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mã voucher không hợp lệ!'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Áp dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (resState.appliedVoucher != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${resState.appliedVoucher!.name} (-${CurrencyFormatter.format(resState.discountAmount)})',
                      style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                    onPressed: () => notifier.removeVoucher(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Payment Method Selection
          const Text('Phương thức thanh toán cọc', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Material(
            color: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                RadioListTile<int>(
                  value: 1,
                  groupValue: _paymentMethod,
                  title: const Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Thanh toán PayOS (QR Code / Ngân hàng)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  subtitle: const Text('Tạo mã QR VietQR thanh toán tức thì và tự động kích hoạt bàn.'),
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
                const Divider(height: 1),
                RadioListTile<int>(
                  value: 2,
                  groupValue: _paymentMethod,
                  title: const Row(
                    children: [
                      Icon(Icons.payments_outlined, color: AppColors.gold),
                      SizedBox(width: 10),
                      Text('Đặt cọc tại quầy nhà hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  subtitle: const Text('Xác nhận đặt bàn và thanh toán trực tiếp khi tới nhà hàng.'),
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cost Breakdown Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                _buildPriceRow('Tiền cọc giữ bàn:', CurrencyFormatter.format(resState.tableDeposit)),
                if (resState.foodSubtotal > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Tiền món ăn đặt trước:', CurrencyFormatter.format(resState.foodSubtotal)),
                ],
                if (resState.appliedVoucher != null) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow('Giảm giá ưu đãi:', '-${CurrencyFormatter.format(resState.discountAmount)}', isDiscount: true),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng cọc cần trả:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.format(resState.finalAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isHighlight ? AppColors.primary : AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDiscount ? AppColors.success : null,
          ),
        ),
      ],
    );
  }
}
