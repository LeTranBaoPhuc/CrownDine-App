enum MyVoucherType { percentage, fixedAmount }

/// A voucher assigned to the signed-in customer, not the public/admin voucher DTO.
class MyVoucherModel {
  final int assignmentId;
  final int voucherId;
  final String code;
  final String name;
  final MyVoucherType type;
  final double discountValue;
  final double? maxDiscountValue;
  final double? minValue;
  final String description;
  final int usageCount;
  final int? usageLimit;
  final DateTime? expiredAt;

  const MyVoucherModel(
      {required this.assignmentId,
      required this.voucherId,
      required this.code,
      required this.name,
      required this.type,
      required this.discountValue,
      this.maxDiscountValue,
      this.minValue,
      this.description = '',
      this.usageCount = 0,
      this.usageLimit,
      this.expiredAt});

  int? get remainingUses => usageLimit == null
      ? null
      : (usageLimit! - usageCount).clamp(0, usageLimit!);
  bool get isAvailable =>
      (expiredAt == null || expiredAt!.isAfter(DateTime.now())) &&
      (remainingUses == null || remainingUses! > 0);

  factory MyVoucherModel.fromJson(Map<String, dynamic> json) {
    double? money(String key, {bool required = false}) {
      final value = json[key];
      if (value == null && !required) return null;
      if (value is! num || !value.isFinite || value < 0) {
        throw const FormatException('Thông tin voucher không hợp lệ.');
      }
      return value.toDouble();
    }

    final type = switch (json['voucherType']) {
      'PERCENTAGE' => MyVoucherType.percentage,
      'FIXED_AMOUNT' => MyVoucherType.fixedAmount,
      _ => throw const FormatException('Loại voucher chưa được hỗ trợ.'),
    };
    final assignmentId = json['assignmentId'];
    final voucherId = json['voucherId'];
    final code = json['voucherCode'];
    final name = json['voucherName'];
    final count = json['usageCount'] ?? 0;
    final limit = json['usageLimit'];
    final rawExpiry = json['expiredAt'];
    final expiry =
        rawExpiry == null ? null : DateTime.tryParse(rawExpiry.toString());
    if (assignmentId is! int ||
        assignmentId <= 0 ||
        voucherId is! int ||
        voucherId <= 0 ||
        code is! String ||
        code.trim().isEmpty ||
        name is! String ||
        count is! int ||
        count < 0 ||
        (limit != null && (limit is! int || limit < 0)) ||
        (rawExpiry != null && expiry == null)) {
      throw const FormatException('Thông tin voucher không hợp lệ.');
    }
    return MyVoucherModel(
        assignmentId: assignmentId,
        voucherId: voucherId,
        code: code,
        name: name,
        type: type,
        discountValue: money('discountValue', required: true)!,
        maxDiscountValue: money('maxDiscountValue'),
        minValue: money('minValue'),
        description: json['description'] as String? ?? '',
        usageCount: count,
        usageLimit: limit as int?,
        expiredAt: expiry);
  }
}
