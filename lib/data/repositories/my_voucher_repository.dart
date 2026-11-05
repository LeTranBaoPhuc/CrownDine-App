import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/my_voucher_model.dart';

class MyVoucherRepository {
  final Dio _dio;
  MyVoucherRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  Future<List<MyVoucherModel>> getMyVouchers() async {
    final response = await _dio.get('${ApiEndpoints.userVouchers}/my');
    final body = response.data;
    if (body is! Map<String, dynamic> ||
        (body['status'] is num && (body['status'] as num) >= 400) ||
        body['data'] is! List) {
      throw const FormatException(
          'Không thể đọc danh sách voucher. Vui lòng thử lại.');
    }
    return (body['data'] as List).map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Thông tin voucher không hợp lệ.');
      }
      return MyVoucherModel.fromJson(item);
    }).toList();
  }
}
