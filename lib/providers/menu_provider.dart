import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/models/item_model.dart';
import '../data/repositories/menu_repository.dart';

final menuRepositoryProvider =
    Provider<MenuRepository>((ref) => MenuRepository());

class MenuState {
  final List<CategoryModel> categories;
  final List<ItemModel> allItems;
  final int
      selectedCategoryId; // 0 = 'Tất cả', -99 = 'Set Menu Combo', >0 = Category ID
  final String searchQuery;
  final String
      sortBy; // 'default' | 'price_asc' | 'price_desc' | 'rating_desc' | 'name_asc'
  final String
      priceFilter; // 'all' | 'under_100k' | '100k_300k' | '300k_1m' | 'over_1m'
  final bool onlyAvailable;
  final bool onlyDiscount;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;

  MenuState({
    this.categories = const [],
    this.allItems = const [],
    this.selectedCategoryId = 0,
    this.searchQuery = '',
    this.sortBy = 'default',
    this.priceFilter = 'all',
    this.onlyAvailable = false,
    this.onlyDiscount = false,
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
  });

  int get activeFilterCount {
    int count = 0;
    if (sortBy != 'default') count++;
    if (priceFilter != 'all') count++;
    if (onlyAvailable) count++;
    if (onlyDiscount) count++;
    return count;
  }

