import '../../core/utils/image_utils.dart';
import 'item_model.dart';

class FavoriteModel {
  final int id;
  final int? itemId;
  final String? itemName;
  final String? itemImageUrl;
  final double? itemPrice;
  final int? comboId;
  final String? comboName;
  final String? comboImageUrl;
  final double? comboPrice;
  final DateTime? createdAt;

  const FavoriteModel({
    required this.id,
    this.itemId,
    this.itemName,
    this.itemImageUrl,
    this.itemPrice,
    this.comboId,
    this.comboName,
    this.comboImageUrl,
    this.comboPrice,
    this.createdAt,
  });

  bool get isCombo => comboId != null;

  int get targetId => isCombo ? comboId! : (itemId ?? 0);

  String get displayName => isCombo ? (comboName ?? 'Combo') : (itemName ?? 'Món ăn');

  String get displayImageUrl {
    final rawUrl = isCombo ? (comboImageUrl ?? '') : (itemImageUrl ?? '');
    return ImageUtils.getSafeImageUrl(rawUrl);
  }

  double get displayPrice => (isCombo ? comboPrice : itemPrice) ?? 0.0;

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      itemId: json['itemId'] is int ? json['itemId'] : int.tryParse(json['itemId']?.toString() ?? ''),
      itemName: json['itemName'] as String?,
      itemImageUrl: json['itemImageUrl'] as String?,
      itemPrice: (json['itemPrice'] as num?)?.toDouble(),
      comboId: json['comboId'] is int ? json['comboId'] : int.tryParse(json['comboId']?.toString() ?? ''),
      comboName: json['comboName'] as String?,
      comboImageUrl: json['comboImageUrl'] as String?,
      comboPrice: (json['comboPrice'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'itemImageUrl': itemImageUrl,
      'itemPrice': itemPrice,
      'comboId': comboId,
      'comboName': comboName,
      'comboImageUrl': comboImageUrl,
      'comboPrice': comboPrice,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Helper to convert dish favorite to ItemModel for detail views
  ItemModel toItemModel() {
    return ItemModel(
      id: targetId,
      categoryId: 0,
      name: displayName,
      description: isCombo ? 'Set Combo đặc biệt' : 'Món ăn hấp dẫn tại CrownDine',
      price: displayPrice,
      imageUrl: displayImageUrl,
      categoryName: isCombo ? 'Combo' : 'Món ăn',
      status: 'AVAILABLE',
      isCombo: isCombo,
    );
  }
}

