class ItemModel {
  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? priceAfterDiscount;
  final String status; // 'AVAILABLE' | 'SOLD_OUT' | 'STOPPED'
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

  double get displayPrice => priceAfterDiscount ?? price;

  bool get hasDiscount => priceAfterDiscount != null && priceAfterDiscount! < price;

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      categoryId: json['categoryId'] is int ? json['categoryId'] : int.tryParse('${json['categoryId']}') ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse('${json['price']}') ?? 0.0,
      priceAfterDiscount: json['priceAfterDiscount'] != null
          ? ((json['priceAfterDiscount'] is num)
              ? (json['priceAfterDiscount'] as num).toDouble()
              : double.tryParse('${json['priceAfterDiscount']}'))
          : null,
      status: json['status'] ?? 'AVAILABLE',
      categoryName: json['category'] ?? json['categoryName'],
      averageRating: json['averageRating'] != null ? (json['averageRating'] as num).toDouble() : 4.8,
      feedbackCount: json['feedbackCount'] ?? 24,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : const [],
      isCombo: json['isCombo'] == true,
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
