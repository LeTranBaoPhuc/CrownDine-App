import '../../core/utils/image_utils.dart';

class ItemModel {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? priceAfterDiscount;
  final String status; // 'AVAILABLE' | 'SOLD_OUT' | 'UNAVAILABLE' | 'STOPPED'
  final String? categoryName;
  final double averageRating;
  final int feedbackCount;
  final List<String> tags;
  final bool isCombo;

  ItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.priceAfterDiscount,
    this.status = 'AVAILABLE',
    this.categoryName,
    this.averageRating = 4.8,
    this.feedbackCount = 24,
    this.tags = const [],
    this.isCombo = false,
  });

  bool get isAvailable => status == 'AVAILABLE';

  double get displayPrice => (priceAfterDiscount != null && priceAfterDiscount! > 0)
      ? priceAfterDiscount!
      : price;

  bool get hasDiscount =>
      priceAfterDiscount != null && priceAfterDiscount! > 0 && priceAfterDiscount! < price;

  double get discountPercent {
    if (!hasDiscount || price <= 0) return 0;
    return ((price - priceAfterDiscount!) / price) * 100;
  }

  factory ItemModel.fromJson(Map<String, dynamic> json, {String? categoryNameFallback}) {
    final rawStatus = json['status']?.toString().toUpperCase() ?? 'AVAILABLE';
    final isCombo = json['isCombo'] == true || (json['items'] is List && json['categoryId'] == null);
    final rawPrice = (json['price'] is num)
        ? (json['price'] as num).toDouble()
        : double.tryParse('${json['price']}') ?? 0.0;

    final rawDiscount = json['priceAfterDiscount'] != null
        ? ((json['priceAfterDiscount'] is num)
            ? (json['priceAfterDiscount'] as num).toDouble()
            : double.tryParse('${json['priceAfterDiscount']}'))
        : null;

    final tags = <String>[];
    if (json['tags'] != null && json['tags'] is List) {
      tags.addAll(List<String>.from(json['tags']));
    } else {
      if (isCombo) tags.add('Combo');
      if (rawDiscount != null && rawDiscount > 0 && rawDiscount < rawPrice) tags.add('Ưu đãi');
      if (rawPrice > 500000) tags.add('Thượng hạng');
    }

    final catId = json['categoryId'] is int
        ? json['categoryId'] as int
        : (int.tryParse('${json['categoryId']}') ?? (isCombo ? -99 : 0));

    return ItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      categoryId: catId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: ImageUtils.getSafeImageUrl(json['imageUrl'] ?? json['image']),
      price: rawPrice,
      priceAfterDiscount: rawDiscount,
      status: rawStatus,
      categoryName: json['category'] ?? json['categoryName'] ?? categoryNameFallback ?? (isCombo ? 'Set Menu Combo' : null),
      averageRating: json['averageRating'] != null ? (json['averageRating'] as num).toDouble() : 4.8,
      feedbackCount: json['feedbackCount'] != null ? (json['feedbackCount'] as num).toInt() : 24,
      tags: tags,
      isCombo: isCombo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'priceAfterDiscount': priceAfterDiscount,
        'status': status,
        'category': categoryName,
        'averageRating': averageRating,
        'feedbackCount': feedbackCount,
        'tags': tags,
        'isCombo': isCombo,
      };
}
