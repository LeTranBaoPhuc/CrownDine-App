import 'package:intl/intl.dart';

class FeedbackModel {
  final int id;
  final int rating;
  final String comment;
  final String fullName;
  final String? avatarUrl;
  final String? guestName;
  final String? reply;
  final int? itemId;
  final String? itemName;
  final int? comboId;
  final String? comboName;
  final int? orderId;
  final int? orderDetailId;
  final int? userId;
  final bool isFeatured;
  final String? status;
  final String createdAt;
  final String? updatedAt;

  FeedbackModel({
    required this.id,
    required this.rating,
    required this.comment,
    this.fullName = 'Thực khách CrownDine',
    this.avatarUrl,
    this.guestName,
    this.reply,
    this.itemId,
    this.itemName,
    this.comboId,
    this.comboName,
    this.orderId,
    this.orderDetailId,
    this.userId,
    this.isFeatured = false,
    this.status,
    this.createdAt = 'Vừa xong',
    this.updatedAt,
  });

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  String get shortDate {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    final rawRating = json['rating'] is int
        ? json['rating'] as int
        : int.tryParse('${json['rating']}') ?? 5;

    return FeedbackModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      rating: rawRating.clamp(1, 5),
      comment: json['comment']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['guestName']?.toString() ?? 'Thực khách CrownDine',
      avatarUrl: json['avatarUrl']?.toString(),
      guestName: json['guestName']?.toString(),
      reply: json['reply']?.toString(),
      itemId: json['itemId'] != null ? int.tryParse('${json['itemId']}') : null,
      itemName: json['itemName']?.toString() ?? json['item']?['name']?.toString(),
      comboId: json['comboId'] != null ? int.tryParse('${json['comboId']}') : null,
      comboName: json['comboName']?.toString() ?? json['combo']?['name']?.toString(),
      orderId: json['orderId'] != null ? int.tryParse('${json['orderId']}') : null,
      orderDetailId: json['orderDetailId'] != null ? int.tryParse('${json['orderDetailId']}') : null,
      userId: json['userId'] != null ? int.tryParse('${json['userId']}') : null,
      isFeatured: json['isFeatured'] == true,
      status: json['status']?.toString(),
      createdAt: json['createdAt']?.toString() ?? 'Vừa xong',
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rating': rating,
        'comment': comment,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'guestName': guestName,
        'reply': reply,
        'itemId': itemId,
        'itemName': itemName,
        'comboId': comboId,
        'comboName': comboName,
        'orderId': orderId,
        'orderDetailId': orderDetailId,
        'userId': userId,
        'isFeatured': isFeatured,
        'status': status,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}
