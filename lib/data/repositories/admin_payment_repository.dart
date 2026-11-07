import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/admin_payment_model.dart';

class AdminPaymentRepository {
  final Dio _dio;
  AdminPaymentRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  dynamic _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['status'] is! num || body['status'] >= 400) {
      throw const FormatException('Phản hồi giao dịch không hợp lệ.');
    }
    return body['data'];
  }

  Future<AdminPaymentPage> list({
    int page = 1,
    int size = 10,
    AdminPaymentFilter filter = const AdminPaymentFilter(),
  }) async {
    if (page < 1 ||
        size < 1 ||
        (filter.fromDate != null &&
            filter.toDate != null &&
            filter.fromDate!.isAfter(filter.toDate!))) {
      throw ArgumentError('Bộ lọc giao dịch không hợp lệ.');
    }
    final raw = _data(await _dio.get(ApiEndpoints.payments, queryParameters: {
      'page': page,
      'size': size,
      if (filter.search?.trim().isNotEmpty == true)
        'search': filter.search!.trim(),
      if (filter.status != null) 'status': filter.status,
      if (filter.method != null) 'method': filter.method,
      if (filter.type != null) 'type': filter.type,
      if (filter.target != null) 'target': filter.target,
      if (filter.source != null) 'source': filter.source,
      if (filter.fromDate != null)
        'fromDate': DateFormat('yyyy-MM-dd').format(filter.fromDate!),
      if (filter.toDate != null)
        'toDate': DateFormat('yyyy-MM-dd').format(filter.toDate!),
    }));
    if (raw is! Map ||
        raw['data'] is! List ||
        raw['page'] is! int ||
        raw['totalPages'] is! int ||
        raw['totalItems'] is! num) {
      throw const FormatException('Danh sách giao dịch không hợp lệ.');
    }
    return AdminPaymentPage(
      items: (raw['data'] as List).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Dữ liệu giao dịch không hợp lệ.');
        }
        return AdminPayment.fromJson(item);
      }).toList(),
      page: raw['page'] as int,
      totalPages: raw['totalPages'] as int,
      totalItems: (raw['totalItems'] as num).toInt(),
    );
  }

  Future<AdminPayment> detail(int id) async {
    if (id <= 0) throw ArgumentError('Mã giao dịch không hợp lệ.');
    final raw = _data(await _dio.get(ApiEndpoints.paymentById(id)));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Chi tiết giao dịch không hợp lệ.');
    }
    final payment = AdminPayment.fromJson(raw);
    if (payment.id != id) {
      throw const FormatException('Chi tiết giao dịch không khớp.');
    }
    return payment;
  }
}
