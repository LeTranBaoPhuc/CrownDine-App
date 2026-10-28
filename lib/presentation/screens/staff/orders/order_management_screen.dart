import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/order_model.dart';
import '../../../../providers/order_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../../widgets/status_badge.dart';

class OrderManagementScreen extends ConsumerWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderProvider);
    final notifier = ref.read(orderProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CrownAppBar(title: 'Quản lý Đơn gọi món'),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Tất cả đơn'),
                    selected: orderState.selectedStatus == null,
                    onSelected: (_) => notifier.filterStatus(null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Đang phục vụ'),
                    selected: orderState.selectedStatus == OrderStatus.inProgress,
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    onSelected: (_) => notifier.filterStatus(OrderStatus.inProgress),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Đặt trước'),
                    selected: orderState.selectedStatus == OrderStatus.preOrder,
                    onSelected: (_) => notifier.filterStatus(OrderStatus.preOrder),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Đã hoàn tất'),
                    selected: orderState.selectedStatus == OrderStatus.completed,
                    onSelected: (_) => notifier.filterStatus(OrderStatus.completed),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Orders List
          Expanded(
            child: orderState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : orderState.filteredOrders.isEmpty
                    ? const Center(child: Text('Không có đơn hàng nào'))
                    : RefreshIndicator(
                        onRefresh: () => notifier.loadOrders(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: orderState.filteredOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final order = orderState.filteredOrders[index];

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order.code,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                      ),
                                      StatusBadge(
                                        label: order.status.displayName,
                                        color: order.status == OrderStatus.inProgress ? AppColors.primary : AppColors.success,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    order.guestName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (order.tableName != null)
                                    Text(
                                      'Vị trí: ${order.tableName}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  const Divider(height: 18),

                                  // Dishes details
                                  ...order.details.map((d) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${d.quantity}x ${d.itemName}${d.note != null ? " (${d.note})" : ""}',
                                              style: const TextStyle(fontSize: 13),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: d.status == DishCookingStatus.ready
                                                  ? AppColors.successContainer
                                                  : AppColors.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              d.status.displayName,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: d.status == DishCookingStatus.ready ? AppColors.success : AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  const Divider(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Tổng tiền:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                          Text(
                                            CurrencyFormatter.format(order.finalPrice),
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                        ],
                                      ),
                                      if (order.status == OrderStatus.inProgress)
                                        ElevatedButton(
                                          onPressed: () => notifier.completeOrder(order.id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Thanh toán', style: TextStyle(color: Colors.white, fontSize: 13)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
