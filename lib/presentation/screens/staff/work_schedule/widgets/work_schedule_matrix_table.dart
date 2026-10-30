import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/models/user_model.dart';
import '../../../../../data/models/work_schedule_model.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/staff_work_schedule_provider.dart';
import 'add_schedule_dialog.dart';
import 'shift_detail_dialog.dart';

class WorkScheduleMatrixTable extends ConsumerStatefulWidget {
  const WorkScheduleMatrixTable({super.key});

  @override
  ConsumerState<WorkScheduleMatrixTable> createState() => _WorkScheduleMatrixTableState();
}

class _WorkScheduleMatrixTableState extends ConsumerState<WorkScheduleMatrixTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const double _staffColWidth = 210.0;
  static const double _dayColWidth = 145.0;
  static const double _minRowHeight = 90.0;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheduleState = ref.watch(staffWorkScheduleProvider);
    final authState = ref.watch(authProvider);

    final staffs = scheduleState.filteredStaffs;
    final weekDays = scheduleState.weekDays;
    final todayStr = DateFormatter.toApiDate(DateTime.now());

    if (scheduleState.isLoading) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 12),
            Text('Đang tải dữ liệu lịch làm việc...', style: TextStyle(fontSize: 13)),
          ],
        ),
      );
    }

    if (staffs.isEmpty) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy nhân viên phù hợp với bộ lọc',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Vui lòng thử tìm kiếm với tên hoặc mã nhân viên khác',
              style: TextStyle(color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _staffColWidth + (7 * _dayColWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Table Header (Staff Column + 7 Days of the Week)
                _buildTableHeader(context, weekDays, todayStr, isDark),

                const Divider(height: 1),

                // 2. Table Body (Each row is a Staff Member)
                ...staffs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final staff = entry.value;
                  final isEven = index % 2 == 0;

                  return _buildStaffRow(
                    context,
                    staff: staff,
                    weekDays: weekDays,
                    todayStr: todayStr,
                    isEven: isEven,
                    isDark: isDark,
                    canAddShift: authState.isAdmin || staff.id == authState.user?.id,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    BuildContext context,
    List<DateTime> weekDays,
    String todayStr,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final dayNames = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];

    return Container(
      color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
      child: Row(
        children: [
          // Left Sticky Header: Staff
          Container(
            width: _staffColWidth,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Nhân viên',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 7 Day Headers
          ...weekDays.map((date) {
            final dateStr = DateFormatter.toApiDate(date);
            final isToday = dateStr == todayStr;
            final dayName = dayNames[date.weekday];
            final dayNumber = date.day.toString().padLeft(2, '0');

            return Container(
              width: _dayColWidth,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                      color: isToday
                          ? AppColors.primary
                          : (isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStaffRow(
    BuildContext context, {
    required UserModel staff,
    required List<DateTime> weekDays,
    required String todayStr,
    required bool isEven,
    required bool isDark,
    required bool canAddShift,
  }) {
    final scheduleState = ref.watch(staffWorkScheduleProvider);
    final rowBg = isEven
        ? Colors.transparent
        : (isDark ? AppColors.darkSurface.withValues(alpha: 0.4) : const Color(0xFFFAFBFD));

    return Container(
      decoration: BoxDecoration(
        color: rowBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Staff Info Card
            Container(
              width: _staffColWidth,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: staff.avatarUrl != null
                        ? NetworkImage(staff.avatarUrl!)
                        : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: staff.avatarUrl == null
                        ? Text(
                            staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          staff.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NV${staff.id.toString().padLeft(6, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.textLightSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (staff.membershipTier != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            staff.membershipTier!,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 7 Day Cells
            ...weekDays.map((date) {
              final dateStr = DateFormatter.toApiDate(date);
              final isToday = dateStr == todayStr;
              final shifts = scheduleState.getShiftsForStaffAndDay(staff.id, dateStr);

              return Container(
                width: _dayColWidth,
                constraints: const BoxConstraints(minHeight: _minRowHeight),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.03)
                      : Colors.transparent,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shifts in this cell
                    ...shifts.map((schedule) {
                      return _buildShiftItem(context, schedule, isDark);
                    }),

                    const Spacer(),

                    // Add Shift Button on Cell Hover/Tap
                    if (canAddShift)
                      InkWell(
                        onTap: () {
                          AddScheduleDialog.show(
                            context,
                            initialStaff: staff,
                            initialDate: dateStr,
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: AppColors.primary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Thêm ca',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftItem(
    BuildContext context,
    WorkScheduleModel schedule,
    bool isDark,
  ) {
    final shiftColor = schedule.shift.themeColor;
    final isPending = schedule.status == WorkScheduleStatus.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: '${schedule.shift.name} (${schedule.shift.displayTimeRange})\n${schedule.note ?? 'Trực ca thường'}',
        child: InkWell(
          onTap: () => ShiftDetailDialog.show(context, schedule),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? shiftColor.withValues(alpha: 0.18)
                  : shiftColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isPending
                    ? AppColors.warning
                    : shiftColor.withValues(alpha: 0.4),
                width: isPending ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isPending ? AppColors.warning : shiftColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        schedule.shift.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : shiftColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  schedule.shift.displayTimeRange,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Chờ duyệt',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
