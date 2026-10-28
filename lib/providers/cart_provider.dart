import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/item_model.dart';
import '../data/models/reservation_model.dart';

class CartState {
  final List<CartItemModel> items;

  CartState({this.items = const []});

  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  CartState copyWith({List<CartItemModel>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(ItemModel item, {int quantity = 1, String? note}) {
    final list = List<CartItemModel>.from(state.items);
    final index = list.indexWhere((element) => element.item.id == item.id);

    if (index != -1) {
      list[index].quantity += quantity;
      if (note != null && note.isNotEmpty) {
        list[index].note = note;
      }
    } else {
      list.add(CartItemModel(item: item, quantity: quantity, note: note));
    }
    state = state.copyWith(items: list);
  }

  void updateQuantity(int itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }
    final list = List<CartItemModel>.from(state.items);
    final index = list.indexWhere((element) => element.item.id == itemId);
    if (index != -1) {
      list[index].quantity = newQuantity;
      state = state.copyWith(items: list);
    }
  }

  void removeItem(int itemId) {
    final list = state.items.where((element) => element.item.id != itemId).toList();
    state = state.copyWith(items: list);
  }

  void updateNote(int itemId, String note) {
    final list = List<CartItemModel>.from(state.items);
    final index = list.indexWhere((element) => element.item.id == itemId);
    if (index != -1) {
      list[index].note = note;
      state = state.copyWith(items: list);
    }
  }

  void clear() {
    state = CartState(items: const []);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
