import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/mock/mock_data.dart';
import '../../../../../data/models/reservation_model.dart';
import '../../../../../providers/staff_reservation_provider.dart';
import '../../../../../providers/table_provider.dart';
import 'reservation_detail_sheet.dart';
import 'staff_create_reservation_sheet.dart';

class StaffReservationCalendarView extends ConsumerStatefulWidget {
  const StaffReservationCalendarView({super.key});

  @override
  ConsumerState<StaffReservationCalendarView> createState() => _StaffReservationCalendarViewState();
}

class _StaffReservationCalendarViewState extends ConsumerState<StaffReservationCalendarView> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const double _hourWidth = 85.0;
  static const double _tableColWidth = 125.0;
  static const double _rowHeight = 68.0;
  static const int _startHour = 8;
  static const int _endHour = 22; // 08:00 to 22:00 (14 hours)

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.confirmed:
        return AppColors.success;
      case ReservationStatus.checkedIn:
        return AppColors.info;
      case ReservationStatus.pending:
        return AppColors.warning;
      case ReservationStatus.completed:
        return Colors.teal;
      case ReservationStatus.cancelled:
        return AppColors.error;
      case ReservationStatus.noShow:
        return Colors.grey;
    }
  }

  double? _calculateNowOffset(DateTime selectedDate) {
    final now = DateTime.now();
    if (DateFormatter.toApiDate(now) != DateFormatter.toApiDate(selectedDate)) {
      return null;
    }
    if (now.hour < _startHour || now.hour >= _endHour) {
      return null;
    }
    final totalMinutes = (now.hour - _startHour) * 60 + now.minute;
    return (totalMinutes / 60.0) * _hourWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final staffState = ref.watch(staffReservationProvider);
    final tableState = ref.watch(tableProvider);

    final allTables = tableState.allTables.isNotEmpty ? tableState.allTables : MockData.tables;

    // Filter tables by floor
    final tables = allTables.where((t) {
      if (staffState.selectedFloor != 'Tất cả' && 'Tầng ${t.floorId}' != staffState.selectedFloor) {
        return false;
      }
      if (staffState.selectedArea != 'Tất cả' && t.areaName != staffState.selectedArea) {
        return false;
      }
      return true;
    }).toList();

    // Reservations matching current date and filters
    final reservations = staffState.filteredReservations;
    final nowOffset = _calculateNowOffset(staffState.selectedDate);
    final totalTimelineWidth = (_endHour - _startHour) * _hourWidth;

    return Column(
      children: [
        // Color Legend Bar
        _buildLegendBar(isDark),
        const Divider(height: 1),

        // Main 2D Grid
        Expanded(
          child: tables.isEmpty
              ? Center(
                  child: Text(
                    'Không có bàn nào phù hợp với bộ lọc ${staffState.selectedFloor}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Row(
                  children: [
                    // Left Sticky Column: Tables
                    SizedBox(
                      width: _tableColWidth,
                      child: Column(
                        children: [
                          // Table Header Cell
                          Container(
                            height: 40,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                              border: Border(
                                right: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                                bottom: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                            ),
                            child: const Text(
                              'BÀN / VỊ TRÍ',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),

                          // Table Rows
                          Expanded(
                            child: ListView.builder(
                              controller: _verticalController,
                              itemCount: tables.length,
                              itemBuilder: (ctx, i) {
                                final t = tables[i];
                                return Container(
                                  height: _rowHeight,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : Colors.white,
                                    border: Border(
                                      right: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                      bottom: BorderSide(
                                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        t.name,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppColors.textLight : AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.people, size: 11, color: isDark ? Colors.white60 : AppColors.textSecondary),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${t.capacity} chỗ',
                                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'T${t.floorId}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right Scrollable Grid: Timeline Header + Table Time Tracks
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: totalTimelineWidth,
                          child: Column(
                            children: [
                              // Top Sticky Hours Header
                              Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Row(
                                      children: List.generate(_endHour - _startHour, (i) {
                                        final hour = _startHour + i;
                                        return Container(
                                          width: _hourWidth,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            '${hour.toString().padLeft(2, '0')}:00',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        );
                                      }),
                                    ),

                                    // Current Time Indicator Header
                                    if (nowOffset != null)
                                      Positioned(
                                        left: nowOffset - 5,
                                        top: 8,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Grid Rows with Reservation Blocks
                              Expanded(
                                child: ListView.builder(
                                  itemCount: tables.length,
                                  itemBuilder: (ctx, i) {
                                    final t = tables[i];
                                    final tableReservations = reservations.where((r) => r.tableId == t.id).toList();

                                    return Container(
                                      height: _rowHeight,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.darkBackground : Colors.white,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                          ),
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Background Hour Grid Lines & Tap Detectors
                                          Row(
                                            children: List.generate(_endHour - _startHour, (hIndex) {
                                              final hour = _startHour + hIndex;
                                              return InkWell(
                                                onTap: () {
                                                  final timeStr = '${hour.toString().padLeft(2, '0')}:00';
                                                  StaffCreateReservationSheet.show(
                                                    context,
                                                    initialDate: staffState.selectedDate,
                                                    initialStartTime: timeStr,
                                                    initialTableId: t.id,
                                                  );
                                                },
                                                child: Container(
                                                  width: _hourWidth,
                                                  height: _rowHeight,
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: BorderSide(
                                                        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                                                            .withValues(alpha: 0.5),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),

                                          // Red Line: Current Time Indicator
                                          if (nowOffset != null)
                                            Positioned(
                                              left: nowOffset,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 2,
                                                color: Colors.red.withValues(alpha: 0.8),
                                              ),
                                            ),

                                          // Reservation Cards
                                          ...tableReservations.map((res) {
                                            return _buildReservationBlock(res);
                                          }),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildReservationBlock(ReservationModel res) {
    final startParts = res.startTime.split(':');
    final startHour = int.tryParse(startParts[0]) ?? 12;
    final startMin = int.tryParse(startParts.length > 1 ? startParts[1] : '0') ?? 0;

    int endHour = startHour + 2;
    int endMin = startMin;
    if (res.endTime != null && res.endTime!.contains(':')) {
      final endParts = res.endTime!.split(':');
      endHour = int.tryParse(endParts[0]) ?? (startHour + 2);
      endMin = int.tryParse(endParts[1]) ?? 0;
    }

    final startTotalMin = (startHour - _startHour) * 60 + startMin;
    final endTotalMin = (endHour - _startHour) * 60 + endMin;
    final durationMin = max(endTotalMin - startTotalMin, 60);

    final left = max((startTotalMin / 60.0) * _hourWidth, 0.0);
    final width = max((durationMin / 60.0) * _hourWidth, 75.0);
    final statusColor = _getStatusColor(res.status);

    return Positioned(
      left: left + 2,
      top: 4,
      width: width - 4,
      height: _rowHeight - 8,
      child: GestureDetector(
        onTap: () => ReservationDetailSheet.show(context, res),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      res.displayName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${res.guestNumber}k',
                      style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                res.displayTimeRange,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBar(bool isDark) {
    final legends = [
      {'color': AppColors.success, 'label': 'Đã xác nhận'},
      {'color': AppColors.info, 'label': 'Đang phục vụ'},
      {'color': AppColors.warning, 'label': 'Chờ duyệt'},
      {'color': Colors.teal, 'label': 'Hoàn tất'},
      {'color': AppColors.error, 'label': 'Đã hủy'},
    ];

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: legends.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (ctx, i) {
          final l = legends[i];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: l['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                l['label'] as String,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }
}
