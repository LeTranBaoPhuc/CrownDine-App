import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/reservation_model.dart';
import '../../../../providers/reservation_provider.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/write_feedback_sheet.dart';

class ReservationHistoryScreen extends ConsumerWidget {
  const ReservationHistoryScreen({super.key});

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppColors.success;
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.completed:
        return AppColors.info;
      case ReservationStatus.checkedIn:
        return AppColors.primary;
      case ReservationStatus.noShow:
        return Colors.grey;
      case ReservationStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(reservationHistoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử đặt bàn'),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (reservations) {
          if (reservations.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 60, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('Bạn chưa có lịch đặt bàn nào', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final r = reservations[index];
              final statusColor = _getStatusColor(r.status);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.code,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        StatusBadge(
                          label: r.status.displayName,
                          color: statusColor,
                        ),
                      ],
                    ),
                    const Divider(height: 18),
                    Row(
                      children: [
                        const Icon(Icons.table_restaurant, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          r.tableName ?? 'Chưa xác định bàn',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const Spacer(),
                        const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${r.guestNumber} khách', style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text('${r.date} lúc ${r.startTime}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                    if (r.items.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Món đặt trước: ${r.items.map((i) => '${i.quantity}x ${i.item.name}').join(', ')}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng tiền thanh toán:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(
                              CurrencyFormatter.format(r.finalAmount),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                        if (r.status == ReservationStatus.pending || r.status == ReservationStatus.confirmed)
                          OutlinedButton(
                            onPressed: () => _confirmCancel(context, ref, r),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Hủy đặt bàn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        if (r.status == ReservationStatus.completed)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                            label: const Text('Đánh giá trải nghiệm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              final firstItem = r.items.isNotEmpty ? r.items.first.item.name : 'Bữa tiệc tại ${r.tableName ?? r.code}';
                              WriteFeedbackSheet.show(
                                context,
                                itemName: firstItem,
                                orderId: r.id,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldDark,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, ReservationModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đặt bàn?'),
        content: Text('Bạn có chắc chắn muốn hủy đặt bàn mã ${r.code}? Bàn ${r.tableName} sẽ được trả lại cho khách khác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(reservationRepositoryProvider).cancelReservation(r.id);
              ref.invalidate(reservationHistoryProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã hủy đặt bàn ${r.code}'), backgroundColor: AppColors.error),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

