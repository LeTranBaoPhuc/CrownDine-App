class AdminPayment {
  final int id;
  final int code;
  final double amount;
  final String? username;
  final String? orderCode;
  final String? reservationCode;
  final String? transactionCode;
  final String method;
  final String status;
  final String type;
  final String target;
  final String source;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AdminPayment({
    required this.id,
    required this.code,
    required this.amount,
    required this.username,
    required this.orderCode,
    required this.reservationCode,
    required this.transactionCode,
    required this.method,
    required this.status,
    required this.type,
    required this.target,
    required this.source,
    required this.createdAt,
    this.updatedAt,
  });

  factory AdminPayment.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final code = json['code'];
    final amount = json['amount'];
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? ''}');
    if (id is! int ||
        id <= 0 ||
        code is! int ||
        code <= 0 ||
        amount is! num ||
        !amount.isFinite ||
        amount < 0 ||
        createdAt == null) {
      throw const FormatException('Dữ liệu giao dịch không hợp lệ.');
    }
    String value(String key) {
      final raw = json[key];
      if (raw == null || (raw is String && raw.trim().isEmpty)) {
        return 'UNKNOWN';
      }
      if (raw is! String) {
        throw const FormatException('Dữ liệu giao dịch không hợp lệ.');
      }
      return raw;
    }

    String? optional(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is! String) {
        throw const FormatException('Dữ liệu giao dịch không hợp lệ.');
      }
      return raw;
    }

    return AdminPayment(
      id: id,
      code: code,
      amount: amount.toDouble(),
      username: optional('username'),
      orderCode: optional('orderCode'),
      reservationCode: optional('reservationCode'),
      transactionCode: optional('transactionCode'),
      method: value('method'),
      status: value('status'),
      type: value('type'),
      target: value('target'),
      source: value('source'),
      createdAt: createdAt,
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }
}

class AdminPaymentPage {
  final List<AdminPayment> items;
  final int page;
  final int totalPages;
  final int totalItems;

  const AdminPaymentPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
  });
}

class AdminPaymentFilter {
  final String? search;
  final String? status;
  final String? method;
  final String? type;
  final String? target;
  final String? source;
  final DateTime? fromDate;
  final DateTime? toDate;

  const AdminPaymentFilter({
    this.search,
    this.status,
    this.method,
    this.type,
    this.target,
    this.source,
    this.fromDate,
    this.toDate,
  });
}
