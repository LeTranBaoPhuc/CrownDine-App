import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/table_model.dart';

class TableRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<FloorModel>> getFloors() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.layoutFloors);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null && list.isNotEmpty) {
          return list.map((e) => FloorModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.floors;
  }

  Future<List<TableModel>> getTables({int? floorId}) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(
        ApiEndpoints.layoutTables,
        queryParameters: floorId != null ? {'floorId': floorId} : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null && list.isNotEmpty) {
          return list.map((e) => TableModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    if (floorId != null) {
      return MockData.tables.where((t) => t.floorId == floorId).toList();
    }
    return MockData.tables;
  }
}
