enum AdminVoucherType { percentage, fixedAmount }

class AdminVoucherModel {
  final int id;
  final String code;
  final String name;
  final AdminVoucherType type;
  final double discountValue;
  final double? maxDiscountValue;
  final double? minValue;
  final String description;
  final int? pointsRequired;

  const AdminVoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.discountValue,
    this.maxDiscountValue,
    this.minValue,
    this.description = '',
    this.pointsRequired,
  });

  factory AdminVoucherModel.fromJson(Map<String, dynamic> json) {
    double? amount(String key, {bool required = false}) {
      final value = json[key];
      if (value == null && !required) return null;
      if (value is! num || !value.isFinite || value < 0) {
        throw const FormatException('Dữ liệu voucher không hợp lệ.');
      }
      return value.toDouble();
    }

    final id = json['id'];
    final code = json['code'];
    final name = json['name'];
    final type = switch (json['type']) {
      'PERCENTAGE' => AdminVoucherType.percentage,
      'FIXED_AMOUNT' => AdminVoucherType.fixedAmount,
      _ => throw const FormatException('Loại voucher không hợp lệ.'),
    };
    if (id is! int ||
        id <= 0 ||
        code is! String ||
        code.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty) {
      throw const FormatException('Dữ liệu voucher không hợp lệ.');
    }
    return AdminVoucherModel(
      id: id,
      code: code,
      name: name,
      type: type,
      discountValue: amount('discountValue', required: true)!,
      maxDiscountValue: amount('maxDiscountValue'),
      minValue: amount('minValue'),
      description: json['description'] as String? ?? '',
      pointsRequired: json['pointsRequired'] as int?,
    );
  }
}

class AdminVoucherPage {
  final List<AdminVoucherModel> items;
  final int page;
  final int totalPages;
  final int totalItems;

  const AdminVoucherPage(
      {required this.items,
      required this.page,
      required this.totalPages,
      required this.totalItems});
}

class AdminVoucherDraft {
  final String code;
  final String name;
  final AdminVoucherType type;
  final double discountValue;
  final double? maxDiscountValue;
  final double? minValue;
  final String description;

  const AdminVoucherDraft(
      {required this.code,
      required this.name,
      required this.type,
      required this.discountValue,
      this.maxDiscountValue,
      this.minValue,
      required this.description});

  Map<String, dynamic> toJson() => {
        'code': code.trim().toUpperCase(),
        'name': name.trim(),
        'type':
            type == AdminVoucherType.percentage ? 'PERCENTAGE' : 'FIXED_AMOUNT',
        'discountValue': discountValue,
        'maxDiscountValue': maxDiscountValue,
        'minValue': minValue,
        'description': description.trim(),
      };
}
