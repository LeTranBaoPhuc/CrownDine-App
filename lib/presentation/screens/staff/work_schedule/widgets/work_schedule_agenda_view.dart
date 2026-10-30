import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/staff_work_schedule_provider.dart';
import 'add_schedule_dialog.dart';
import 'shift_detail_dialog.dart';

class WorkScheduleAgendaView extends ConsumerWidget {
  const WorkScheduleAgendaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheduleState = ref.watch(staffWorkScheduleProvider);
    final authState = ref.watch(authProvider);

    final weekDays = scheduleState.weekDays;
    final todayStr = DateFormatter.toApiDate(DateTime.now());

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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final date = weekDays[index];
        final dateStr = DateFormatter.toApiDate(date);
        final isToday = dateStr == todayStr;
        final dayName = dayNames[date.weekday];
        final fullDateStr = '$dayName, ${DateFormat('dd/MM/yyyy').format(date)}';
        final shifts = scheduleState.getShiftsForDay(dateStr);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isToday
                  ? AppColors.primary.withValues(alpha: 0.6)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isToday ? 1.5 : 1,
            ),
            boxShadow: [
              if (isToday)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.primary : (isDark ? AppColors.darkCard : Colors.white),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isToday ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        date.day.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isToday ? Colors.white : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            fullDateStr,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isToday ? AppColors.primary : null,
                            ),
                          ),
                          if (isToday) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Hôm nay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      '${shifts.length} ca trực',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (authState.isAdmin || authState.isStaff)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primary),
                        tooltip: 'Thêm ca trực ngày này',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          AddScheduleDialog.show(context, initialDate: dateStr);
                        },
                      ),
                  ],
                ),
              ),

              // Shifts List in this Day
              if (shifts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  child: Center(
                    child: Text(
                      'Không có ca làm việc nào được phân công trong ngày này',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: shifts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, shiftIdx) {
                    final schedule = shifts[shiftIdx];
                    final shiftColor = schedule.shift.themeColor;

                    return InkWell(
                      onTap: () => ShiftDetailDialog.show(context, schedule),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Staff Avatar
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: schedule.user.avatarUrl != null
                                  ? NetworkImage(schedule.user.avatarUrl!)
                                  : null,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                              child: schedule.user.avatarUrl == null
                                  ? Text(
                                      schedule.user.fullName.isNotEmpty
                                          ? schedule.user.fullName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Staff Name & Code
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    schedule.user.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${schedule.employeeCode} • ${schedule.user.membershipTier ?? schedule.user.role.displayName}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                  if (schedule.note != null && schedule.note!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.note_alt_outlined,
                                          size: 13,
                                          color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            schedule.note!,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Shift Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: shiftColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: shiftColor.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    schedule.shift.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: shiftColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    schedule.shift.displayTimeRange,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Status Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: schedule.status.backgroundColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: schedule.status.color.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                schedule.status.displayName,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: schedule.status.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
