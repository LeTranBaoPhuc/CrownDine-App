import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/models/attendance_model.dart';

class ScheduleByShiftTable extends StatelessWidget {
  final AttendanceScheduleResponse data;
  final Function(int userId, int shiftId, String workDate) onCellClick;

  const ScheduleByShiftTable({
    super.key,
    required this.data,
    required this.onCellClick,
  });

  static const double _shiftColWidth = 180.0;
  static const double _dayColWidth = 150.0;
  static const double _minRowHeight = 90.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final todayStr = DateFormatter.toApiDate(DateTime.now());

    // Generate 7 days from weekStart
    final start = DateTime.tryParse(data.weekStart) ?? DateTime.now();
    final dayNames = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    final days = List.generate(7, (i) {
      final d = start.add(Duration(days: i));
      return {
        'dayOfWeek': dayNames[i],
        'dateShort': '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
        'date': DateFormatter.toApiDate(d),
      };
    });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _shiftColWidth + (7 * _dayColWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Container(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                  child: Row(
                    children: [
                      // Shift Column Header
                      Container(
                        width: _shiftColWidth,
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
                            const Icon(Icons.access_time_filled_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Ca làm việc',
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // 7 Day Headers
                      ...days.map((d) {
                        final dateStr = d['date']!;
                        final isToday = dateStr == todayStr;

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
                                d['dayOfWeek']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                  color: isToday
                                      ? AppColors.primary
                                      : (isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                d['dateShort']!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? AppColors.primary : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Shift Rows
                ...data.shifts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final shift = entry.value;
                  final isEven = index % 2 == 0;
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
                          // Left Column: Shift Info
                          Container(
                            width: _shiftColWidth,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
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
                                    Expanded(
                                      child: Text(
                                        shift.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  shift.displayTimeRange,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 7 Day Cells
                          ...days.map((d) {
                            final dateStr = d['date']!;
                            final isToday = dateStr == todayStr;
                            final cell = data.getCell(shift.id, dateStr);
                            final employees = cell?.employees ?? const [];

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
                              child: employees.isEmpty
                                  ? const Center(
                                      child: Text(
                                        '-',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: employees.map((emp) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 5),
                                          child: InkWell(
                                            onTap: () => onCellClick(emp.userId, shift.id, dateStr),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? AppColors.darkSurface
                                                    : emp.status.backgroundColor,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: emp.status.color.withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 7,
                                                    height: 7,
                                                    decoration: BoxDecoration(
                                                      color: emp.status.color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      emp.fullName,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? Colors.white : AppColors.textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

