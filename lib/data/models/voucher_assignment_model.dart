class VoucherCustomerModel {
  final int id;
  final String username;
  final String name;
  final String? phone;
  final String? email;

  const VoucherCustomerModel(
      {required this.id,
      required this.username,
      required this.name,
      this.phone,
      this.email});

  factory VoucherCustomerModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final username = json['username'];
    if (id is! int || id <= 0 || username is! String || username.isEmpty) {
      throw const FormatException('Dữ liệu khách hàng không hợp lệ.');
    }
    final first = json['firstName'] as String? ?? '';
    final last = json['lastName'] as String? ?? '';
    final full = '$first $last'.trim();
    return VoucherCustomerModel(
        id: id,
        username: username,
        name: full.isEmpty ? username : full,
        phone: json['phone'] as String?,
        email: json['email'] as String?);
  }
}

class VoucherAssignmentModel {
  final int assignmentId;
  final int customerId;
  final String username;
  final String name;
  final int usageCount;
  final int? usageLimit;
  final DateTime? expiredAt;

  const VoucherAssignmentModel(
      {required this.assignmentId,
      required this.customerId,
      required this.username,
      required this.name,
      required this.usageCount,
      this.usageLimit,
      this.expiredAt});

  int? get remaining => usageLimit == null
      ? null
      : (usageLimit! - usageCount).clamp(0, usageLimit!);

  factory VoucherAssignmentModel.fromJson(Map<String, dynamic> json) {
    final id = json['assignmentId'];
    final customerId = json['customerId'];
    final username = json['username'];
    final name = json['fullName'];
    final count = json['usageCount'] ?? 0;
    final limit = json['usageLimit'];
    final expiry = json['expiredAt'];
    final parsedExpiry =
        expiry == null ? null : DateTime.tryParse(expiry.toString());
    if (id is! int ||
        id <= 0 ||
        customerId is! int ||
        customerId <= 0 ||
        username is! String ||
        count is! int ||
        count < 0 ||
        (limit != null && (limit is! int || limit < 0)) ||
        (expiry != null && parsedExpiry == null)) {
      throw const FormatException('Dữ liệu cấp voucher không hợp lệ.');
    }
    return VoucherAssignmentModel(
        assignmentId: id,
        customerId: customerId,
        username: username,
        name: name is String && name.trim().isNotEmpty ? name : username,
        usageCount: count,
        usageLimit: limit as int?,
        expiredAt: parsedExpiry);
  }
}
