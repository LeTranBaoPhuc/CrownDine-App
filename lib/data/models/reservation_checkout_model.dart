class ReservationCheckoutModel {
  final int reservationId;
  final String reservationCode;
  final int? orderId;
  final String status;
  final DateTime? expiresAt;
  final double itemsTotal;
  final double discountAmount;
  final double finalAmount;
  final double tableDeposit;
  final double depositAmount;
  final double remainingAmount;

  const ReservationCheckoutModel({
    required this.reservationId,
    required this.reservationCode,
    this.orderId,
    required this.status,
    this.expiresAt,
    required this.itemsTotal,
    required this.discountAmount,
    required this.finalAmount,
    required this.tableDeposit,
    required this.depositAmount,
    required this.remainingAmount,
  });

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());
  bool get canPay => status == 'PENDING' && !isExpired && depositAmount > 0;
  bool get canApplyVoucher => canPay && orderId != null && itemsTotal > 0;

  factory ReservationCheckoutModel.fromJson(Map<String, dynamic> json) {
    // Never silently substitute local/mock totals for a malformed server quote.
    double money(String key) {
      final value = json[key];
      if (value is! num || !value.isFinite || value < 0) {
        throw const FormatException('Bảng thanh toán không hợp lệ.');
      }
      return value.toDouble();
    }

    final id = json['reservationId'];
    final code = json['reservationCode'];
    final status = json['reservationStatus'];
    if (id is! int ||
        id <= 0 ||
        code is! String ||
        code.isEmpty ||
        status is! String) {
      throw const FormatException('Thiếu thông tin đặt bàn từ máy chủ.');
    }
    final expiry = json['expiratedAt'];
    final expiresAt =
        expiry == null ? null : DateTime.tryParse(expiry.toString());
    if (expiry != null && expiresAt == null) {
      throw const FormatException('Thời hạn đặt bàn không hợp lệ.');
    }
    return ReservationCheckoutModel(
      reservationId: id,
      reservationCode: code,
      orderId: json['orderId'] as int?,
      status: status,
      expiresAt: expiresAt,
      itemsTotal: money('itemsTotal'),
      discountAmount: money('discountAmount'),
      finalAmount: money('finalAmount'),
      tableDeposit: money('tableDeposit'),
      depositAmount: money('depositAmount'),
      remainingAmount: money('remainingAmount'),
    );
  }
}

class ReservationPaymentResult {
  final String code;
  final String reservationCode;
  final String status;
  final String reservationStatus;
  final String target;
  final double amount;

  const ReservationPaymentResult(
      {required this.code,
      required this.reservationCode,
      required this.status,
      this.reservationStatus = 'CONFIRMED',
      required this.target,
      required this.amount});

  factory ReservationPaymentResult.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    if (amount is! num || !amount.isFinite || amount < 0) {
      throw const FormatException('Kết quả thanh toán không hợp lệ.');
    }
    return ReservationPaymentResult(
      code: '${json['code'] ?? ''}',
      reservationCode: json['reservationCode'] as String? ?? '',
      status: json['status'] as String? ?? '',
      reservationStatus: json['reservationStatus'] as String? ?? '',
      target: json['target'] as String? ?? '',
      amount: amount.toDouble(),
    );
  }
}
