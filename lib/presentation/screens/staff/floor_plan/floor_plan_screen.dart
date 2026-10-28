import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../data/models/table_model.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/table_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../../widgets/table_widget.dart';

class FloorPlanScreen extends ConsumerWidget {
  const FloorPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tableState = ref.watch(tableProvider);
    final notifier = ref.read(tableProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CrownAppBar(title: 'Sơ đồ bàn & Phục vụ'),
      body: Column(
        children: [
          // Floor and Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: Column(
              children: [
                // Floor switcher
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
                          onTap: () => notifier.selectFloor(f.id),
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
                                f.id == 1 ? 'Tầng 1 (Đại sảnh)' : 'Tầng 2 (Phòng VIP)',
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
                const SizedBox(height: 10),

                // Table Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Tất cả bàn'),
                        selected: tableState.statusFilter == null,
                        onSelected: (_) => notifier.filterByStatus(null),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Bàn trống'),
                        selected: tableState.statusFilter == TableStatus.available,
                        selectedColor: AppColors.tableAvailable.withOpacity(0.2),
                        onSelected: (_) => notifier.filterByStatus(TableStatus.available),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Đang phục vụ'),
                        selected: tableState.statusFilter == TableStatus.occupied,
                        selectedColor: AppColors.tableOccupied.withOpacity(0.2),
                        onSelected: (_) => notifier.filterByStatus(TableStatus.occupied),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Đã đặt trước'),
                        selected: tableState.statusFilter == TableStatus.reserved,
                        selectedColor: AppColors.tableReserved.withOpacity(0.2),
                        onSelected: (_) => notifier.filterByStatus(TableStatus.reserved),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Table Grid
          Expanded(
            child: tableState.floorTables.isEmpty
                ? const Center(child: Text('Không có bàn phù hợp bộ lọc'))
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
                      return TableWidget(
                        table: table,
                        onTap: () => _showTableActionSheet(context, ref, table),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTableActionSheet(BuildContext context, WidgetRef ref, TableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Material(
        color: Theme.of(ctx).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(table.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    table.status.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Sức chứa: ${table.capacity} khách • Tiền cọc: ${CurrencyFormatter.format(table.deposit)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const Divider(height: 24),

            // Actions based on table status
            if (table.status == TableStatus.available) ...[
              ListTile(
                leading: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                title: const Text('Mở bàn cho khách vãng lai (Walk-in)'),
                subtitle: const Text('Bắt đầu gọi món cho khách'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, TableStatus.occupied);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã mở ${table.name} cho khách vào dùng bữa!'), backgroundColor: AppColors.success),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border, color: AppColors.gold),
                title: const Text('Đánh dấu đã giữ chỗ'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, TableStatus.reserved);
                  Navigator.pop(context);
                },
              ),
            ] else if (table.status == TableStatus.occupied) ...[
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                title: const Text('Gọi thêm món cho bàn'),
                subtitle: const Text('Thêm đồ ăn, đồ uống chuyển vào bếp KDS'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddDishSheet(context, ref, table);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                title: const Text('Xem hóa đơn & Thanh toán thu ngân'),
                subtitle: const Text('In hóa đơn tạm tính và thanh toán'),
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentDialog(context, ref, table);
                },
              ),
              ListTile(
                leading: const Icon(Icons.clean_hands_outlined, color: AppColors.success),
                title: const Text('Dọn bàn & Trả bàn trống'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, TableStatus.available);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã dọn dẹp và trả ${table.name} về bàn trống!'), backgroundColor: AppColors.success),
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.people, color: AppColors.primary),
                title: const Text('Khách đặt bàn đã đến nhận bàn'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, TableStatus.occupied);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Khách đã vào ${table.name}!'), backgroundColor: AppColors.success),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: AppColors.error),
                title: const Text('Hủy giữ chỗ bàn'),
                onTap: () {
                  ref.read(tableProvider.notifier).updateTableStatus(table.id, TableStatus.available);
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }

  void _showPaymentDialog(BuildContext context, WidgetRef ref, TableModel table) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thanh toán ${table.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng tiền dịch vụ: 1.630.000 ₫', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Đã trừ cọc bàn: -100.000 ₫', style: TextStyle(color: AppColors.success)),
            const Divider(),
            const Text('Cần thanh toán: 1.530.000 ₫', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            const SizedBox(height: 12),
            const Text('Phương thức: Tiền mặt hoặc quét mã QR PayOS'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
          ElevatedButton(
            onPressed: () {
              ref.read(tableProvider.notifier).updateTableStatus(table.id, TableStatus.available);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanh toán thành công! Bàn đã hoàn tất.'), backgroundColor: AppColors.success),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xác nhận thanh toán', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDishSheet(BuildContext context, WidgetRef ref, TableModel table) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomCtx) => Material(
        color: Theme.of(bottomCtx).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gọi món cho ${table.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Text('Chọn món ăn hoặc đồ uống cần thêm. Món sẽ chuyển trực tiếp vào Bếp KDS.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Divider(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: MockData.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = MockData.items[idx];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: AppColors.lightSurface, child: const Icon(Icons.restaurant, color: AppColors.primary)),
                      ),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(CurrencyFormatter.format(item.displayPrice), style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ref.read(orderProvider.notifier).addDishToTable(table.name, item, 1, 'Gọi thêm tại bàn');
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm 1x ${item.name} cho ${table.name}! Bếp đã nhận vé.'), backgroundColor: AppColors.success),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Thêm món', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}
