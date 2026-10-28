import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/table_model.dart';
import '../../../../providers/reservation_provider.dart';
import '../../../../providers/table_provider.dart';
import '../../../widgets/table_widget.dart';

class Step2TableMapView extends ConsumerWidget {
  const Step2TableMapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableState = ref.watch(tableProvider);
    final tableNotifier = ref.read(tableProvider.notifier);
    final resState = ref.watch(reservationProvider);
    final resNotifier = ref.read(reservationProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header & Floor Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bước 2: Chọn bàn trên sơ đồ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Phù hợp cho ${resState.guestNumber} khách vào lúc ${resState.selectedTime}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // Floor Segmented Buttons
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: tableState.floors.map((f) {
                    final isSelected = tableState.selectedFloorId == f.id;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => tableNotifier.selectFloor(f.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              f.id == 1 ? 'Tầng 1 (Đại sảnh)' : 'Tầng 2 (VIP & Ban công)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : AppColors.textPrimary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Status Legend
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LegendItem(color: AppColors.tableAvailable, label: 'Còn trống'),
                  _LegendItem(color: AppColors.tableReserved, label: 'Đã đặt'),
                  _LegendItem(color: AppColors.tableOccupied, label: 'Đang dùng'),
                  _LegendItem(color: AppColors.primary, label: 'Đang chọn'),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Tables Grid
        Expanded(
          child: tableState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: tableState.floorTables.length,
                  itemBuilder: (context, index) {
                    final table = tableState.floorTables[index];
                    final isSelected = resState.selectedTable?.id == table.id;

                    return TableWidget(
                      table: table,
                      isSelected: isSelected,
                      onTap: () {
                        if (table.status == TableStatus.available) {
                          resNotifier.selectTable(table);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${table.name} hiện ${table.status.displayName.toLowerCase()}! Vui lòng chọn bàn khác.'),
                              backgroundColor: AppColors.warning,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),

        // Selected Table Notification Banner
        if (resState.selectedTable != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.primary.withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Đã chọn: ${resState.selectedTable!.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Cọc bàn: ${CurrencyFormatter.format(resState.selectedTable!.deposit)} • Sức chứa ${resState.selectedTable!.capacity} người',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
