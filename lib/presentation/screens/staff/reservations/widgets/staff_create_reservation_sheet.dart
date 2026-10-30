import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../data/mock/mock_data.dart';
import '../../../../../providers/staff_reservation_provider.dart';
import '../../../../../providers/table_provider.dart';

class StaffCreateReservationSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialStartTime;
  final int? initialTableId;

  const StaffCreateReservationSheet({
    super.key,
    this.initialDate,
    this.initialStartTime,
    this.initialTableId,
  });

  static Future<bool?> show(
    BuildContext context, {
    DateTime? initialDate,
    String? initialStartTime,
    int? initialTableId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffCreateReservationSheet(
        initialDate: initialDate,
        initialStartTime: initialStartTime,
        initialTableId: initialTableId,
      ),
    );
  }

  @override
  ConsumerState<StaffCreateReservationSheet> createState() => _StaffCreateReservationSheetState();
}

class _StaffCreateReservationSheetState extends ConsumerState<StaffCreateReservationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _selectedDate;
  late String _selectedTime;
  int _guestNumber = 2;
  int? _selectedTableId;
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00', '21:30',
  ];

  @override
  void initState() {
    super.initState();
    final staffState = ref.read(staffReservationProvider);
    _selectedDate = widget.initialDate ?? staffState.selectedDate;
    _selectedTime = widget.initialStartTime ?? '19:00';
    _selectedTableId = widget.initialTableId;

    if (!_timeSlots.contains(_selectedTime)) {
      _timeSlots.add(_selectedTime);
      _timeSlots.sort();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tableState = ref.watch(tableProvider);
    final allTables = tableState.allTables.isNotEmpty ? tableState.allTables : MockData.tables;

    // Ensure initial table exists
    if (_selectedTableId == null && allTables.isNotEmpty) {
      _selectedTableId = allTables.first.id;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tạo Đặt Bàn Mới (Tại Quầy)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dành cho khách vãng lai hoặc đặt trước qua điện thoại',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Tên khách hàng & SĐT
                    const Text(
                      'Thông tin khách hàng (*)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên khách hàng *',
                        hintText: 'Nhập họ tên khách...',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập tên khách hàng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại *',
                        hintText: 'Nhập số điện thoại liên hệ...',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập số điện thoại';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 2. Ngày giờ & Số lượng khách
                    const Text(
                      'Thời gian & Số lượng khách (*)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Chọn ngày
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 60)),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Ngày đến',
                                prefixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(
                                DateFormatter.format(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Chọn giờ đến
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedTime,
                            decoration: const InputDecoration(
                              labelText: 'Giờ đến',
                              prefixIcon: Icon(Icons.schedule, size: 18),
                            ),
                            items: _timeSlots.map((time) {
                              return DropdownMenuItem(
                                value: time,
                                child: Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTime = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Counter số lượng khách
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số lượng khách:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                onPressed: _guestNumber > 1 ? () => setState(() => _guestNumber--) : null,
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 32),
                                alignment: Alignment.center,
                                child: Text(
                                  '$_guestNumber',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                onPressed: _guestNumber < 30 ? () => setState(() => _guestNumber++) : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. Chọn Bàn phục vụ
                    const Text(
                      'Bàn phục vụ (*)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: _selectedTableId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Chọn bàn',
                        prefixIcon: Icon(Icons.table_restaurant, size: 20),
                      ),
                      items: allTables.map((t) {
                        return DropdownMenuItem<int>(
                          value: t.id,
                          child: Text(
                            '${t.name} (Tầng ${t.floorId} • ${t.capacity} chỗ • ${t.areaName})',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTableId = val);
                      },
                    ),
                    const SizedBox(height: 20),

                    // 4. Ghi chú của khách
                    const Text(
                      'Ghi chú phục vụ',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Yêu cầu đặc biệt: vị trí yên tĩnh, ghế trẻ em, trang trí hoa...',
                        prefixIcon: Icon(Icons.notes, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Submit Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'Đang tạo đặt bàn...' : 'Xác Nhận Đặt Bàn',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSubmitting ? null : _submitForm,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn 1 bàn để gán đơn')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final guestName = _nameController.text.trim();
    final guestPhone = _phoneController.text.trim();
    final note = _noteController.text.trim();
    final dateStr = DateFormatter.toApiDate(_selectedDate);

    final success = await ref.read(staffReservationProvider.notifier).createWalkIn(
          guestName: guestName,
          guestPhone: guestPhone,
          date: dateStr,
          startTime: _selectedTime,
          guestNumber: _guestNumber,
          tableId: _selectedTableId!,
          note: note.isNotEmpty ? note : null,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo đặt bàn thành công cho khách "$guestName"!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo đặt bàn thất bại. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
