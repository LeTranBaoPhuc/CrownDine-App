import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/table_model.dart';

class TableRepository {
  final Dio _dio;
  TableRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  dynamic _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || body['status'] is! num || body['status'] >= 400) {
      throw const FormatException('Phản hồi bàn ăn không hợp lệ.');
    }
    return body['data'];
  }

  Future<List<FloorModel>> getFloors() async {
    final data = _data(await _dio.get(ApiEndpoints.layoutFloors));
    if (data is! List) throw const FormatException('Thiếu danh sách tầng.');
    return data
        .map((e) => FloorModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<TableModel>> getTables({int? floorId}) async {
    final data = _data(await _dio.get(ApiEndpoints.restaurantTables));
    if (data is! List) throw const FormatException('Thiếu danh sách bàn.');
    final tables = data
        .map((e) => TableModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return floorId == null
        ? tables
        : tables.where((t) => t.floorId == floorId).toList();
  }

  Future<List<TableModel>> getAvailableTables(
      {required String date,
      required String startTime,
      required int guestNumber}) async {
    final data = _data(await _dio
        .get('${ApiEndpoints.restaurantTables}/available', queryParameters: {
      'date': date,
      'startTime': startTime,
      'guestNumber': guestNumber
    }));
    if (data is! List)
      throw const FormatException('Thiếu danh sách bàn trống.');
    return data
        .map((e) => TableModel.fromJson(
            {...Map<String, dynamic>.from(e), 'status': 'AVAILABLE'}))
        .toList();
  }

  Future<TableModel> updateStatus(int tableId, TableStatus status) async {
    final data = _data(await _dio.patch(
        '${ApiEndpoints.restaurantTables}/$tableId',
        queryParameters: {'status': status.name.toUpperCase()}));
    if (data is! Map<String, dynamic> ||
        data['id'] != tableId ||
        data['status'] != status.name.toUpperCase()) {
      throw const FormatException('Máy chủ chưa xác nhận trạng thái bàn.');
    }
    return TableModel.fromJson(data);
  }
}
