import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../providers/menu_provider.dart';
import '../../../../providers/reservation_provider.dart';

class Step3FoodPreorderView extends ConsumerWidget {
  const Step3FoodPreorderView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resState = ref.watch(reservationProvider);
    final resNotifier = ref.read(reservationProvider.notifier);
    final menuState = ref.watch(menuProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: isDark ? AppColors.darkCard : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bước 3: Đặt món ăn trước (Tùy chọn)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (resState.preOrderItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${resState.preOrderItems.length} món',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Đặt món trước giúp Bếp chuẩn bị chu đáo và phục vụ ngay khi bạn đến.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Food List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: menuState.allItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = menuState.allItems[index];
              final cartItem = resState.preOrderItems.where((i) => i.item.id == item.id).firstOrNull;
              final quantity = cartItem?.quantity ?? 0;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: quantity > 0 ? AppColors.primary : AppColors.lightBorder,
                    width: quantity > 0 ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: AppColors.lightSurface,
                          child: const Icon(Icons.restaurant, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.categoryName ?? 'Món chính',
                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(item.displayPrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quantity actions
                    if (quantity == 0)
                      ElevatedButton(
                        onPressed: () => resNotifier.addPreOrderItem(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Thêm', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      )
                    else
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 22, color: AppColors.textSecondary),
                            onPressed: () => resNotifier.updatePreOrderItemQuantity(item.id, quantity - 1),
                          ),
                          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          IconButton(
                            icon: const Icon(Icons.add_circle, size: 22, color: AppColors.primary),
                            onPressed: () => resNotifier.updatePreOrderItemQuantity(item.id, quantity + 1),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // Preorder total banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tiền món đặt trước:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                    CurrencyFormatter.format(resState.foodSubtotal),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              Text(
                resState.preOrderItems.isEmpty ? '(Có thể bỏ qua)' : 'Đã chọn ${resState.preOrderItems.length} món',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
