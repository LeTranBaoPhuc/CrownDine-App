import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/category_model.dart';
import '../data/models/item_model.dart';
import '../data/repositories/menu_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) => MenuRepository());

class MenuState {
  final List<CategoryModel> categories;
  final List<ItemModel> allItems;
  final int selectedCategoryId;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  MenuState({
    this.categories = const [],
    this.allItems = const [],
    this.selectedCategoryId = 1,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  List<ItemModel> get filteredItems {
    var items = allItems;
    if (selectedCategoryId > 1) {
      items = items.where((i) => i.categoryId == selectedCategoryId).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      items = items.where((i) => i.name.toLowerCase().contains(q) || i.description.toLowerCase().contains(q)).toList();
    }
    return items;
  }

  MenuState copyWith({
    List<CategoryModel>? categories,
    List<ItemModel>? allItems,
    int? selectedCategoryId,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MenuState(
      categories: categories ?? this.categories,
      allItems: allItems ?? this.allItems,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuRepository _repo;

  MenuNotifier(this._repo) : super(MenuState()) {
    loadMenu();
  }

  Future<void> loadMenu() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final categories = await _repo.getCategories();
      final items = await _repo.getItems();
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

  void selectCategory(int categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  final repo = ref.watch(menuRepositoryProvider);
  return MenuNotifier(repo);
});
