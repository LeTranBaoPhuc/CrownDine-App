import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map && body['message'] is String) {
      return body['message'] as String;
    }
    if (error.response?.statusCode == 401 ||
        error.response?.statusCode == 403) {
      return 'Phiên đăng nhập hết hạn hoặc bạn không có quyền thực hiện.';
    }
    return 'Không kết nối được máy chủ. Vui lòng tải lại dữ liệu.';
  }
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message.toString();
  return 'Không xử lý được yêu cầu. Vui lòng thử lại.';
}
