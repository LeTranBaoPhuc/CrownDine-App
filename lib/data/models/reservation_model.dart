import 'item_model.dart';

enum ReservationStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  static ReservationStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return ReservationStatus.confirmed;
      case 'COMPLETED':
        return ReservationStatus.completed;
      case 'CANCELLED':
        return ReservationStatus.cancelled;
      case 'PENDING':
      default:
        return ReservationStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'Chờ thanh toán cọc';
      case ReservationStatus.confirmed:
        return 'Đã xác nhận';
      case ReservationStatus.completed:
        return 'Đã hoàn tất';
      case ReservationStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

class CartItemModel {
  final ItemModel item;
  int quantity;
  String? note;

  CartItemModel({
    required this.item,
    this.quantity = 1,
    this.note,
  });

  double get totalPrice => item.displayPrice * quantity;
}

class ReservationModel {
  final int id;
  final String code;
  final String date;
  final String startTime;
  final int guestNumber;
  final int? tableId;
  final String? tableName;
  final double tableDeposit;
  final double itemsTotal;
  final double finalAmount;
  final ReservationStatus status;
  final String? note;
  final String? guestName;
  final String? guestPhone;
  final List<CartItemModel> items;
  final DateTime? createdAt;

  ReservationModel({
    required this.id,
    required this.code,
    required this.date,
    required this.startTime,
    required this.guestNumber,
    this.tableId,
    this.tableName,
    this.tableDeposit = 100000.0,
    this.itemsTotal = 0.0,
    this.finalAmount = 100000.0,
    this.status = ReservationStatus.pending,
    this.note,
    this.guestName,
    this.guestPhone,
    this.items = const [],
    this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['reservationId'] ?? json['id'] ?? 0,
      code: json['reservationCode'] ?? json['code'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      guestNumber: json['guestNumber'] ?? 2,
      tableId: json['table']?['id'] ?? json['tableId'],
      tableName: json['table']?['name'] ?? json['tableName'],
      tableDeposit: (json['tableDeposit'] is num)
          ? (json['tableDeposit'] as num).toDouble()
          : (json['depositAmount'] is num)
              ? (json['depositAmount'] as num).toDouble()
              : 100000.0,
      itemsTotal: (json['itemsTotal'] is num) ? (json['itemsTotal'] as num).toDouble() : 0.0,
      finalAmount: (json['finalAmount'] is num) ? (json['finalAmount'] as num).toDouble() : 100000.0,
      status: ReservationStatus.fromString(json['reservationStatus'] ?? json['status']),
      note: json['note'],
      guestName: json['guestName'],
      guestPhone: json['guestPhone'],
    );
  }
}
