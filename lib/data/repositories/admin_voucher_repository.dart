import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/admin_voucher_model.dart';
import '../models/voucher_assignment_model.dart';

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

  Future<List<VoucherCustomerModel>> customers() async {
    final raw = _data(await _dio.get('users'));
    if (raw is! List) {
      throw const FormatException('Danh sách khách hàng không hợp lệ.');
    }
    return raw.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Dữ liệu khách hàng không hợp lệ.');
      }
      return VoucherCustomerModel.fromJson(item);
    }).toList();
  }

  Future<List<VoucherAssignmentModel>> assignments(int voucherId) async {
    final raw = _data(
        await _dio.get('${ApiEndpoints.vouchers}/$voucherId/assignments'));
    if (raw is! List) {
      throw const FormatException('Danh sách đã cấp không hợp lệ.');
    }
    return _parseAssignments(raw);
  }

  Future<List<VoucherAssignmentModel>> assign(int voucherId,
      {required List<int> userIds,
      required int usageLimit,
      DateTime? expiredAt}) async {
    if (userIds.isEmpty ||
        userIds.any((id) => id <= 0) ||
        usageLimit <= 0 ||
        (expiredAt != null && !expiredAt.isAfter(DateTime.now()))) {
      throw ArgumentError('Thông tin cấp voucher không hợp lệ.');
    }
    final raw = _data(await _dio.post(
      '${ApiEndpoints.vouchers}/$voucherId/assign-users',
      data: {
        'userIds': userIds.toSet().toList(),
        'usageLimit': usageLimit,
        if (expiredAt != null)
          'expiredAt': '${expiredAt.year.toString().padLeft(4, '0')}-'
              '${expiredAt.month.toString().padLeft(2, '0')}-'
              '${expiredAt.day.toString().padLeft(2, '0')}T'
              '${expiredAt.hour.toString().padLeft(2, '0')}:'
              '${expiredAt.minute.toString().padLeft(2, '0')}:00',
      },
    ));
    if (raw is! List) {
      throw const FormatException('Kết quả cấp voucher không hợp lệ.');
    }
    return _parseAssignments(raw);
  }

  List<VoucherAssignmentModel> _parseAssignments(List raw) => raw.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Dữ liệu cấp voucher không hợp lệ.');
        }
        return VoucherAssignmentModel.fromJson(item);
      }).toList();
}
