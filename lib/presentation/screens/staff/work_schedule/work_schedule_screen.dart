import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/staff_work_schedule_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import 'widgets/add_schedule_dialog.dart';
import 'widgets/work_schedule_agenda_view.dart';
import 'widgets/work_schedule_header.dart';
import 'widgets/work_schedule_matrix_table.dart';

class WorkScheduleScreen extends ConsumerStatefulWidget {
  const WorkScheduleScreen({super.key});

  @override
  ConsumerState<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends ConsumerState<WorkScheduleScreen> {
  bool _hasCheckedScreenSize = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheduleState = ref.watch(staffWorkScheduleProvider);
    final scheduleNotifier = ref.read(staffWorkScheduleProvider.notifier);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: CrownAppBar(
        title: 'Lịch làm việc',
        showCart: false,
        actions: [
          // Toggle View Mode (Table / Agenda)
          IconButton(
            icon: Icon(
              scheduleState.viewMode.isTable
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_outlined,
              size: 22,
            ),
            tooltip: scheduleState.viewMode.isTable
                ? 'Chuyển sang xem danh sách (Agenda)'
                : 'Chuyển sang xem bảng ma trận tuần',
            onPressed: () => scheduleNotifier.toggleViewMode(),
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Tải lại dữ liệu',
            onPressed: () => scheduleNotifier.fetchSchedules(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Auto switch to agenda mode for small mobile screens on first load
          if (!_hasCheckedScreenSize) {
            _hasCheckedScreenSize = true;
            if (constraints.maxWidth < 700 && scheduleState.viewMode.isTable) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                scheduleNotifier.setViewMode(WorkScheduleViewMode.agenda);
              });
            }
          }

          return RefreshIndicator(
            onRefresh: () => scheduleNotifier.fetchSchedules(),
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
                      // 1. Pending Approval Banner (if any)
                      if (scheduleState.pendingShiftsInWeek > 0) ...[
                        _buildPendingBanner(
                          context,
                          scheduleState.pendingShiftsInWeek,
                          isDark,
                          onFilterPending: () => scheduleNotifier.setSelectedStatus('PENDING'),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 2. Schedule Header (Controls, Date Navigator & Filters)
                      WorkScheduleHeader(
                        onAddShift: () => AddScheduleDialog.show(context),
                      ),

                      const SizedBox(height: 12),

                      // 3. Main Schedule Content (Matrix Table vs Agenda List)
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: scheduleState.viewMode.isTable
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: const WorkScheduleMatrixTable(),
                        secondChild: const WorkScheduleAgendaView(),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: (authState.isAdmin || authState.isStaff)
          ? FloatingActionButton.extended(
              onPressed: () => AddScheduleDialog.show(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.more_time_rounded),
              label: const Text(
                'Phân ca / Đăng ký',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildPendingBanner(
    BuildContext context,
    int pendingCount,
    bool isDark, {
    required VoidCallback onFilterPending,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Có $pendingCount ca làm việc đang chờ phê duyệt trong tuần này.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ),
          TextButton(
            onPressed: onFilterPending,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: const Color(0xFFB45309),
            ),
            child: const Text('Xem ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

