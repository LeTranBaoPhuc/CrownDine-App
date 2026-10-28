import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/mock/mock_data.dart';
import '../../../../data/models/item_model.dart';

class AdminMenuManagementScreen extends StatefulWidget {
  const AdminMenuManagementScreen({super.key});

  @override
  State<AdminMenuManagementScreen> createState() => _AdminMenuManagementScreenState();
}

class _AdminMenuManagementScreenState extends State<AdminMenuManagementScreen> {
  int _selectedCategory = 1; // 1 = Tất cả
  String _searchQuery = '';
  late List<ItemModel> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(MockData.items);
  }

  List<ItemModel> get _filteredItems {
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 1 || item.categoryId == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.categoryName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _toggleItemStatus(ItemModel item) {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      setState(() {
        final newStatus = item.status == 'AVAILABLE' ? 'OUT_OF_STOCK' : 'AVAILABLE';
        _items[idx] = ItemModel(
          id: item.id,
          categoryId: item.categoryId,
          name: item.name,
          description: item.description,
          imageUrl: item.imageUrl,
          price: item.price,
          priceAfterDiscount: item.priceAfterDiscount,
          status: newStatus,
          categoryName: item.categoryName,
          averageRating: item.averageRating,
          feedbackCount: item.feedbackCount,
          tags: item.tags,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.name} đã chuyển sang: ${item.status == 'AVAILABLE' ? "Tạm ngưng phục vụ" : "Sẵn sàng phục vụ"}',
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showAddEditDishSheet([ItemModel? existingItem]) {
    final isEditing = existingItem != null;
    final nameController = TextEditingController(text: existingItem?.name ?? '');
    final priceController = TextEditingController(
      text: existingItem != null ? existingItem.price.toStringAsFixed(0) : '',
    );
    final discountPriceController = TextEditingController(
      text: existingItem?.priceAfterDiscount != null ? existingItem!.priceAfterDiscount!.toStringAsFixed(0) : '',
    );
    final descController = TextEditingController(text: existingItem?.description ?? '');
    int categoryId = existingItem?.categoryId ?? 3; // Default Món chính

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
                        labelText: 'Tên món ăn',
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
                              labelText: 'Giá niêm yết (₫)',
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
                    DropdownButtonFormField<int>(
                      value: categoryId,
                      decoration: InputDecoration(
                        labelText: 'Danh mục món',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                      ),
                      items: MockData.categories
                          .where((c) => c.id != 1)
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setSheetState(() => categoryId = val);
                      },
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
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          final price = double.tryParse(priceController.text) ?? 100000;
                          final discountPrice = double.tryParse(discountPriceController.text);
                          final catName = MockData.categories.firstWhere((c) => c.id == categoryId).name;

                          setState(() {
                            if (isEditing) {
                              final idx = _items.indexWhere((i) => i.id == existingItem.id);
                              if (idx != -1) {
                                _items[idx] = ItemModel(
                                  id: existingItem.id,
                                  categoryId: categoryId,
                                  name: nameController.text.trim(),
                                  description: descController.text.trim(),
                                  imageUrl: existingItem.imageUrl,
                                  price: price,
                                  priceAfterDiscount: discountPrice,
                                  status: existingItem.status,
                                  categoryName: catName,
                                  averageRating: existingItem.averageRating,
                                  feedbackCount: existingItem.feedbackCount,
                                  tags: existingItem.tags,
                                );
                              }
                            } else {
                              _items.insert(
                                0,
                                ItemModel(
                                  id: DateTime.now().millisecondsSinceEpoch,
                                  categoryId: categoryId,
                                  name: nameController.text.trim(),
                                  description: descController.text.trim(),
                                  imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
                                  price: price,
                                  priceAfterDiscount: discountPrice,
                                  status: 'AVAILABLE',
                                  categoryName: catName,
                                  averageRating: 5.0,
                                  feedbackCount: 0,
                                  tags: ['Mới'],
                                ),
                              );
                            }
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEditing ? 'Đã cập nhật món ăn' : 'Đã thêm món mới thành công!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isEditing ? 'Lưu Thay Đổi' : 'Tạo Món Ăn',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
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
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: MockData.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = MockData.categories[index];
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
                  'Hiển thị ${_filteredItems.length} món',
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
            child: _filteredItems.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 50, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text('Không tìm thấy món ăn nào phù hợp'),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
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
                                    item.imageUrl,
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
                                      color: Colors.black.withOpacity(0.6),
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
                                          color: AppColors.primary.withOpacity(0.1),
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
                                InkWell(
                                  onTap: () => _showAddEditDishSheet(item),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                                        SizedBox(width: 4),
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
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
