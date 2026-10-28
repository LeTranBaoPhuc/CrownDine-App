import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/order_model.dart';
import '../data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) => OrderRepository());

class OrderState {
  final List<OrderModel> orders;
  final OrderStatus? selectedStatus;
  final bool isLoading;
  final String? errorMessage;

  OrderState({
    this.orders = const [],
    this.selectedStatus,
    this.isLoading = false,
    this.errorMessage,
  });

  List<OrderModel> get filteredOrders {
    if (selectedStatus != null) {
      return orders.where((o) => o.status == selectedStatus).toList();
    }
    return orders;
  }

  // All active kitchen items for KDS screen
  List<Map<String, dynamic>> get kitchenTicketItems {
    final List<Map<String, dynamic>> list = [];
    for (final order in orders) {
      for (final detail in order.details) {
        if (detail.status == DishCookingStatus.pending || detail.status == DishCookingStatus.cooking) {
          list.add({
            'orderId': order.id,
            'orderCode': order.code,
            'tableName': order.tableName ?? 'Bàn vãng lai',
            'detail': detail,
          });
        }
      }
    }
    return list;
  }

  OrderState copyWith({
    List<OrderModel>? orders,
    OrderStatus? Function()? selectedStatus,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      selectedStatus: selectedStatus != null ? selectedStatus() : this.selectedStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderRepository _repo;

  OrderNotifier(this._repo) : super(OrderState()) {
    loadOrders();
  }

  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await _repo.getAllOrders();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải đơn hàng: ${e.toString()}',
      );
    }
  }

  void filterStatus(OrderStatus? status) {
    state = state.copyWith(selectedStatus: () => status);
  }

  Future<void> advanceCookingStatus(int orderId, int detailId, DishCookingStatus nextStatus) async {
    await _repo.updateDishCookingStatus(orderId, detailId, nextStatus);
    await loadOrders();
  }

  Future<void> addDishToTable(String tableName, dynamic item, int quantity, String? note) async {
    await _repo.addDishToOrder(tableName, item, quantity, note);
    await loadOrders();
  }

  Future<void> completeOrder(int orderId) async {
    await _repo.updateOrderStatus(orderId, OrderStatus.completed);
    await loadOrders();
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrderNotifier(repo);
});
