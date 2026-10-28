import 'item_model.dart';

enum OrderStatus {
  preOrder,
  confirmed,
  inProgress,
  completed,
  cancelled;

  static OrderStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'IN_PROGRESS':
        return OrderStatus.inProgress;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PRE_ORDER':
      default:
        return OrderStatus.preOrder;
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.preOrder:
        return 'Đặt trước';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.inProgress:
        return 'Đang phục vụ';
      case OrderStatus.completed:
        return 'Đã thanh toán';
      case OrderStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

enum DishCookingStatus {
  pending,
  cooking,
  ready,
  served,
  cancelled;

  static DishCookingStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'COOKING':
        return DishCookingStatus.cooking;
      case 'READY':
        return DishCookingStatus.ready;
      case 'SERVED':
        return DishCookingStatus.served;
      case 'CANCELLED':
        return DishCookingStatus.cancelled;
      case 'PENDING':
      default:
        return DishCookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case DishCookingStatus.pending:
        return 'Chờ nấu';
      case DishCookingStatus.cooking:
        return 'Đang nấu';
      case DishCookingStatus.ready:
        return 'Ra món';
      case DishCookingStatus.served:
        return 'Đã phục vụ';
      case DishCookingStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

class OrderDetailModel {
  final int id;
  final ItemModel? item;
  final String itemName;
  final int quantity;
  final double totalPrice;
  final DishCookingStatus status;
  final String? note;
  final DateTime orderTime;

  OrderDetailModel({
    required this.id,
    this.item,
    required this.itemName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    this.note,
    DateTime? orderTime,
  }) : orderTime = orderTime ?? DateTime.now();

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'] ?? 0,
      item: json['item'] != null ? ItemModel.fromJson(json['item']) : null,
      itemName: json['item']?['name'] ?? json['itemName'] ?? 'Món ăn',
      quantity: json['quantity'] ?? 1,
      totalPrice: (json['totalPrice'] is num) ? (json['totalPrice'] as num).toDouble() : 0.0,
      status: DishCookingStatus.fromString(json['status']),
      note: json['note'],
      orderTime: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class OrderModel {
  final int id;
  final String code;
  final String guestName;
  final String? tableName;
  final OrderStatus status;
  final double totalPrice;
  final double discountPrice;
  final double finalPrice;
  final List<OrderDetailModel> details;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.code,
    required this.guestName,
    this.tableName,
    required this.status,
    required this.totalPrice,
    this.discountPrice = 0.0,
    required this.finalPrice,
    required this.details,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawDetails = (json['orderDetails'] as List?) ?? [];
    return OrderModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      guestName: json['guestName'] ?? 'Khách vãng lai',
      tableName: json['tableName'],
      status: OrderStatus.fromString(json['status']),
      totalPrice: (json['totalPrice'] is num) ? (json['totalPrice'] as num).toDouble() : 0.0,
      discountPrice: (json['discountPrice'] is num) ? (json['discountPrice'] as num).toDouble() : 0.0,
      finalPrice: (json['finalPrice'] is num) ? (json['finalPrice'] as num).toDouble() : 0.0,
      details: rawDetails.map((e) => OrderDetailModel.fromJson(e)).toList(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}
