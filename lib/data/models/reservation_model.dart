import 'item_model.dart';

enum ReservationStatus {
  pending,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  noShow;

  static ReservationStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return ReservationStatus.confirmed;
      case 'CHECKED_IN':
        return ReservationStatus.checkedIn;
      case 'COMPLETED':
        return ReservationStatus.completed;
      case 'CANCELLED':
        return ReservationStatus.cancelled;
      case 'NO_SHOW':
        return ReservationStatus.noShow;
      case 'PENDING':
      default:
        return ReservationStatus.pending;
    }
  }

  String get code {
    switch (this) {
      case ReservationStatus.confirmed:
        return 'CONFIRMED';
      case ReservationStatus.checkedIn:
        return 'CHECKED_IN';
      case ReservationStatus.completed:
        return 'COMPLETED';
      case ReservationStatus.cancelled:
        return 'CANCELLED';
      case ReservationStatus.noShow:
        return 'NO_SHOW';
      case ReservationStatus.pending:
        return 'PENDING';
    }
  }

  String get displayName {
    switch (this) {
      case ReservationStatus.pending:
        return 'Chờ xác nhận';
      case ReservationStatus.confirmed:
        return 'Đã xác nhận';
      case ReservationStatus.checkedIn:
        return 'Đã nhận bàn';
      case ReservationStatus.completed:
        return 'Đã hoàn tất';
      case ReservationStatus.cancelled:
        return 'Đã hủy';
      case ReservationStatus.noShow:
        return 'Không đến';
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

class ReservationOrderDetailModel {
  final int id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? note;
  final String type; // 'ITEM' | 'COMBO'
  final String? imageUrl;

  ReservationOrderDetailModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    double? totalPrice,
    this.note,
    this.type = 'ITEM',
    this.imageUrl,
  }) : totalPrice = totalPrice ?? (unitPrice * quantity);

  factory ReservationOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    final combo = json['combo'];
    final name = json['name'] ?? item?['name'] ?? combo?['name'] ?? 'Món ăn';
    final unitPrice = (json['unitPrice'] is num)
        ? (json['unitPrice'] as num).toDouble()
        : (item?['price'] is num)
            ? (item['price'] as num).toDouble()
            : (combo?['price'] is num)
                ? (combo['price'] as num).toDouble()
                : 0.0;
    final qty = (json['quantity'] is num) ? (json['quantity'] as num).toInt() : 1;
    final total = (json['totalPrice'] is num)
        ? (json['totalPrice'] as num).toDouble()
        : unitPrice * qty;

    return ReservationOrderDetailModel(
      id: json['id'] ?? json['orderDetailId'] ?? 0,
      name: name,
      quantity: qty,
      unitPrice: unitPrice,
      totalPrice: total,
      note: json['note'],
      type: json['type'] ?? (combo != null ? 'COMBO' : 'ITEM'),
      imageUrl: item?['imageUrl'] ?? combo?['imageUrl'],
    );
  }
}

class ReservationModel {
  final int id;
  final String code;
  final String date;
  final String startTime;
  final String? endTime;
  final int guestNumber;
  final int? tableId;
  final String? tableName;
  final String? floorName;
  final String? areaName;
  final double tableDeposit;
  final double itemsTotal;
  final double finalAmount;
  final ReservationStatus status;
  final String? note;
  final String? customerName;
  final String? guestName;
  final String? guestPhone;
  final String? email;
  final int? orderId;
  final List<CartItemModel> items;
  final List<ReservationOrderDetailModel> orderDetails;
  final DateTime? createdAt;

  ReservationModel({
    required this.id,
    required this.code,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.guestNumber,
    this.tableId,
    this.tableName,
    this.floorName,
    this.areaName,
    this.tableDeposit = 100000.0,
    this.itemsTotal = 0.0,
    this.finalAmount = 100000.0,
    this.status = ReservationStatus.pending,
    this.note,
    this.customerName,
    this.guestName,
    this.guestPhone,
    this.email,
    this.orderId,
    this.items = const [],
    this.orderDetails = const [],
    this.createdAt,
  });

