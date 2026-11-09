import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/order_model.dart';
import '../models/item_model.dart';

class TableOrderLine {
  final ItemModel item;
  final int quantity;
  final String? note;
  const TableOrderLine({required this.item, required this.quantity, this.note});
  Map<String, dynamic> toJson() => {
        item.isCombo ? 'comboId' : 'itemId': item.id,
        'quantity': quantity,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };
}

class OrderRepository {
  final Dio _dio;
  OrderRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  dynamic _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['status'] is! num || body['status'] >= 400) {
      throw const FormatException('Phản hồi đơn hàng không hợp lệ.');
    }
    return body['data'];
  }

  Future<List<OrderModel>> getAllOrders() async {
    // KDS must not fall back to unrelated historical orders or mock tickets.
    final data = _data(await _dio.get(ApiEndpoints.ordersKitchen));
    if (data is! List) throw const FormatException('Thiếu danh sách đơn bếp.');
    return data
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OrderModel?> getActiveTableOrder(int tableId) async {
    final data = _data(await _dio.get('orders/tables/$tableId/active'));
    if (data == null) return null;
    if (data is! Map<String, dynamic> ||
        data['tableId'] != tableId ||
        data['id'] is! int ||
        data['id'] <= 0 ||
        !['CONFIRMED', 'IN_PROGRESS', 'SERVED'].contains(data['status'])) {
      throw const FormatException('Đơn phục vụ không khớp bàn.');
    }
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> addItemsAtTable(int tableId, List<TableOrderLine> lines,
      {int? expectedOrderId}) async {
    if (lines.isEmpty ||
        lines.any((line) => line.quantity < 1 || !line.item.isAvailable)) {
      throw StateError('Chọn món còn phục vụ và số lượng hợp lệ.');
    }
    final data = _data(await _dio.post('orders/tables/$tableId/details', data: {
      'expectedOrderId': expectedOrderId,
      'items': lines.map((line) => line.toJson()).toList(),
    }));
    if (data is! Map<String, dynamic> ||
        data['tableId'] != tableId ||
        data['id'] is! int ||
        data['id'] <= 0 ||
        (expectedOrderId != null && data['id'] != expectedOrderId) ||
        !['CONFIRMED', 'IN_PROGRESS', 'SERVED'].contains(data['status'])) {
      throw const FormatException('Máy chủ chưa xác nhận đơn gọi món của bàn.');
    }
    return OrderModel.fromJson(data);
  }

  Future<Map<String, dynamic>> getCheckout(int orderId) async {
    final data = _data(await _dio.get('orders/$orderId/checkout'));
    if (data is! Map<String, dynamic> ||
        data['orderId'] != orderId ||
        [
          'totalAmount',
          'voucherDiscount',
          'orderDepositPaidAmount',
          'finalAmount'
        ].any((key) => data[key] is! num)) {
      throw const FormatException('Không đọc được hóa đơn từ máy chủ.');
    }
    return data;
  }

  Future<Map<String, dynamic>?> latestPayment(int orderId) async {
    final data = _data(await _dio.get('payments/orders/$orderId/latest'));
    if (data == null) return null;
    if (data is! Map<String, dynamic> ||
        data['target'] != 'ORDER' ||
        data['code'] is! int) {
      throw const FormatException('Giao dịch không hợp lệ.');
    }
    return data;
  }

  Future<void> createSettlement(String orderCode, String method) async {
    _data(await _dio.post('payments/create',
        data: {'orderCode': orderCode, 'method': method}));
  }

  Future<void> updateDishCookingStatus(
      int orderId, int detailId, DishCookingStatus status) async {
    _data(await _dio.patch(ApiEndpoints.orderDetailStatus(detailId),
        queryParameters: {'status': status.name.toUpperCase()}));
  }

  Future<void> updateOrderStatus(int orderId, OrderStatus status) async {
    final code = status == OrderStatus.inProgress
        ? 'IN_PROGRESS'
        : status == OrderStatus.preOrder
            ? 'PRE_ORDER'
            : status.name.toUpperCase();
    _data(await _dio
        .patch('orders/$orderId/status', queryParameters: {'status': code}));
  }
}
