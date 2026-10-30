import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../providers/attendance_provider.dart';

class AttendanceHeader extends ConsumerWidget {
  const AttendanceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // 1. Search Bar
          SizedBox(
            width: 240,
            height: 40,
            child: TextField(
              onChanged: notifier.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm nhân viên...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                prefixIconConstraints: const BoxConstraints(minWidth: 36),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // 2. Week Navigation Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
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
                      onPressed: notifier.goPrevWeek,
                      visualDensity: VisualDensity.compact,
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.referenceDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          notifier.changeDate(picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.periodLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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
                      onPressed: notifier.goNextWeek,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Button "Hôm nay"
              OutlinedButton.icon(
                onPressed: notifier.goToCurrentWeek,
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Hôm nay'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
            ],
          ),

          // 3. View Mode Dropdown
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AttendanceViewMode>(
                value: state.viewMode,
                icon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
                items: AttendanceViewMode.values.map((mode) {
                  return DropdownMenuItem<AttendanceViewMode>(
                    value: mode,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          mode.isShift
                              ? Icons.grid_view_rounded
                              : Icons.format_list_bulleted_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(mode.displayName, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (mode) {
                  if (mode != null) notifier.setViewMode(mode);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

