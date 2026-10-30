import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/attendance_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import 'widgets/attendance_header.dart';
import 'widgets/attendance_legend.dart';
import 'widgets/attendance_modal.dart';
import 'widgets/schedule_by_shift_table.dart';
import 'widgets/summary_by_employee_table.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: CrownAppBar(
        title: 'Bảng chấm công',
        showCart: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Tải lại dữ liệu',
            onPressed: () => notifier.fetchData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.fetchData(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header (Search, Week Navigator & View Mode)
                  const AttendanceHeader(),

                  const SizedBox(height: 14),

                  // 2. Status Legend Pills
                  const AttendanceLegend(),

                  const SizedBox(height: 14),

                  // 3. Main Attendance Table (Schedule by Shift vs Summary by Employee)
                  if (state.isLoading)
                    Container(
                      height: 350,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 12),
                          Text(
                            'Đang tải dữ liệu chấm công...',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else if (state.viewMode.isShift && state.scheduleData != null)
                    ScheduleByShiftTable(
                      data: state.scheduleData!,
                      onCellClick: (userId, shiftId, workDate) {
                        AttendanceModal.show(
                          context,
                          userId: userId,
                          defaultShiftId: shiftId,
                          defaultWorkDate: workDate,
                        );
                      },
                    )
                  else if (state.viewMode.isEmployee && state.summaryData != null)
                    SummaryByEmployeeTable(
                      data: state.summaryData!,
                      onEmployeeClick: (userId) {
                        AttendanceModal.show(context, userId: userId);
                      },
                    )
                  else
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        state.errorMessage ?? 'Không có dữ liệu chấm công',
                        style: TextStyle(
                          color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

