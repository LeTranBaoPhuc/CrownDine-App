import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/mock/mock_data.dart';
import '../../../../../data/models/attendance_model.dart';
import '../../../../../providers/attendance_provider.dart';

class AttendanceModal extends ConsumerStatefulWidget {
  final int userId;
  final int? defaultShiftId;
  final String? defaultWorkDate;

  const AttendanceModal({
    super.key,
    required this.userId,
    this.defaultShiftId,
    this.defaultWorkDate,
  });

  static Future<void> show(
    BuildContext context, {
    required int userId,
    int? defaultShiftId,
    String? defaultWorkDate,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AttendanceModal(
        userId: userId,
        defaultShiftId: defaultShiftId,
        defaultWorkDate: defaultWorkDate,
      ),
    );
  }

  @override
  ConsumerState<AttendanceModal> createState() => _AttendanceModalState();
}

class _AttendanceModalState extends ConsumerState<AttendanceModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late DateTime _workDate;
  int? _shiftId;
  AttendanceType _attendanceType = AttendanceType.working;
  bool _hasPunchIn = true;
  bool _hasPunchOut = true;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 16, minute: 0);
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _shiftId = widget.defaultShiftId ?? (MockData.sampleShifts.isNotEmpty ? MockData.sampleShifts.first.id : 1);
    if (widget.defaultWorkDate != null) {
      _workDate = DateTime.tryParse(widget.defaultWorkDate!) ?? DateTime.now();
    } else {
      _workDate = DateTime.now();
    }

    // Set times from selected shift if possible
    final matchingShift = MockData.sampleShifts.firstWhere(
      (s) => s.id == _shiftId,
      orElse: () => MockData.sampleShifts.first,
    );
    _checkInTime = TimeOfDay(hour: matchingShift.startHour, minute: 0);
    _checkOutTime = TimeOfDay(hour: matchingShift.endHour, minute: 0);

    // Load initial user history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceProvider.notifier).fetchUserHistory(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _handleSave() async {
    setState(() => _isSubmitting = true);

    final workDateStr = DateFormatter.toApiDate(_workDate);
    final req = AttendanceRecordRequest(
      userId: widget.userId,
      workDate: workDateStr,
      shiftId: _shiftId ?? 1,
      attendanceType: _attendanceType,
      hasPunchIn: _hasPunchIn,
      hasPunchOut: _hasPunchOut,
      checkInAt: _hasPunchIn ? _formatTimeOfDay(_checkInTime) : null,
      checkOutAt: _hasPunchOut ? _formatTimeOfDay(_checkOutTime) : null,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    final ok = await ref.read(attendanceProvider.notifier).saveRecord(req);
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lưu thông tin chấm công thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lưu thông tin chấm công, vui lòng thử lại'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(attendanceProvider);

    // Lookup staff info from mock or list
    final staff = MockData.staffList.firstWhere(
      (s) => s.id == widget.userId,
      orElse: () => MockData.staffList.first,
    );
    final staffStatus = MockData.getEmployeeAttendanceStatus(widget.userId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Employee Banner Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: staff.avatarUrl != null ? NetworkImage(staff.avatarUrl!) : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: staff.avatarUrl == null
                        ? Text(staff.fullName[0], style: const TextStyle(fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'NV${staff.id.toString().padLeft(6, '0')} • ${staff.membershipTier ?? staff.role.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: staffStatus.backgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: staffStatus.color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: staffStatus.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          staffStatus.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: staffStatus.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Tab Bar (Cập nhật vs Lịch sử)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primary,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Cập nhật chấm công'),
                    Tab(text: 'Lịch sử chấm công'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Form cập nhật
                    _buildFormTab(context, isDark),

                    // Tab 2: Lịch sử chấm công
                    _buildHistoryTab(state, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTab(BuildContext context, bool isDark) {
    final shifts = MockData.sampleShifts;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Ca làm & Ngày làm
          Row(
            children: [
              // Shift Dropdown
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ca làm việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _shiftId,
                          items: shifts.map((s) {
                            return DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(
                                '${s.name} (${s.displayTimeRange})',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              setState(() {
                                _shiftId = id;
                                final s = shifts.firstWhere((item) => item.id == id);
                                _checkInTime = TimeOfDay(hour: s.startHour, minute: 0);
                                _checkOutTime = TimeOfDay(hour: s.endHour, minute: 0);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Date Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ngày làm việc', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _workDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _workDate = picked);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy').format(_workDate),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Attendance Type
          const Text('Hình thức', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AttendanceType>(
                isExpanded: true,
                value: _attendanceType,
                items: AttendanceType.values.map((type) {
                  return DropdownMenuItem<AttendanceType>(
                    value: type,
                    child: Text(type.displayName, style: const TextStyle(fontSize: 12.5)),
                  );
                }).toList(),
                onChanged: (t) {
                  if (t != null) setState(() => _attendanceType = t);
                },
              ),
            ),
          ),

          // Working Time Punch In/Out (only if working)
          if (_attendanceType == AttendanceType.working) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // Check-in
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasPunchIn,
                            onChanged: (v) => setState(() => _hasPunchIn = v ?? true),
                            activeColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          const Text('Chấm công vào', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (_hasPunchIn)
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _checkInTime,
                            );
                            if (picked != null) setState(() => _checkInTime = picked);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(_formatTimeOfDay(_checkInTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Check-out
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _hasPunchOut,
                            onChanged: (v) => setState(() => _hasPunchOut = v ?? true),
                            activeColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                          const Text('Chấm công ra', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (_hasPunchOut)
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _checkOutTime,
                            );
                            if (picked != null) setState(() => _checkOutTime = picked);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(_formatTimeOfDay(_checkOutTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 14),

          // Note Field
          const Text('Ghi chú lý do / giải trình', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú hoặc lý do đi muộn / nghỉ phép...',
              hintStyle: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
              ),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            style: const TextStyle(fontSize: 12.5),
          ),

          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Lưu thông tin chấm công', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AttendanceState state, bool isDark) {
    if (state.isHistoryLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.userHistory.isEmpty) {
      return Center(
        child: Text(
          'Chưa có lịch sử chấm công',
          style: TextStyle(
            color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: state.userHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = state.userHistory[idx];

        return Container(
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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: item.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.content ?? item.status.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.time,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.status.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.status.color,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
