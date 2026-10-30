import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../providers/staff_reservation_provider.dart';
import 'staff_reservation_card.dart';

class StaffReservationListView extends ConsumerWidget {
  final VoidCallback? onOpenCreateWalkIn;

  const StaffReservationListView({
    super.key,
    this.onOpenCreateWalkIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffReservationProvider);
    final notifier = ref.read(staffReservationProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final reservations = state.filteredReservations;

    if (state.isLoading && state.allReservations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (reservations.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => notifier.fetchReservations(showLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_seat_outlined,
                  size: 46,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Không có đơn đặt bàn nào',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  state.searchQuery.isNotEmpty
                      ? 'Không tìm thấy kết quả phù hợp với từ khóa "${state.searchQuery}".'
                      : 'Không có đơn đặt chỗ nào trong ngày ${state.apiDateString} với bộ lọc hiện tại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      notifier.setStatusFilter('ALL');
                      notifier.setFloorFilter('Tất cả');
                      notifier.setSearchQuery('');
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Đặt lại bộ lọc'),
                  ),
                  if (onOpenCreateWalkIn != null) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text('Đặt bàn mới', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: onOpenCreateWalkIn,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.fetchReservations(showLoading: false),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final res = reservations[index];
          return StaffReservationCard(
            key: ValueKey('res_${res.id}'),
            reservation: res,
          );
        },
      ),
    );
  }
}

