import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../providers/reservation_provider.dart';

class Step1DateTimeView extends ConsumerWidget {
  const Step1DateTimeView({super.key});

  static const List<String> lunchSlots = ['11:00', '11:30', '12:00', '12:30', '13:00', '13:30'];
  static const List<String> dinnerSlots = ['17:30', '18:00', '18:30', '19:00', '19:30', '20:00', '20:30', '21:00'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reservationProvider);
    final notifier = ref.read(reservationProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                    notifier.setDateTime(date: picked);
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
                    onTap: () => notifier.setDateTime(date: date),
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

          // Lunch
          const Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 16, color: AppColors.gold),
              SizedBox(width: 6),
              Text('Bữa Trưa (11:00 - 14:00)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lunchSlots.map((time) {
              final isSelected = state.selectedTime == time;
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? AppColors.textLight : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: (_) => notifier.setDateTime(time: time),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Dinner
          const Row(
            children: [
              Icon(Icons.nights_stay_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Bữa Tối (17:30 - 22:00)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: dinnerSlots.map((time) {
              final isSelected = state.selectedTime == time;
              return ChoiceChip(
                label: Text(time),
                selected: isSelected,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? AppColors.textLight : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                onSelected: (_) => notifier.setDateTime(time: time),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
