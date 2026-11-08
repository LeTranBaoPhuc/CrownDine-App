import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../providers/reservation_provider.dart';

class Step1DateTimeView extends ConsumerWidget {
  const Step1DateTimeView({super.key});

  static const List<String> lunchSlots = ['11:00', '11:30', '12:00', '12:30', '13:00', '13:30'];
  static const List<String> dinnerSlots = ['17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00'];

  static bool isSlotPast(DateTime date, String timeStr) {
    if (timeStr.isEmpty) return true;
    final now = DateTime.now();
    final isBeforeToday = DateTime(date.year, date.month, date.day)
        .isBefore(DateTime(now.year, now.month, now.day));
    if (isBeforeToday) return true;

    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    if (!isToday) return false;

    final parts = timeStr.split(':');
    if (parts.length != 2) return false;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
    return slotTime.isBefore(now);
  }

  void _onDateSelected(WidgetRef ref, DateTime pickedDate, String currentTime) {
    final notifier = ref.read(reservationProvider.notifier);
    final allSlots = [...lunchSlots, ...dinnerSlots];

    if (isSlotPast(pickedDate, currentTime)) {
      final nextValid = allSlots.firstWhere(
        (slot) => !isSlotPast(pickedDate, slot),
        orElse: () => '',
      );
      notifier.setDateTime(date: pickedDate, time: nextValid.isNotEmpty ? nextValid : '');
    } else {
      notifier.setDateTime(date: pickedDate);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservationProvider);
    final notifier = ref.read(reservationProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final allLunchPast = lunchSlots.every((t) => isSlotPast(state.selectedDate, t));
    final allDinnerPast = dinnerSlots.every((t) => isSlotPast(state.selectedDate, t));
    final allDayPast = allLunchPast && allDinnerPast;

    final isCurrentTimePast = isSlotPast(state.selectedDate, state.selectedTime);
    if (isCurrentTimePast && state.selectedTime.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final allSlots = [...lunchSlots, ...dinnerSlots];
        final nextValid = allSlots.firstWhere(
          (slot) => !isSlotPast(state.selectedDate, slot),
          orElse: () => '',
        );
        notifier.setDateTime(time: nextValid);
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header
          const Text(
            'Bước 1: Chọn ngày, giờ & số khách',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hệ thống sẽ kiểm tra bàn trống tương ứng theo thời gian bạn đã chọn.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // 1. DATE SELECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('1. Chọn ngày dùng bữa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Lịch chi tiết'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    _onDateSelected(ref, picked, state.selectedTime);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick 3 Days chips
          Row(
            children: List.generate(4, (index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = DateFormatter.toApiDate(date) == DateFormatter.toApiDate(state.selectedDate);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: InkWell(
                    onTap: () => _onDateSelected(ref, date, state.selectedTime),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isDark
                                ? AppColors.darkCard
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormatter.friendly(date),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}/${date.month}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : (isDark ? AppColors.textLight : AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // 2. GUESTS COUNT
          const Text('2. Số lượng khách', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group_outlined, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.guestNumber} người lớn',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Bao gồm người lớn & trẻ em từ 6 tuổi',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                      onPressed: state.guestNumber > 1 ? () => notifier.setGuests(state.guestNumber - 1) : null,
                    ),
                    Text(
                      '${state.guestNumber}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: AppColors.primary),
                      onPressed: state.guestNumber < 30 ? () => notifier.setGuests(state.guestNumber + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 3. TIME SLOT SELECTION
          const Text('3. Chọn khung giờ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (allDayPast) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Các khung giờ trong ngày đã qua. Vui lòng chọn ngày tiếp theo để đặt bàn.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Lunch
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.gold),
              const SizedBox(width: 6),
              const Text('Bữa Trưa (11:00 - 14:00)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              if (allLunchPast) ...[
                const SizedBox(width: 8),
                Text(
                  '(Đã qua)',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lunchSlots.map((time) {
              final isPast = isSlotPast(state.selectedDate, time);
              final isSelected = !isPast && state.selectedTime == time;
              return ChoiceChip(
                label: Text(
                  time,
                  style: TextStyle(
                    color: isPast
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textLight : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                disabledColor: isDark ? const Color(0xFF231E1A) : const Color(0xFFF1F5F9),
                onSelected: isPast ? null : (_) => notifier.setDateTime(time: time),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Dinner
          Row(
            children: [
              const Icon(Icons.nights_stay_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Bữa Tối (17:30 - 22:00)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              if (allDinnerPast) ...[
                const SizedBox(width: 8),
                Text(
                  '(Đã qua)',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dinnerSlots.map((time) {
              final isPast = isSlotPast(state.selectedDate, time);
              final isSelected = !isPast && state.selectedTime == time;
              return ChoiceChip(
                label: Text(
                  time,
                  style: TextStyle(
                    color: isPast
                        ? (isDark ? Colors.white24 : Colors.black26)
                        : isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textLight : AppColors.textPrimary),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    decoration: isPast ? TextDecoration.lineThrough : null,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                disabledColor: isDark ? const Color(0xFF231E1A) : const Color(0xFFF1F5F9),
                onSelected: isPast ? null : (_) => notifier.setDateTime(time: time),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
