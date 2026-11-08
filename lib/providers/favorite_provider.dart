import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/favorite_model.dart';
import '../data/repositories/favorite_repository.dart';
import 'auth_provider.dart';

class FavoriteState {
  final bool isLoading;
  final List<FavoriteModel> favorites;
  final Set<int> favoriteItemIds;
  final Set<int> favoriteComboIds;
  final String? errorMessage;

  const FavoriteState({
    this.isLoading = false,
    this.favorites = const [],
    this.favoriteItemIds = const {},
    this.favoriteComboIds = const {},
    this.errorMessage,
  });

  int get totalCount => favorites.length;

  FavoriteState copyWith({
    bool? isLoading,
    List<FavoriteModel>? favorites,
    Set<int>? favoriteItemIds,
    Set<int>? favoriteComboIds,
    String? errorMessage,
  }) {
    return FavoriteState(
      isLoading: isLoading ?? this.isLoading,
      favorites: favorites ?? this.favorites,
      favoriteItemIds: favoriteItemIds ?? this.favoriteItemIds,
      favoriteComboIds: favoriteComboIds ?? this.favoriteComboIds,
      errorMessage: errorMessage,
    );
  }
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  final FavoriteRepository _repo;
  final Ref _ref;

  FavoriteNotifier(this._repo, this._ref) : super(const FavoriteState()) {
    // Automatically load favorites when user is authenticated
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      loadFavorites();
    }

    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        loadFavorites();
      } else if (!next.isAuthenticated && (previous?.isAuthenticated ?? false)) {
        state = const FavoriteState();
      }
    });
  }

  bool isItemFavorite(int itemId) => state.favoriteItemIds.contains(itemId);
  bool isComboFavorite(int comboId) => state.favoriteComboIds.contains(comboId);

  Future<void> loadFavorites() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = const FavoriteState();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getMyFavorites();
      final itemIds = <int>{};
      final comboIds = <int>{};
      for (final f in list) {
        if (f.itemId != null) itemIds.add(f.itemId!);
        if (f.comboId != null) comboIds.add(f.comboId!);
      }
      state = state.copyWith(
        isLoading: false,
        favorites: list,
        favoriteItemIds: itemIds,
        favoriteComboIds: comboIds,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách yêu thích: $e',
      );
    }
  }

  /// Toggle yêu thích món ăn (với Optimistic UI update)
  Future<bool> toggleItemFavorite({
    required int itemId,
    String? name,
    String? imageUrl,
    double? price,
  }) async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) {
      return false;
    }

    final isCurrentlyFavorite = state.favoriteItemIds.contains(itemId);
    final previousState = state;

    // Optimistic UI update
    if (isCurrentlyFavorite) {
      final updatedIds = Set<int>.from(state.favoriteItemIds)..remove(itemId);
      final updatedList = state.favorites.where((f) => f.itemId != itemId).toList();
      state = state.copyWith(favoriteItemIds: updatedIds, favorites: updatedList);
    } else {
      final updatedIds = Set<int>.from(state.favoriteItemIds)..add(itemId);
      final dummyFavorite = FavoriteModel(
        id: DateTime.now().millisecondsSinceEpoch,
        itemId: itemId,
        itemName: name,
        itemImageUrl: imageUrl,
        itemPrice: price,
        createdAt: DateTime.now(),
      );
      final updatedList = [dummyFavorite, ...state.favorites];
      state = state.copyWith(favoriteItemIds: updatedIds, favorites: updatedList);
    }

    try {
      if (isCurrentlyFavorite) {
        await _repo.removeFavoriteItem(itemId);
      } else {
        await _repo.addFavoriteItem(itemId);
        // Refresh silently from backend to get server-generated id
        await loadFavorites();
      }
      return true;
    } catch (e) {
      // Rollback on error
      state = previousState.copyWith(errorMessage: 'Lỗi cập nhật yêu thích: $e');
      return false;
    }
  }

  /// Toggle yêu thích combo (với Optimistic UI update)
  Future<bool> toggleComboFavorite({
    required int comboId,
    String? name,
    String? imageUrl,
    double? price,
  }) async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) {
      return false;
    }

    final isCurrentlyFavorite = state.favoriteComboIds.contains(comboId);
    final previousState = state;

    // Optimistic UI update
    if (isCurrentlyFavorite) {
      final updatedIds = Set<int>.from(state.favoriteComboIds)..remove(comboId);
      final updatedList = state.favorites.where((f) => f.comboId != comboId).toList();
      state = state.copyWith(favoriteComboIds: updatedIds, favorites: updatedList);
    } else {
      final updatedIds = Set<int>.from(state.favoriteComboIds)..add(comboId);
      final dummyFavorite = FavoriteModel(
        id: DateTime.now().millisecondsSinceEpoch,
        comboId: comboId,
        comboName: name,
        comboImageUrl: imageUrl,
        comboPrice: price,
        createdAt: DateTime.now(),
      );
      final updatedList = [dummyFavorite, ...state.favorites];
      state = state.copyWith(favoriteComboIds: updatedIds, favorites: updatedList);
    }

    try {
      if (isCurrentlyFavorite) {
        await _repo.removeFavoriteCombo(comboId);
      } else {
        await _repo.addFavoriteCombo(comboId);
        await loadFavorites();
      }
      return true;
    } catch (e) {
      // Rollback on error
      state = previousState.copyWith(errorMessage: 'Lỗi cập nhật yêu thích combo: $e');
      return false;
    }
  }
}

final favoriteProvider = StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  final repo = ref.watch(favoriteRepositoryProvider);
  return FavoriteNotifier(repo, ref);
});

