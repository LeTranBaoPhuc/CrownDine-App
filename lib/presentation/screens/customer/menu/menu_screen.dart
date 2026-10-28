import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/item_model.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/menu_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../../widgets/food_card.dart';
import 'menu_detail_sheet.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  void _openDetail(BuildContext context, ItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(menuProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CrownAppBar(title: 'Thực đơn CrownDine'),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: TextField(
              onChanged: (val) => ref.read(menuProvider.notifier).setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn, đồ uống, combo...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: menuState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => ref.read(menuProvider.notifier).setSearchQuery(''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              ),
            ),
          ),

          // Horizontal Category Chips
          Container(
            height: 52,
            color: isDark ? AppColors.darkCard : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: menuState.categories.length,
              itemBuilder: (context, index) {
                final cat = menuState.categories[index];
                final isSelected = cat.id == menuState.selectedCategoryId;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: FilterChip(
                    label: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? AppColors.textLight : AppColors.textPrimary),
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                    selectedColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                    onSelected: (_) => ref.read(menuProvider.notifier).selectCategory(cat.id),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Food Grid List
          Expanded(
            child: menuState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : menuState.filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.restaurant_outlined, size: 60, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'Không tìm thấy món ăn phù hợp',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(menuProvider.notifier).loadMenu(),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.68,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: menuState.filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = menuState.filteredItems[index];
                            return FoodCard(
                              item: item,
                              onTap: () => _openDetail(context, item),
                              onAddToCart: () {
                                ref.read(cartProvider.notifier).addItem(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã thêm ${item.name} vào giỏ!'),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(milliseconds: 900),
                                  ),
                                );
                              },
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
