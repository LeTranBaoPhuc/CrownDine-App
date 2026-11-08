import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

enum SetupKind { category, combo, floor, area, table, shift }

class AdminSetupRepository {
  final Dio _dio;
  AdminSetupRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  String path(SetupKind kind) => switch (kind) {
        SetupKind.category => 'categories',
        SetupKind.combo => 'combos',
        SetupKind.shift => 'shifts',
        SetupKind.floor => 'layout/floors',
        SetupKind.area => 'layout/areas',
        SetupKind.table => 'layout/tables',
      };
  Future<List<Map<String, dynamic>>> items() async =>
      responseList(responseData(await _dio.get('items')))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  Future<List<Map<String, dynamic>>> list(SetupKind kind,
      {int? floorId, int? areaId}) async {
    if (kind == SetupKind.area || kind == SetupKind.table) {
      if (floorId == null) throw StateError('Vui lòng chọn tầng.');
      final layout =
          responseData(await _dio.get('layout/floors/$floorId/layout'));
      final areas = responseList(layout['areas'])
          .map((e) => Map<String, dynamic>.from(e));
      if (kind == SetupKind.area) {
        return areas
            .map((a) => {...a, 'id': a['areaId'], 'name': a['areaName']})
            .toList();
      }
      return areas
          .where((a) => a['areaId'] == areaId)
          .expand((a) => responseList(a['tables']))
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return responseList(responseData(await _dio.get(path(kind))))
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> save(SetupKind kind, Map<String, dynamic> data,
      {int? id, int? parentId}) async {
    String endpoint = path(kind);
    if (id != null) {
      responseData(await _dio.put('$endpoint/$id', data: data));
    } else {
      if (kind == SetupKind.area) endpoint = 'layout/floors/$parentId/areas';
      if (kind == SetupKind.table) endpoint = 'layout/areas/$parentId/tables';
      responseData(await _dio.post(endpoint, data: data));
    }
  }

  Future<void> delete(SetupKind kind, int id) async {
    responseData(await _dio.delete('${path(kind)}/$id'));
  }
}
