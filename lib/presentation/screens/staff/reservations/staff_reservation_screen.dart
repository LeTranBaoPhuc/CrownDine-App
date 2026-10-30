import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../providers/staff_reservation_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import 'widgets/staff_create_reservation_sheet.dart';
import 'widgets/staff_reservation_calendar_view.dart';
import 'widgets/staff_reservation_list_view.dart';

class StaffReservationScreen extends ConsumerStatefulWidget {
  const StaffReservationScreen({super.key});

  @override
  ConsumerState<StaffReservationScreen> createState() => _StaffReservationScreenState();
}

class _StaffReservationScreenState extends ConsumerState<StaffReservationScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffReservationProvider);
    final notifier = ref.read(staffReservationProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CrownAppBar(
        title: 'Quản lý Đặt bàn',
        showCart: false,
        actions: [
          // Toggle View Mode (List vs Calendar)
          IconButton(
            icon: Icon(
              state.viewMode.isList ? Icons.calendar_view_week_outlined : Icons.view_agenda_outlined,
              size: 22,
            ),
            tooltip: state.viewMode.isList ? 'Xem theo lịch bàn' : 'Xem theo danh sách',
            onPressed: () => notifier.toggleViewMode(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Date Navigation Bar
          _buildDateHeader(isDark, state, notifier),

          // 2. Search & Floor Filter Bar
          _buildSearchAndFilters(isDark, state, notifier),

          // 3. Status Filter Chips
          _buildStatusChips(isDark, state, notifier),

          const Divider(height: 1),

          // 4. Main Body: List View or Calendar Timeline View
          Expanded(
            child: state.viewMode.isList
                ? StaffReservationListView(
                    onOpenCreateWalkIn: () => StaffCreateReservationSheet.show(context),
                  )
                : const StaffReservationCalendarView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add),
        label: const Text('Đặt bàn mới', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => StaffCreateReservationSheet.show(context),
      ),
    );
  }

  /// 1. Thanh điều hướng ngày (Hôm nay / Trước / Sau / DatePicker)
  Widget _buildDateHeader(
    bool isDark,
    StaffReservationState state,
    StaffReservationNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous day button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Ngày trước',
            onPressed: () => notifier.prevDay(),
          ),

          // Date Picker Trigger
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: state.selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  notifier.setDate(picked);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormatter.friendly(state.selectedDate)} (${DateFormatter.format(state.selectedDate)})',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textLight : AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),

          // Next day button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Ngày tiếp theo',
            onPressed: () => notifier.nextDay(),
          ),

          // "Hôm nay" quick jump button
          if (DateFormatter.toApiDate(state.selectedDate) != DateFormatter.toApiDate(DateTime.now())) ...[
            const SizedBox(width: 4),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => notifier.setToday(),
              child: const Text(
                'Hôm nay',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 2. Thanh tìm kiếm và bộ lọc Tầng
  Widget _buildSearchAndFilters(
    bool isDark,
    StaffReservationState state,
    StaffReservationNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Row(
        children: [
          // Search TextField
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => notifier.setSearchQuery(val),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm khách, SĐT, mã đặt, bàn...',
                  hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            notifier.setSearchQuery('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Floor filter popup menu
          PopupMenuButton<String>(
            tooltip: 'Lọc theo tầng',
            initialValue: state.selectedFloor,
            onSelected: (floor) => notifier.setFloorFilter(floor),
            itemBuilder: (ctx) {
              return state.availableFloors.map((floor) {
                return PopupMenuItem<String>(
                  value: floor,
                  child: Row(
                    children: [
                      Icon(
                        floor == 'Tất cả' ? Icons.layers_outlined : Icons.apartment,
                        size: 16,
                        color: state.selectedFloor == floor ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        floor,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: state.selectedFloor == floor ? FontWeight.bold : FontWeight.normal,
                          color: state.selectedFloor == floor ? AppColors.primary : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: state.selectedFloor != 'Tất cả'
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.selectedFloor != 'Tất cả'
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 16,
                    color: state.selectedFloor != 'Tất cả' ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.selectedFloor,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: state.selectedFloor != 'Tất cả' ? AppColors.primary : null,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Dải Chip trạng thái cuộn ngang
  Widget _buildStatusChips(
    bool isDark,
    StaffReservationState state,
    StaffReservationNotifier notifier,
  ) {
    final chips = [
      {'code': 'ALL', 'label': 'Tất cả', 'count': state.countAll},
      {'code': 'CONFIRMED', 'label': 'Đã xác nhận', 'count': state.countConfirmed},
      {'code': 'CHECKED_IN', 'label': 'Đã nhận bàn', 'count': state.countCheckedIn},
      {'code': 'PENDING', 'label': 'Chờ duyệt', 'count': state.countPending},
      {'code': 'COMPLETED', 'label': 'Hoàn tất', 'count': state.countCompleted},
      {'code': 'CANCELLED', 'label': 'Đã hủy', 'count': state.countCancelled},
    ];

    return Container(
      height: 46,
      color: isDark ? AppColors.darkCard : Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final item = chips[i];
          final isSelected = state.selectedStatus == item['code'];
          final count = item['count'] as int;

          return GestureDetector(
            onTap: () => notifier.setStatusFilter(item['code'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
