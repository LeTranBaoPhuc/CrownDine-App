import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/item_model.dart';
import '../../../../providers/cart_provider.dart';
import '../../../../providers/menu_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../../widgets/food_card.dart';
import 'menu_detail_sheet.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(BuildContext context, ItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuDetailSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuProvider);
    final notifier = ref.read(menuProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final items = menuState.filteredItems;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: const CrownAppBar(title: 'Thực đơn CrownDine'),
      // POPUP BỘ LỌC XUẤT HIỆN NỬA TRÁI MÀN HÌNH (LEFT DRAWER)
      drawer: Drawer(
        width: min(380, screenWidth * 0.85),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        child: _buildLeftFilterDrawer(context, menuState, notifier, isDark),
      ),
      body: Builder(
        builder: (scaffoldContext) => Column(
        children: [
          // 1. Search Box with Integrated Left-Filter Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => notifier.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Tìm món ăn, đồ uống, combo...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                      ),
                      prefixIcon: menuState.isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                            )
                          : const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                      suffixIcon: menuState.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                notifier.clearSearch();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // NÚT MỞ BỘ LỌC NỬA TRÁI MÀN HÌNH
                GestureDetector(
                  onTap: () {
                    Scaffold.of(scaffoldContext).openDrawer();
                  },
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: menuState.activeFilterCount > 0
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: menuState.activeFilterCount > 0
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: menuState.activeFilterCount > 0
                              ? Colors.white
                              : (isDark ? Colors.white70 : AppColors.textPrimary),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Bộ lọc',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: menuState.activeFilterCount > 0
                                ? Colors.white
                                : (isDark ? Colors.white : AppColors.textPrimary),
                          ),
                        ),
                        if (menuState.activeFilterCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Center(
                              child: Text(
                                '${menuState.activeFilterCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Horizontal Category Chips
          Container(
            height: 48,
            color: isDark ? AppColors.darkCard : Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: menuState.categories.length,
              itemBuilder: (context, index) {
                final cat = menuState.categories[index];
                final isSelected = cat.id == menuState.selectedCategoryId;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: FilterChip(
                    label: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textLight : AppColors.textPrimary),
                      ),
                    ),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
                    selectedColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                    onSelected: (_) => notifier.selectCategory(cat.id),
                  ),
                );
              },
            ),
          ),

          // 3. Active Filters Indicator Bar (Hiển thị tóm tắt khi có lọc)
          if (menuState.activeFilterCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark ? const Color(0xFF1B1614) : const Color(0xFFFFF7ED),
              child: Row(
                children: [
                  const Icon(Icons.filter_list_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Đang lọc: ${_getActiveFilterSummary(menuState)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => notifier.resetFilters(),
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Divider(height: 1),

          // 4. Food Grid List
          Expanded(
            child: menuState.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.primary),
                        SizedBox(height: 12),
                        Text('Đang tải thực đơn CrownDine...'),
                      ],
                    ),
                  )
                : items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.restaurant_menu_rounded, size: 48, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Không tìm thấy món ăn phù hợp',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hãy thử mở "Bộ lọc" để đổi mức giá hoặc xóa từ khóa tìm kiếm.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.clearSearch();
                                  notifier.resetFilters();
                                  notifier.selectCategory(0);
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Xem tất cả món ăn'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => notifier.loadMenu(),
                        child: CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Danh sách món ăn (${items.length})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (menuState.searchQuery.isNotEmpty)
                                      Text(
                                        'Kết quả cho "${menuState.searchQuery}"',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.65,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = items[index];
                                    return FoodCard(
                                      item: item,
                                      onTap: () => _openDetail(context, item),
                                      onAddToCart: () {
                                        ref.read(cartProvider.notifier).addItem(item);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Đã thêm "${item.name}" vào giỏ!'),
                                            backgroundColor: AppColors.primary,
                                            duration: const Duration(milliseconds: 900),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  childCount: items.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    ),
  );
}

  String _getActiveFilterSummary(MenuState state) {
    final parts = <String>[];
    switch (state.priceFilter) {
      case 'under_100k':
        parts.add('Dưới 100k');
        break;
      case '100k_300k':
        parts.add('100k - 300k');
        break;
      case '300k_1m':
        parts.add('300k - 1tr');
        break;
      case 'over_1m':
        parts.add('Trên 1tr');
        break;
    }
    switch (state.sortBy) {
      case 'price_asc':
        parts.add('Giá tăng');
        break;
      case 'price_desc':
        parts.add('Giá giảm');
        break;
      case 'rating_desc':
        parts.add('Đánh giá cao');
        break;
      case 'name_asc':
        parts.add('Tên A-Z');
        break;
    }
    if (state.onlyDiscount) parts.add('Ưu đãi');
    if (state.onlyAvailable) parts.add('Còn hàng');
    return parts.join(' • ');
  }

  // WIDGET POPUP BỘ LỌC BÊN TRÁI MÀN HÌNH
  Widget _buildLeftFilterDrawer(
    BuildContext context,
    MenuState state,
    MenuNotifier notifier,
    bool isDark,
  ) {
    return SafeArea(
      child: Column(
        children: [
          // Drawer Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 22, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Bộ Lọc Thực Đơn',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PHẦN 1: LỌC THEO KHOẢNG GIÁ (RẤT NỔI BẬT)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 18, color: AppColors.gold),
                          SizedBox(width: 6),
                          Text(
                            'LỌC THEO GIÁ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (state.priceFilter != 'all')
                        GestureDetector(
                          onTap: () => notifier.setPriceFilter('all'),
                          child: const Text(
                            'Xóa lọc giá',
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPriceFilterOption(
                    title: 'Tất cả mức giá',
                    subTitle: 'Hiển thị mọi phân khúc',
                    isSelected: state.priceFilter == 'all',
                    onTap: () => notifier.setPriceFilter('all'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildPriceFilterOption(
                    title: 'Dưới 100.000 ₫',
                    subTitle: 'Món tráng miệng, nước uống, ăn nhẹ',
                    isSelected: state.priceFilter == 'under_100k',
                    onTap: () => notifier.setPriceFilter('under_100k'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildPriceFilterOption(
                    title: '100.000 ₫ – 300.000 ₫',
                    subTitle: 'Món khai vị, súp, gà, heo truyền thống',
                    isSelected: state.priceFilter == '100k_300k',
                    onTap: () => notifier.setPriceFilter('100k_300k'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildPriceFilterOption(
                    title: '300.000 ₫ – 1.000.000 ₫',
                    subTitle: 'Món bò, hải sản tươi sống, lẩu cao cấp',
                    isSelected: state.priceFilter == '300k_1m',
                    onTap: () => notifier.setPriceFilter('300k_1m'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildPriceFilterOption(
                    title: 'Trên 1.000.000 ₫',
                    subTitle: 'Bò Wagyu A5, Tôm hùm, Combo Hoàng Gia',
                    isSelected: state.priceFilter == 'over_1m',
                    onTap: () => notifier.setPriceFilter('over_1m'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // PHẦN 2: SẮP XẾP THEO GIÁ & ĐÁNH GIÁ
                  const Row(
                    children: [
                      Icon(Icons.swap_vert_rounded, size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'SẮP XẾP THEO',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'Mặc định',
                        isSelected: state.sortBy == 'default',
                        onTap: () => notifier.setSortBy('default'),
                        isDark: isDark,
                      ),
                      _buildChip(
                        label: 'Giá tăng dần',
                        icon: Icons.arrow_upward_rounded,
                        isSelected: state.sortBy == 'price_asc',
                        onTap: () => notifier.setSortBy('price_asc'),
                        isDark: isDark,
                      ),
                      _buildChip(
                        label: 'Giá giảm dần',
                        icon: Icons.arrow_downward_rounded,
                        isSelected: state.sortBy == 'price_desc',
                        onTap: () => notifier.setSortBy('price_desc'),
                        isDark: isDark,
                      ),
                      _buildChip(
                        label: 'Đánh giá cao',
                        icon: Icons.star_rounded,
                        isSelected: state.sortBy == 'rating_desc',
                        onTap: () => notifier.setSortBy('rating_desc'),
                        isDark: isDark,
                      ),
                      _buildChip(
                        label: 'Tên món (A - Z)',
                        isSelected: state.sortBy == 'name_asc',
                        onTap: () => notifier.setSortBy('name_asc'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // PHẦN 3: TÌNH TRẠNG & ƯU ĐÃI
                  const Row(
                    children: [
                      Icon(Icons.discount_outlined, size: 18, color: AppColors.gold),
                      SizedBox(width: 6),
                      Text(
                        'TÙY CHỌN BỔ SUNG',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Đang giảm giá / Ưu đãi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: state.onlyDiscount,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => notifier.toggleOnlyDiscount(val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chỉ hiện món còn hàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: state.onlyAvailable,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => notifier.toggleOnlyAvailable(val),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Footer Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1614) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: () {
                      notifier.resetFilters();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Đặt lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Xem ${state.filteredItems.length} món',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilterOption({
    required String title,
    required String subTitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subTitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.gold),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
