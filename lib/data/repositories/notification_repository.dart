import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _client = ApiClient.instance;

  /// Lấy danh sách thông báo phân trang của người dùng hiện tại
  Future<List<NotificationModel>> getMyNotifications({int page = 1, int size = 20}) async {
    try {
      final response = await _client.dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'size': size},
      );
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'];
        List? rawList;
        if (resData is Map && resData['data'] is List) {
          rawList = resData['data'] as List;
        } else if (resData is List) {
          rawList = resData;
        }

        if (rawList != null) {
          return rawList
              .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Lấy số lượng thông báo chưa đọc
  Future<int> getUnreadCount() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.notificationUnreadCount);
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'];
        if (resData is Map && resData['unreadCount'] != null) {
          return (resData['unreadCount'] as num).toInt();
        } else if (resData is num) {
          return resData.toInt();
        }
      }
    } catch (_) {}
    return 0;
  }

  /// Đánh dấu thông báo đã đọc
  Future<NotificationModel?> markAsRead(int id) async {
    try {
      final response = await _client.dio.patch(ApiEndpoints.notificationMarkAsRead(id));
      if (response.statusCode == 200 && response.data != null) {
        final resData = response.data['data'];
        if (resData is Map) {
          return NotificationModel.fromJson(Map<String, dynamic>.from(resData));
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
}

