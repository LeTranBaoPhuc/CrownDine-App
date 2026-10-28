import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<OrderModel>> getAllOrders() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.orders);
      if (response.statusCode == 200 && response.data != null) {
        final pageData = response.data['data'] ?? response.data;
        final list = (pageData['items'] as List?) ?? (pageData['content'] as List?) ?? (pageData as List?);
        if (list != null && list.isNotEmpty) {
          return list.map((e) => OrderModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.sampleOrders;
  }

  Future<void> updateDishCookingStatus(int orderId, int detailId, DishCookingStatus status) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      await _client.dio.patch(
        'order-details/$detailId/upd',
        data: {'status': status.name.toUpperCase()},
      );
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Update in local mock
    for (final o in MockData.sampleOrders) {
      if (o.id == orderId) {
        final idx = o.details.indexWhere((d) => d.id == detailId);
        if (idx != -1) {
          final old = o.details[idx];
          o.details[idx] = OrderDetailModel(
            id: old.id,
            item: old.item,
            itemName: old.itemName,
            quantity: old.quantity,
            totalPrice: old.totalPrice,
            status: status,
            note: old.note,
            orderTime: old.orderTime,
          );
        }
      }
    }
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      await _client.dio.patch('${ApiEndpoints.orders}/$orderId/status?status=${status.name.toUpperCase()}');
    } catch (e) {
      if (!useMock) rethrow;
    }

    final idx = MockData.sampleOrders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final old = MockData.sampleOrders[idx];
      MockData.sampleOrders[idx] = OrderModel(
        id: old.id,
        code: old.code,
        guestName: old.guestName,
        tableName: old.tableName,
        status: status,
        totalPrice: old.totalPrice,
        discountPrice: old.discountPrice,
        finalPrice: old.finalPrice,
        details: old.details,
        createdAt: old.createdAt,
      );
    }
  }

  Future<void> addDishToOrder(String tableName, dynamic item, int quantity, String? note) async {
    final order = MockData.sampleOrders.where((o) => o.tableName == tableName && o.status == OrderStatus.inProgress).firstOrNull;
    if (order != null) {
      final newDetail = OrderDetailModel(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        item: item,
        itemName: item.name,
        quantity: quantity,
        totalPrice: (item.displayPrice as num).toDouble() * quantity,
        status: DishCookingStatus.pending,
        note: note,
      );
      order.details.add(newDetail);
    }
  }
}
