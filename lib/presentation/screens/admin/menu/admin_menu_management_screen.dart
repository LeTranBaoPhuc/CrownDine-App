import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../data/models/item_model.dart';
import '../../../../providers/menu_provider.dart';

class AdminMenuManagementScreen extends ConsumerStatefulWidget {
  const AdminMenuManagementScreen({super.key});

  @override
  ConsumerState<AdminMenuManagementScreen> createState() => _AdminMenuManagementScreenState();
}

class _AdminMenuManagementScreenState extends ConsumerState<AdminMenuManagementScreen> {
  int _selectedCategory = 0; // 0 = Tất cả
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(menuProvider.notifier).loadMenu();
    });
  }

  void _toggleItemStatus(ItemModel item) async {
    final success = await ref.read(menuProvider.notifier).toggleItemStatus(item);
    if (!mounted) return;
    if (success) {
      final willBeAvailable = item.status != 'AVAILABLE';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.name} đã chuyển sang: ${willBeAvailable ? "Sẵn sàng phục vụ" : "Tạm ngưng phục vụ"}',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật trạng thái món ăn. Vui lòng thử lại!'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _confirmDeleteItem(ItemModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Xác nhận xóa món'),
          ],
        ),
        content: Text('Bạn có chắc chắn muốn ngưng và xóa món "${item.name}" khỏi thực đơn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(menuProvider.notifier).deleteItem(item.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa món "${item.name}" thành công'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi khi xóa món: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Xóa món', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDishSheet([ItemModel? existingItem]) {
    final isEditing = existingItem != null;
    final menuState = ref.read(menuProvider);

    // List of real database categories (exclude 'Tất cả' and 'Combo')
    final realCategories = menuState.categories.where((c) => c.id > 0).toList();

    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final priceController = TextEditingController(
      text: existingItem != null ? existingItem.price.toStringAsFixed(0) : '',
    );
    final discountPriceController = TextEditingController(
      text: existingItem?.priceAfterDiscount != null ? existingItem!.priceAfterDiscount!.toStringAsFixed(0) : '',
    );
    final imageUrlController = TextEditingController(
      text: existingItem?.imageUrl ?? 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
    );
    final descController = TextEditingController(text: existingItem?.description ?? '');

    int selectedCatId = existingItem?.categoryId ?? (realCategories.isNotEmpty ? realCategories.first.id : 1);
    String selectedStatus = existingItem?.status ?? 'AVAILABLE';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEditing ? 'Chỉnh Sửa Món Ăn' : 'Thêm Món Mới',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Tên món ăn *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.restaurant, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá niêm yết (₫) *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.attach_money, color: AppColors.gold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: discountPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Giá khuyến mãi (₫)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.local_offer_outlined, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (realCategories.isNotEmpty)
                        DropdownButtonFormField<int>(
                          initialValue: selectedCatId,
                          decoration: InputDecoration(
                            labelText: 'Danh mục món *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                          ),
                          items: realCategories
                              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedCatId = val);
                          },
                        ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Trạng thái phục vụ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.toggle_on_outlined, color: AppColors.primary),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'AVAILABLE', child: Text('Sẵn sàng phục vụ')),
                          DropdownMenuItem(value: 'UNAVAILABLE', child: Text('Tạm ngưng phục vụ')),
                        ],
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedStatus = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'Đường dẫn ảnh món ăn (URL)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.image_outlined, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Mô tả nguyên liệu / hương vị',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng nhập tên món ăn')),
                                    );
                                    return;
                                  }
                                  final price = double.tryParse(priceController.text);
                                  if (price == null || price <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Vui lòng nhập giá niêm yết hợp lệ')),
                                    );
                                    return;
                                  }
                                  final discountPrice = double.tryParse(discountPriceController.text);
                                  final catName = realCategories.firstWhere(
                                    (c) => c.id == selectedCatId,
                                    orElse: () => realCategories.first,
                                  ).name;

                                  setSheetState(() => isSubmitting = true);

                                  try {
                                    if (isEditing) {
                                      await ref.read(menuProvider.notifier).updateItem(
                                            existingItem.id,
                                            name: name,
                                            description: descController.text.trim(),
                                            imageUrl: imageUrlController.text.trim(),
                                            price: price,
                                            priceAfterDiscount: discountPrice,
                                            status: selectedStatus,
                                            categoryId: selectedCatId,
                                            categoryName: catName,
                                          );
                                    } else {
                                      await ref.read(menuProvider.notifier).createItem(
                                            name: name,
                                            description: descController.text.trim(),
                                            imageUrl: imageUrlController.text.trim(),
                                            price: price,
                                            priceAfterDiscount: discountPrice,
                                            status: selectedStatus,
                                            categoryId: selectedCatId,
                                            categoryName: catName,
                                          );
                                    }

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(isEditing ? 'Đã cập nhật món ăn' : 'Đã thêm món mới thành công!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Lỗi: $e'),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  isEditing ? 'Lưu Thay Đổi' : 'Tạo Món Ăn',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final menuState = ref.watch(menuProvider);

    final filteredItems = menuState.allItems.where((item) {
      final matchesCategory = _selectedCategory == 0 ||
          (_selectedCategory == -99 ? item.isCombo : item.categoryId == _selectedCategory);
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.categoryName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: isDark ? AppColors.darkCard : Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm món ăn, danh mục...',
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.primary),
                          filled: true,
                          fillColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDishSheet(),
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: const Text('Thêm món', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category chips
                if (menuState.categories.isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: menuState.categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = menuState.categories[index];
                        final isSelected = _selectedCategory == cat.id;
                        return ChoiceChip(
                          label: Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                          onSelected: (_) => setState(() => _selectedCategory = cat.id),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Items count & status hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị ${filteredItems.length} món',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const Row(
                  children: [
                    Icon(Icons.toggle_on, color: AppColors.success, size: 18),
                    SizedBox(width: 4),
                    Text('Bật/tắt trạng thái phục vụ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          // Dishes List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(menuProvider.notifier).loadMenu(),
              child: menuState.isLoading && menuState.allItems.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 14),
                          Text('Đang tải thực đơn từ máy chủ...', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : filteredItems.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 80),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 50, color: AppColors.textMuted),
                                  SizedBox(height: 8),
                                  Text('Không tìm thấy món ăn nào phù hợp'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          itemCount: filteredItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isAvailable = item.status == 'AVAILABLE';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Dish Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          ImageUtils.getSafeImageUrl(item.imageUrl),
                                          width: 76,
                                          height: 76,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 76,
                                            height: 76,
                                            color: AppColors.lightSurface,
                                            child: const Icon(Icons.fastfood, color: AppColors.primary),
                                          ),
                                        ),
                                        if (!isAvailable)
                                          Container(
                                            width: 76,
                                            height: 76,
                                            color: Colors.black.withValues(alpha: 0.6),
                                            child: const Center(
                                              child: Text(
                                                'Hết món',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Dish Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                item.categoryName ?? 'Món chính',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              CurrencyFormatter.format(item.displayPrice),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (item.hasDiscount) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                CurrencyFormatter.format(item.price),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action buttons
                                  Column(
                                    children: [
                                      Switch(
                                        value: isAvailable,
                                        activeThumbColor: AppColors.success,
                                        onChanged: (_) => _toggleItemStatus(item),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _showAddEditDishSheet(item),
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 15, color: AppColors.primary),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    'Sửa',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => _confirmDeleteItem(item),
                                            borderRadius: BorderRadius.circular(10),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.delete_outline, size: 15, color: AppColors.error),
                                                  SizedBox(width: 2),
                                                  Text(
                                                    'Xóa',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.error,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
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