  List<ItemModel> get filteredItems {
    var items = List<ItemModel>.from(allItems);

    // 1. Lọc theo trạng thái còn hàng
    if (onlyAvailable) {
      items = items.where((i) => i.isAvailable).toList();
    }

    // 2. Lọc chỉ món có ưu đãi / giảm giá
    if (onlyDiscount) {
      items = items.where((i) => i.hasDiscount).toList();
    }

    // 3. Lọc theo khoảng giá
    switch (priceFilter) {
      case 'under_100k':
        items = items.where((i) => i.displayPrice < 100000).toList();
        break;
      case '100k_300k':
        items = items
            .where((i) => i.displayPrice >= 100000 && i.displayPrice <= 300000)
            .toList();
        break;
      case '300k_1m':
        items = items
            .where((i) => i.displayPrice > 300000 && i.displayPrice <= 1000000)
            .toList();
        break;
      case 'over_1m':
        items = items.where((i) => i.displayPrice > 1000000).toList();
        break;
    }

    // 4. Lọc tìm kiếm phụ nếu danh sách có sẵn
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.description.toLowerCase().contains(q))
          .toList();
    }

    // 5. Sắp xếp danh sách
    switch (sortBy) {
      case 'price_asc':
        items.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
        break;
      case 'price_desc':
        items.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
        break;
      case 'rating_desc':
        items.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'name_asc':
        items.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return items;
  }

  MenuState copyWith({
    List<CategoryModel>? categories,
    List<ItemModel>? allItems,
    int? selectedCategoryId,
    String? searchQuery,
    String? sortBy,
    String? priceFilter,
    bool? onlyAvailable,
    bool? onlyDiscount,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
  }) {
    return MenuState(
      categories: categories ?? this.categories,
      allItems: allItems ?? this.allItems,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      priceFilter: priceFilter ?? this.priceFilter,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      onlyDiscount: onlyDiscount ?? this.onlyDiscount,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repo;
  Timer? _debounceTimer;

  MenuNotifier(this._repo) : super(MenuState()) {
    loadMenu();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Tải danh mục và danh sách món ăn ban đầu
  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = await _repo.getCategories();
      final categoryMap = {for (var c in categories) c.id: c.name};

      final items = await _repo.getItems(
        categoryId: state.selectedCategoryId,
        search: state.searchQuery,
        categoryNames: categoryMap,
      );

      state = state.copyWith(
        categories: categories,
        allItems: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải thực đơn: ${e.toString()}',
      );
    }
  }

  /// Gọi API lấy món theo danh mục, từ khóa tìm kiếm và sắp xếp
  Future<void> fetchItems() async {
    state = state.copyWith(isSearching: true, errorMessage: null);

    try {
      final categoryMap = {for (var c in state.categories) c.id: c.name};

      String? sortField;
      String? dir;
      if (state.sortBy == 'price_asc') {
        sortField = 'price';
        dir = 'asc';
      } else if (state.sortBy == 'price_desc') {
        sortField = 'price';
        dir = 'desc';
      }

      final items = await _repo.getItems(
        categoryId: state.selectedCategoryId,
        search: state.searchQuery,
        sortBy: sortField,
        dir: dir,
        categoryNames: categoryMap,
      );

      state = state.copyWith(
        allItems: items,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Lỗi tải món: ${e.toString()}',
      );
    }
  }

  /// Chọn danh mục (Tất cả, Món khai vị, Bò, Gà, Combo, ...)
  void selectCategory(int categoryId) {
    if (state.selectedCategoryId == categoryId) return;
    state = state.copyWith(selectedCategoryId: categoryId);
    fetchItems();
  }

  /// Nhập từ khóa tìm kiếm (Có Debounce 350ms gọi API)
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      fetchItems();
    });
  }

  /// Xóa từ khóa tìm kiếm
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    fetchItems();
  }

  /// Thay đổi kiểu sắp xếp
  void setSortBy(String sort) {
    state = state.copyWith(sortBy: sort);
  }

  /// Lọc theo khoảng giá
  void setPriceFilter(String filter) {
    state = state.copyWith(priceFilter: filter);
  }

  /// Bật/tắt chỉ hiện món còn hàng
  void toggleOnlyAvailable(bool val) {
    state = state.copyWith(onlyAvailable: val);
  }

  /// Bật/tắt chỉ hiện món có ưu đãi
  void toggleOnlyDiscount(bool val) {
    state = state.copyWith(onlyDiscount: val);
  }

  /// Đặt lại toàn bộ bộ lọc
  void resetFilters() {
    state = state.copyWith(
      sortBy: 'default',
      priceFilter: 'all',
      onlyAvailable: false,
      onlyDiscount: false,
    );
  }

  /// Thêm món ăn mới (Admin)
  Future<ItemModel> createItem({
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    double? priceAfterDiscount,
    required String status,
    required int categoryId,
    String? categoryName,
  }) async {
    final newItem = await _repo.createItem(
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      priceAfterDiscount: priceAfterDiscount,
      status: status,
      categoryId: categoryId,
      categoryName: categoryName,
    );
    state = state.copyWith(allItems: [newItem, ...state.allItems]);
    return newItem;
  }

  /// Cập nhật món ăn (Admin)
  Future<ItemModel> updateItem(
    int id, {
    required String name,
    required String description,
    required String imageUrl,
    required double price,
    double? priceAfterDiscount,
    required String status,
    required int categoryId,
    String? categoryName,
  }) async {
    final updated = await _repo.updateItem(
      id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      priceAfterDiscount: priceAfterDiscount,
      status: status,
      categoryId: categoryId,
      categoryName: categoryName,
    );
    final updatedList = state.allItems
        .map((i) => !i.isCombo && i.id == id ? updated : i)
        .toList();
    state = state.copyWith(allItems: updatedList);
    return updated;
  }

  /// Xóa món ăn (Admin)
  Future<void> deleteItem(int id) async {
    await _repo.deleteItem(id);
    final updatedList =
        state.allItems.where((i) => i.isCombo || i.id != id).toList();
    state = state.copyWith(allItems: updatedList);
  }

  /// Đổi trạng thái phục vụ của món (AVAILABLE <-> UNAVAILABLE)
  Future<bool> toggleItemStatus(ItemModel item) async {
    final newStatus = item.status == 'AVAILABLE' ? 'UNAVAILABLE' : 'AVAILABLE';

    // Optimistic UI update
    final optimisticItem = ItemModel(
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
      isCombo: item.isCombo,
    );
    final previousList = state.allItems;
    final updatedList = state.allItems
        .map((i) =>
            i.id == item.id && i.isCombo == item.isCombo ? optimisticItem : i)
        .toList();
    state = state.copyWith(allItems: updatedList);

    try {
      final success = await _repo.updateItemStatus(item, newStatus);
      if (!success) {
        state = state.copyWith(allItems: previousList);
        return false;
      }
      return true;
    } catch (_) {
      state = state.copyWith(allItems: previousList);
      return false;
    }
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final repo = ref.watch(menuRepositoryProvider);
  return MenuNotifier(repo);
});