  String get displayName {
    if (customerName != null && customerName!.trim().isNotEmpty) {
      return customerName!.trim();
    }
    if (guestName != null && guestName!.trim().isNotEmpty) {
      return guestName!.trim();
    }
    return 'Khách vãng lai';
  }

  String get displayPhone => guestPhone ?? '';

  String get displayTimeRange => endTime != null && endTime!.isNotEmpty ? '$startTime - $endTime' : startTime;

  bool get canCheckIn => status == ReservationStatus.confirmed;
  bool get canCancel => status == ReservationStatus.pending || status == ReservationStatus.confirmed;

  ReservationModel copyWith({
    int? id,
    String? code,
    String? date,
    String? startTime,
    String? endTime,
    int? guestNumber,
    int? tableId,
    String? tableName,
    String? floorName,
    String? areaName,
    double? tableDeposit,
    double? itemsTotal,
    double? finalAmount,
    ReservationStatus? status,
    String? note,
    String? customerName,
    String? guestName,
    String? guestPhone,
    String? email,
    int? orderId,
    List<CartItemModel>? items,
    List<ReservationOrderDetailModel>? orderDetails,
    DateTime? createdAt,
  }) {
    return ReservationModel(
      id: id ?? this.id,
      code: code ?? this.code,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      guestNumber: guestNumber ?? this.guestNumber,
      tableId: tableId ?? this.tableId,
      tableName: tableName ?? this.tableName,
      floorName: floorName ?? this.floorName,
      areaName: areaName ?? this.areaName,
      tableDeposit: tableDeposit ?? this.tableDeposit,
      itemsTotal: itemsTotal ?? this.itemsTotal,
      finalAmount: finalAmount ?? this.finalAmount,
      status: status ?? this.status,
      note: note ?? this.note,
      customerName: customerName ?? this.customerName,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      email: email ?? this.email,
      orderId: orderId ?? this.orderId,
      items: items ?? this.items,
      orderDetails: orderDetails ?? this.orderDetails,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['reservationStatus'] ?? json['status'];
    final status = ReservationStatus.fromString(rawStatus);

    List<ReservationOrderDetailModel> parsedDetails = [];
    if (json['orderDetails'] is List) {
      parsedDetails = (json['orderDetails'] as List)
          .map((e) => ReservationOrderDetailModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['items'] is List) {
      parsedDetails = (json['items'] as List)
          .map((e) => ReservationOrderDetailModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ReservationModel(
      id: json['reservationId'] ?? json['id'] ?? 0,
      code: json['reservationCode'] ?? json['code'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'],
      guestNumber: json['guestNumber'] ?? 2,
      tableId: json['table']?['id'] ?? json['tableId'],
      tableName: json['tableName'] ?? json['table']?['name'],
      floorName: json['floorName'] ?? json['table']?['floorName'],
      areaName: json['areaName'] ?? json['table']?['areaName'],
      tableDeposit: (json['tableDeposit'] is num)
          ? (json['tableDeposit'] as num).toDouble()
          : (json['depositAmount'] is num)
              ? (json['depositAmount'] as num).toDouble()
              : 100000.0,
      itemsTotal: (json['itemsTotal'] is num) ? (json['itemsTotal'] as num).toDouble() : 0.0,
      finalAmount: (json['finalAmount'] is num) ? (json['finalAmount'] as num).toDouble() : 100000.0,
      status: status,
      note: json['note'],
      customerName: json['customerName'] ?? json['guestName'],
      guestName: json['guestName'] ?? json['customerName'],
      guestPhone: json['phone'] ?? json['guestPhone'],
      email: json['email'],
      orderId: json['orderId'],
      orderDetails: parsedDetails,
    );
  }
}

