import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/reservation_checkout_model.dart';

/// Real backend only. Checkout/payment must never fall back to mock success.
class ReservationCheckoutRepository {
  final Dio _dio;
  ReservationCheckoutRepository({Dio? dio})
      : _dio = dio ?? ApiClient.instance.dio;

  dynamic _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Phản hồi máy chủ không hợp lệ.');
    }
    final status = body['status'];
    if (status is num && status >= 400) {
      throw StateError(
          body['message']?.toString() ?? 'Yêu cầu không thành công.');
    }
    return body['data'];
  }

  Future<ReservationCheckoutModel> getCheckout(int reservationId) async {
    final data = _data(await _dio.get('reservations/$reservationId/checkout'));
    final checkout =
        ReservationCheckoutModel.fromJson(data as Map<String, dynamic>);
    if (checkout.reservationId != reservationId) {
      throw const FormatException('Bảng thanh toán không khớp đặt bàn.');
    }
    return checkout;
  }

  Future<void> applyVoucher(int orderId, String code) async {
    final normalized = code.trim().toUpperCase();
    _data(await _dio.post('vouchers/validate',
        data: {'orderId': orderId, 'code': normalized}));
    _data(await _dio
        .post('orders/$orderId/voucher/apply', data: {'code': normalized}));
  }

  Future<void> removeVoucher(int orderId) async {
    _data(await _dio.delete('orders/$orderId/voucher'));
  }

  Future<Uri> createPayment(String reservationCode) async {
    final data = _data(await _dio.post('payments/create', data: {
      'reservationCode': reservationCode,
      'method': 'PAYOS',
    }));
    final uri = data is String ? Uri.tryParse(data) : null;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Liên kết thanh toán không hợp lệ.');
    }
    return uri;
  }

  Future<Map<String, dynamic>?> latestPayment(int reservationId) async {
    final data =
        _data(await _dio.get('payments/reservations/$reservationId/latest'));
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  Future<ReservationPaymentResult> getPayment(String code) async {
    if (!RegExp(r'^\d+$').hasMatch(code)) {
      throw const FormatException('Mã thanh toán không hợp lệ.');
    }
    final data = _data(await _dio.get('payments/code/$code'));
    return ReservationPaymentResult.fromJson(data as Map<String, dynamic>);
  }
}
