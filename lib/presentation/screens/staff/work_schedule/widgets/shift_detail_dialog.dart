import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/work_schedule_model.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/staff_work_schedule_provider.dart';

class ShiftDetailDialog extends ConsumerWidget {
  final WorkScheduleModel schedule;

  const ShiftDetailDialog({
    super.key,
    required this.schedule,
  });

  static Future<void> show(BuildContext context, WorkScheduleModel schedule) {
    return showDialog(
      context: context,
      builder: (ctx) => ShiftDetailDialog(schedule: schedule),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final scheduleNotifier = ref.read(staffWorkScheduleProvider.notifier);

    final canDelete = authState.isAdmin || schedule.user.id == authState.user?.id;

    // Format date in Vietnamese
    DateTime? date = schedule.parsedDate;
    String dateStr = schedule.workDate;
    if (date != null) {
      final daysOfWeek = [
        '',
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ Nhật'
      ];
      final dayName = daysOfWeek[date.weekday];
      dateStr = '$dayName, ${DateFormat('dd/MM/yyyy').format(date)}';
    }

    final shiftColor = schedule.shift.themeColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: shiftColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.access_time_filled_rounded, color: shiftColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.shift.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          schedule.shift.displayTimeRange,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: shiftColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: schedule.status.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: schedule.status.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: schedule.status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          schedule.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: schedule.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Staff Information Row
              Text(
                'Nhân viên phân công',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: schedule.user.avatarUrl != null
                          ? NetworkImage(schedule.user.avatarUrl!)
                          : null,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: schedule.user.avatarUrl == null
                          ? Text(
                              schedule.user.fullName.isNotEmpty
                                  ? schedule.user.fullName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            '${schedule.employeeCode} • ${schedule.user.membershipTier ?? schedule.user.role.displayName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textLightSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Date Info
              _buildInfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Ngày trực',
                value: dateStr,
                theme: theme,
                isDark: isDark,
              ),

              const SizedBox(height: 10),

              // Note Info (if any)
              if (schedule.note != null && schedule.note!.isNotEmpty) ...[
                _buildInfoRow(
                  icon: Icons.note_alt_outlined,
                  label: 'Ghi chú / Phân công',
                  value: schedule.note!,
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
              ],

              // Repeat Pattern info
              if (schedule.repeatGroupId != null) ...[
                _buildInfoRow(
                  icon: Icons.repeat_rounded,
                  label: 'Lặp lại',
                  value: 'Ca trực định kỳ hàng tuần',
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canDelete) ...[
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Xác nhận xóa ca làm việc'),
                            content: Text(
                              'Bạn có chắc chắn muốn xóa ca ${schedule.shift.name} của ${schedule.user.fullName} vào ngày $dateStr?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Hủy'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(c, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Xóa ca'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          Navigator.pop(context);
                          final ok = await scheduleNotifier.deleteSchedule(schedule.id);
                          if (ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã xóa ca làm việc thành công'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                      label: const Text('Xóa ca', style: TextStyle(color: AppColors.error)),
                    ),
                    const SizedBox(width: 8),
                  ],

                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
