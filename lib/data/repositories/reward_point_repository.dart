import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/reward_point_model.dart';

class RewardPointRepository {
  final Dio _dio;
  RewardPointRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  dynamic _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['status'] is! num || body['status'] >= 400) {
      throw const FormatException('Phản hồi điểm thưởng không hợp lệ.');
    }
    return body['data'];
  }

  Future<PointHistoryPage> history({int page = 1, int size = 20}) async {
    final raw = _data(await _dio.get(ApiEndpoints.pointHistory,
        queryParameters: {'page': page, 'size': size}));
    if (raw is! Map ||
        raw['data'] is! List ||
        raw['page'] is! int ||
        raw['totalPages'] is! int) {
      throw const FormatException('Lịch sử điểm không hợp lệ.');
    }
    return PointHistoryPage(
      entries: (raw['data'] as List).map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Lịch sử điểm không hợp lệ.');
        }
        return PointHistoryEntry.fromJson(entry);
      }).toList(),
      page: raw['page'] as int,
      totalPages: raw['totalPages'] as int,
    );
  }

  Future<List<RewardVoucher>> rewards() async {
    final rewards = <RewardVoucher>[];
    var page = 1;
    var totalPages = 1;
    do {
      final raw = _data(await _dio.get(ApiEndpoints.vouchers,
          queryParameters: {'page': page, 'size': 50}));
      if (raw is! Map || raw['data'] is! List || raw['totalPages'] is! int) {
        throw const FormatException('Danh sách quà đổi điểm không hợp lệ.');
      }
      totalPages = raw['totalPages'] as int;
      for (final item in raw['data'] as List) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Voucher điểm thưởng không hợp lệ.');
        }
        if (item['pointsRequired'] is int && item['pointsRequired'] > 0) {
          rewards.add(RewardVoucher.fromJson(item));
        }
      }
      page++;
    } while (page <= totalPages);
    return rewards;
  }

  Future<void> exchange(int voucherId) async {
    _data(await _dio.post('${ApiEndpoints.vouchers}/$voucherId/exchange'));
  }
}
