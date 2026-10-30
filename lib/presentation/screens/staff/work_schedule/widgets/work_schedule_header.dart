import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/work_schedule_model.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/staff_work_schedule_provider.dart';

class WorkScheduleHeader extends ConsumerWidget {
  final VoidCallback onAddShift;

  const WorkScheduleHeader({
    super.key,
    required this.onAddShift,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheduleState = ref.watch(staffWorkScheduleProvider);
    final scheduleNotifier = ref.read(staffWorkScheduleProvider.notifier);
    final authState = ref.watch(authProvider);

    final isStaffOrAdmin = authState.isStaff || authState.isAdmin;
    final currentUserId = authState.user?.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title, Week Navigator, View Mode Toggle, Add Shift Button
          Row(
            children: [
              // Icon & Title
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lịch làm việc',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Phân ca & Theo dõi lịch trực',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Week Navigation Controls
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      tooltip: 'Tuần trước',
                      onPressed: scheduleNotifier.prevWeek,
                      visualDensity: VisualDensity.compact,
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: scheduleState.referenceDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          scheduleNotifier.changeWeek(picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              scheduleState.weekRangeDisplay,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                      tooltip: 'Tuần sau',
                      onPressed: scheduleNotifier.nextWeek,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Button "Hôm nay"
              OutlinedButton.icon(
                onPressed: scheduleNotifier.goToCurrentWeek,
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Hôm nay'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  visualDensity: VisualDensity.compact,
                ),
              ),

              const SizedBox(width: 8),

              // View Mode Toggle (Table / Agenda)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.grid_view_rounded,
                        size: 18,
                        color: scheduleState.viewMode.isTable ? AppColors.primary : null,
                      ),
                      tooltip: 'Xem bảng tuần (Ma trận)',
                      onPressed: () => scheduleNotifier.setViewMode(WorkScheduleViewMode.table),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.view_agenda_rounded,
                        size: 18,
                        color: scheduleState.viewMode.isAgenda ? AppColors.primary : null,
                      ),
                      tooltip: 'Xem danh sách (Agenda)',
                      onPressed: () => scheduleNotifier.setViewMode(WorkScheduleViewMode.agenda),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              if (isStaffOrAdmin) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onAddShift,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Đăng ký / Thêm ca'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Row 2: Filters & Search Bar
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Input
              SizedBox(
                width: 220,
                height: 38,
                child: TextField(
                  onChanged: scheduleNotifier.setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Tìm nhân viên, mã ca...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),

              // Staff Selector Dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: scheduleState.selectedStaffId,
                    hint: const Text('Tất cả nhân viên', style: TextStyle(fontSize: 13)),
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả nhân viên', style: TextStyle(fontSize: 13)),
                      ),
                      ...scheduleState.availableStaffs.map((staff) {
                        return DropdownMenuItem<int?>(
                          value: staff.id,
                          child: Text(
                            '${staff.fullName} (NV${staff.id.toString().padLeft(6, '0')})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }),
                    ],
                    onChanged: (id) => scheduleNotifier.setSelectedStaff(id),
                  ),
                ),
              ),

              // Quick Toggle "Chỉ ca của tôi"
              FilterChip(
                selected: scheduleState.onlyMyShifts,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: scheduleState.onlyMyShifts
                          ? AppColors.primary
                          : (isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ca của tôi (${scheduleState.countMyShifts(currentUserId)})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            scheduleState.onlyMyShifts ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                onSelected: (val) => scheduleNotifier.toggleOnlyMyShifts(val),
                backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: scheduleState.onlyMyShifts
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
              ),

              // Filter by Shift (Shifts dropdown/chips)
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: scheduleState.selectedShiftId,
                    hint: const Text('Tất cả ca trực', style: TextStyle(fontSize: 13)),
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tất cả ca trực', style: TextStyle(fontSize: 13)),
                      ),
                      ...scheduleState.availableShifts.map((shift) {
                        return DropdownMenuItem<int?>(
                          value: shift.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: shift.themeColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(shift.displayName, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (id) => scheduleNotifier.setSelectedShift(id),
                  ),
                ),
              ),

              // Status Filter: Tất cả, Đã duyệt, Chờ duyệt
              _buildStatusChip(
                context,
                title: 'Tất cả (${scheduleState.totalShiftsInWeek})',
                code: 'ALL',
                selected: scheduleState.selectedStatus == 'ALL',
                onTap: () => scheduleNotifier.setSelectedStatus('ALL'),
              ),
              _buildStatusChip(
                context,
                title: 'Đã duyệt (${scheduleState.approvedShiftsInWeek})',
                code: 'APPROVED',
                selected: scheduleState.selectedStatus == 'APPROVED',
                color: WorkScheduleStatus.approved.color,
                onTap: () => scheduleNotifier.setSelectedStatus('APPROVED'),
              ),
              _buildStatusChip(
                context,
                title: 'Chờ duyệt (${scheduleState.pendingShiftsInWeek})',
                code: 'PENDING',
                selected: scheduleState.selectedStatus == 'PENDING',
                color: WorkScheduleStatus.pending.color,
                onTap: () => scheduleNotifier.setSelectedStatus('PENDING'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String title,
    required String code,
    required bool selected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? (color != null ? color.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15))
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? (color ?? AppColors.primary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? (color ?? AppColors.primary) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
