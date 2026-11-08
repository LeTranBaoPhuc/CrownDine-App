import 'package:dio/dio.dart';

dynamic responseData(Response<dynamic> response) {
  final body = response.data;
  if (body is! Map || body['status'] is! num || body['status'] >= 400) {
    throw const FormatException('Phản hồi máy chủ không hợp lệ.');
  }
  return body['data'];
}

List<dynamic> responseList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final list = data['data'] ?? data['content'] ?? data['items'];
    if (list is List) return list;
  }
  throw const FormatException('Không đọc được danh sách từ máy chủ.');
}
