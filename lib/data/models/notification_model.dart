class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final String? payload;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.payload,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;
  bool get isReservation => type.contains('RESERVATION');
  bool get isVoucher => type.contains('VOUCHER');

  String get typeDisplayName {
    switch (type) {
      case 'RESERVATION_CONFIRMED':
        return 'Đặt bàn thành công';
      case 'RESERVATION_REMINDER':
        return 'Nhắc giờ dùng bữa';
      case 'VOUCHER_GRANTED':
        return 'Ưu đãi mới tặng bạn';
      case 'VOUCHER_EXPIRING_SOON':
        return 'Voucher sắp hết hạn';
      case 'VOUCHER_EXPIRED':
        return 'Voucher hết hạn';
      default:
        return 'Thông báo hệ thống';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) {
      return 'Vừa xong';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'SYSTEM',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      payload: json['payload']?.toString(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt'].toString()) : null,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'payload': payload,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? id,
    String? type,
    String? title,
    String? message,
    String? payload,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      payload: payload ?? this.payload,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

