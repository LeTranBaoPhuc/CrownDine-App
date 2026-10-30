import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/models/user_model.dart';
import '../../../../../providers/staff_work_schedule_provider.dart';

class AddScheduleDialog extends ConsumerStatefulWidget {
  final UserModel? initialStaff;
  final String? initialDate;

  const AddScheduleDialog({
    super.key,
    this.initialStaff,
    this.initialDate,
  });

  static Future<bool?> show(
    BuildContext context, {
    UserModel? initialStaff,
    String? initialDate,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AddScheduleDialog(
        initialStaff: initialStaff,
        initialDate: initialDate,
      ),
    );
  }

  @override
  ConsumerState<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends ConsumerState<AddScheduleDialog> {
  int? _selectedStaffId;
  int? _selectedShiftId;
  late DateTime _selectedDate;
  bool _repeatWeekly = false;
  final Set<int> _selectedDays = {}; // 1 to 7 (Mon to Sun)
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedStaffId = widget.initialStaff?.id;
    if (widget.initialDate != null) {
      _selectedDate = DateTime.tryParse(widget.initialDate!) ?? DateTime.now();
    } else {
      _selectedDate = DateTime.now();
    }
    // Default current weekday to repeat selection
    _selectedDays.add(_selectedDate.weekday);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn nhân viên phân ca')),
      );
      return;
    }

    if (_selectedShiftId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn loại ca làm việc')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final workDateStr = DateFormatter.toApiDate(_selectedDate);
    final notifier = ref.read(staffWorkScheduleProvider.notifier);

    final success = await notifier.createSchedule(
      staffIds: [_selectedStaffId!],
      shiftId: _selectedShiftId!,
      workDate: workDateStr,
      repeatWeekly: _repeatWeekly,
      daysOfWeek: _repeatWeekly ? _selectedDays.toList() : const [],
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phân ca làm việc thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phân ca thất bại, vui lòng thử lại'),
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
    final scheduleState = ref.watch(staffWorkScheduleProvider);
    final staffs = scheduleState.availableStaffs;
    final shifts = scheduleState.availableShifts;

    // Default select first shift if not selected
    if (_selectedShiftId == null && shifts.isNotEmpty) {
      _selectedShiftId = shifts.first.id;
    }
    // Default select first staff if not selected
    if (_selectedStaffId == null && staffs.isNotEmpty) {
      _selectedStaffId = staffs.first.id;
    }

    final dayLabels = [
      {'val': 1, 'label': 'T2'},
      {'val': 2, 'label': 'T3'},
      {'val': 3, 'label': 'T4'},
      {'val': 4, 'label': 'T5'},
      {'val': 5, 'label': 'T6'},
      {'val': 6, 'label': 'T7'},
      {'val': 7, 'label': 'CN'},
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.more_time_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đăng ký / Phân ca làm việc',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Thiết lập ca trực cho nhân viên',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Staff Selector
              Text('Nhân viên', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedStaffId,
                    items: staffs.map((staff) {
                      return DropdownMenuItem<int>(
                        value: staff.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: staff.avatarUrl != null
                                  ? NetworkImage(staff.avatarUrl!)
                                  : null,
                              child: staff.avatarUrl == null
                                  ? Text(staff.fullName[0], style: const TextStyle(fontSize: 10))
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                            const SizedBox(width: 6),
                            Text('(${staff.membershipTier ?? staff.role.displayName})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                )),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (id) => setState(() => _selectedStaffId = id),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Date Picker
              Text('Ngày làm việc', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      _selectedDays.clear();
                      _selectedDays.add(picked.weekday);
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Shift Selector
              Text('Chọn ca làm việc', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shifts.map((shift) {
                  final isSelected = _selectedShiftId == shift.id;
                  final shiftColor = shift.themeColor;

                  return ChoiceChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: shiftColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${shift.name} (${shift.displayTimeRange})',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? shiftColor : null,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedShiftId = shift.id);
                    },
                    selectedColor: shiftColor.withValues(alpha: 0.15),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? shiftColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Repeat Weekly Switch
              Row(
                children: [
                  Checkbox(
                    value: _repeatWeekly,
                    onChanged: (val) => setState(() => _repeatWeekly = val ?? false),
                    activeColor: AppColors.primary,
                  ),
                  const Text('Lặp lại hàng tuần', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),

              // Days of week selector (if repeat is checked)
              if (_repeatWeekly) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Wrap(
                    spacing: 6,
                    children: dayLabels.map((item) {
                      final val = item['val'] as int;
                      final label = item['label'] as String;
                      final isDaySelected = _selectedDays.contains(val);

                      return FilterChip(
                        selected: isDaySelected,
                        label: Text(label, style: const TextStyle(fontSize: 12)),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(val);
                            } else {
                              if (_selectedDays.length > 1) {
                                _selectedDays.remove(val);
                              }
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: isDaySelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 12),

              // Note Field
              Text('Ghi chú / Nhiệm vụ cụ thể', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Trực sảnh chính, phục vụ phòng VIP...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                  ),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Lưu phân ca', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
