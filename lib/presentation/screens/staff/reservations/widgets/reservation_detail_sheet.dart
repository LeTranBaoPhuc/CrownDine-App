import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../data/models/reservation_model.dart';
import '../../../../../data/models/table_model.dart';
import '../../../../../providers/staff_reservation_provider.dart';
import '../../../../../providers/table_provider.dart';

class ReservationDetailSheet extends ConsumerWidget {
  final ReservationModel reservation;

  const ReservationDetailSheet({
    super.key,
    required this.reservation,
  });

  static Future<void> show(BuildContext context, ReservationModel reservation) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReservationDetailSheet(reservation: reservation),
    );
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppColors.success;
      case ReservationStatus.checkedIn:
        return AppColors.info;
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.completed:
        return Colors.teal;
      case ReservationStatus.cancelled:
        return AppColors.error;
      case ReservationStatus.noShow:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final notifier = ref.read(staffReservationProvider.notifier);
    final statusColor = _getStatusColor(reservation.status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header: Title & Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${reservation.code}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            reservation.status.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chi tiết đơn đặt bàn',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Customer Information Card
                  _buildSectionHeader(Icons.person_outline, 'Thông tin khách hàng', isDark),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    isDark,
                    children: [
                      _buildInfoRow('Họ và tên:', reservation.displayName, isBold: true),
                      const SizedBox(height: 8),
                      _buildInfoRow('Số điện thoại:', reservation.displayPhone.isNotEmpty ? reservation.displayPhone : 'Chưa cập nhật'),
                      if (reservation.email != null && reservation.email!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow('Email:', reservation.email!),
                      ],
                      const SizedBox(height: 8),
                      _buildInfoRow('Số khách:', '${reservation.guestNumber} người', isHighlight: true),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Booking Time & Table
                  _buildSectionHeader(Icons.calendar_today_outlined, 'Thời gian & Bàn phục vụ', isDark),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    isDark,
                    children: [
                      _buildInfoRow('Ngày đặt:', reservation.date),
                      const SizedBox(height: 8),
                      _buildInfoRow('Khung giờ:', reservation.displayTimeRange, isBold: true),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 100,
                            child: Text(
                              'Bàn phục vụ:',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              reservation.tableName ?? 'Chưa xếp bàn',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          // Reassign table button
                          if (reservation.canCancel)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(Icons.swap_horiz, size: 16),
                              label: const Text('Đổi bàn', style: TextStyle(fontSize: 12)),
                              onPressed: () => _showChangeTableDialog(context, ref, reservation),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Vị trí:',
                        '${reservation.floorName ?? 'Tầng 1'}${reservation.areaName != null ? ' - ${reservation.areaName}' : ''}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Notes Section (if any)
                  if (reservation.note != null && reservation.note!.trim().isNotEmpty) ...[
                    _buildSectionHeader(Icons.notes, 'Ghi chú của khách', isDark),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        reservation.note!,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. Pre-ordered Food Details
                  if (reservation.orderDetails.isNotEmpty) ...[
                    _buildSectionHeader(Icons.restaurant_menu, 'Món ăn đặt trước', isDark),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          ...reservation.orderDetails.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCard : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                    ),
                                    child: Text(
                                      '${item.quantity}x',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.textLight : AppColors.textPrimary,
                                          ),
                                        ),
                                        if (item.note != null && item.note!.isNotEmpty)
                                          Text(
                                            item.note!,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(item.totalPrice),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Tạm tính món ăn:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                                Text(
                                  CurrencyFormatter.format(reservation.itemsTotal),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 5. Financial Breakdown Card
                  _buildSectionHeader(Icons.receipt_outlined, 'Chi phí & Đặt cọc', isDark),
                  const SizedBox(height: 10),
                  _buildInfoCard(
                    isDark,
                    children: [
                      _buildInfoRow('Tiền cọc giữ bàn:', CurrencyFormatter.format(reservation.tableDeposit)),
                      if (reservation.itemsTotal > 0) ...[
                        const SizedBox(height: 6),
                        _buildInfoRow('Tiền món đặt trước:', CurrencyFormatter.format(reservation.itemsTotal)),
                      ],
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tổng số tiền thanh toán:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            CurrencyFormatter.format(reservation.finalAmount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 6. Check-in Policy Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFF2563EB)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quy tắc tiếp đón Check-in:',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Chỉ thực hiện check-in trong khoảng 15 phút trước đến 15 phút sau giờ hẹn đặt bàn. Sau 15 phút không liên lạc được, bàn có thể được giải phóng.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1E3A8A),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                if (reservation.canCancel) ...[
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showCancelConfirm(context, notifier, reservation);
                      },
                      child: const Text('Hủy đặt bàn', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                if (reservation.canCheckIn)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text(
                        'Check-in Nhận bàn',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final success = await notifier.checkIn(reservation.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Check-in thành công cho khách!' : 'Check-in thất bại'),
                              backgroundColor: success ? AppColors.success : AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                  ),

                if (!reservation.canCheckIn && !reservation.canCancel)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textLight : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: (isBold || isHighlight) ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }

  void _showChangeTableDialog(
    BuildContext context,
    WidgetRef ref,
    ReservationModel res,
  ) async {
    final tableState = ref.read(tableProvider);
    final allTables = tableState.allTables;

    final selectedTable = await showDialog<TableModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn bàn mới'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: allTables.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final t = allTables[i];
              final isCurrent = t.id == res.tableId;

              return ListTile(
                dense: true,
                leading: Icon(
                  Icons.table_restaurant,
                  color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(
                  '${t.name} (${t.capacity} chỗ)',
                  style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: Text('Tầng ${t.floorId} • ${t.areaName}'),
                trailing: isCurrent
                    ? const Chip(
                        label: Text('Hiện tại', style: TextStyle(fontSize: 10, color: Colors.white)),
                        backgroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );

    if (selectedTable != null && context.mounted) {
      final success = await ref
          .read(staffReservationProvider.notifier)
          .updateTable(res.id, selectedTable.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã đổi sang ${selectedTable.name}!' : 'Đổi bàn thất bại'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  void _showCancelConfirm(
    BuildContext context,
    StaffReservationNotifier notifier,
    ReservationModel res,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đặt bàn'),
        content: Text('Hủy đơn đặt bàn #${res.code} của khách "${res.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Quay lại')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await notifier.cancel(res.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Đã hủy đơn đặt bàn thành công' : 'Hủy thất bại'),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }
}

