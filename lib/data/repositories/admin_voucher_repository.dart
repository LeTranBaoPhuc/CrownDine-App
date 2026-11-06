import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/admin_voucher_model.dart';

class AdminVoucherRepository {
  final Dio _dio;
  AdminVoucherRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  dynamic _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['status'] is! num || body['status'] >= 400) {
      throw const FormatException('Phản hồi voucher không hợp lệ.');
    }
    return body['data'];
  }

  Future<AdminVoucherPage> list(
      {int page = 1,
      int size = 10,
      String? search,
      AdminVoucherType? type}) async {
    final raw = _data(await _dio.get(ApiEndpoints.vouchers, queryParameters: {
      'page': page,
      'size': size,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (type != null)
        'type':
            type == AdminVoucherType.percentage ? 'PERCENTAGE' : 'FIXED_AMOUNT',
    }));
    if (raw is! Map ||
        raw['data'] is! List ||
        raw['page'] is! int ||
        raw['totalPages'] is! int ||
        raw['totalItems'] is! num) {
      throw const FormatException('Danh sách voucher không hợp lệ.');
    }
    return AdminVoucherPage(
      items: (raw['data'] as List).map((e) {
        if (e is! Map<String, dynamic>) {
          throw const FormatException('Dữ liệu voucher không hợp lệ.');
        }
        return AdminVoucherModel.fromJson(e);
      }).toList(),
      page: raw['page'] as int,
      totalPages: raw['totalPages'] as int,
      totalItems: (raw['totalItems'] as num).toInt(),
    );
  }

  Future<AdminVoucherModel> get(int id) {
    return _dio.get('${ApiEndpoints.vouchers}/$id').then((response) {
      final raw = _data(response);
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Dữ liệu voucher không hợp lệ.');
      }
      return AdminVoucherModel.fromJson(raw);
    });
  }

  Future<AdminVoucherModel> create(AdminVoucherDraft draft) async {
    final raw =
        _data(await _dio.post(ApiEndpoints.vouchers, data: draft.toJson()));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu voucher không hợp lệ.');
    }
    return AdminVoucherModel.fromJson(raw);
  }

  Future<AdminVoucherModel> update(int id, AdminVoucherDraft draft) async {
    final raw = _data(
        await _dio.patch('${ApiEndpoints.vouchers}/$id', data: draft.toJson()));
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Dữ liệu voucher không hợp lệ.');
    }
    return AdminVoucherModel.fromJson(raw);
  }

  Future<void> delete(int id) async {
    _data(await _dio.delete('${ApiEndpoints.vouchers}/$id'));
  }
}
