class VoucherModel {
  final int id;
  final String code;
  final String name;
  final String description;
  final double discountPercent;
  final double? maxDiscount;
  final double minOrderValue;
  final DateTime? expiryDate;

  VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountPercent,
    this.maxDiscount,
    this.minOrderValue = 0,
    this.expiryDate,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      discountPercent: (json['discountPercent'] is num)
          ? (json['discountPercent'] as num).toDouble()
          : double.tryParse('${json['discountPercent']}') ?? 10.0,
      maxDiscount: json['maxDiscount'] != null ? (json['maxDiscount'] as num).toDouble() : null,
      minOrderValue: (json['minOrderValue'] is num) ? (json['minOrderValue'] as num).toDouble() : 0.0,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate']) : null,
    );
  }
}
