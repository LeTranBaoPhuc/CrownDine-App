import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/feedback_model.dart';

class FeedbackRepository {
  final ApiClient _client = ApiClient.instance;

  /// Lấy danh sách tất cả đánh giá & phản hồi (sắp xếp mới nhất)
  Future<List<FeedbackModel>> getAllFeedbacks() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.feedbacks);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null) {
          return list.map((e) => FeedbackModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Lấy danh sách đánh giá của món ăn theo itemId
  Future<List<FeedbackModel>> getFeedbacksByItem(int itemId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.feedbacksByItem(itemId));
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null) {
          return list.map((e) => FeedbackModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Lấy danh sách đánh giá của combo theo comboId
  Future<List<FeedbackModel>> getFeedbacksByCombo(int comboId) async {
    try {
      final response = await _client.dio.get(ApiEndpoints.feedbacksByCombo(comboId));
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null) {
          return list.map((e) => FeedbackModel.fromJson(Map<String, dynamic>.from(e))).toList();
        }
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  /// Gửi đánh giá mới (POST /api/feedbacks)
  Future<FeedbackModel> createFeedback({
    required int rating,
    required String comment,
    int? itemId,
    int? comboId,
    int? orderId,
    int? orderDetailId,
  }) async {
    final body = <String, dynamic>{
      'rating': rating,
      'comment': comment,
      if (itemId != null) 'itemId': itemId,
      if (comboId != null) 'comboId': comboId,
      if (orderId != null) 'orderId': orderId,
      if (orderDetailId != null) 'orderDetailId': orderDetailId,
    };

    try {
      final response = await _client.dio.post(ApiEndpoints.feedbacks, data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          return FeedbackModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
      throw Exception('Không nhận được phản hồi hợp lệ từ máy chủ');
    } on DioException catch (dioErr) {
      final serverMessage = dioErr.response?.data?['message']?.toString();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        throw Exception(serverMessage);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Cập nhật đánh giá trong vòng 24 giờ (PUT /api/feedbacks/{id})
  Future<FeedbackModel> updateFeedback({
    required int id,
    required int rating,
    required String comment,
  }) async {
    final body = {
      'rating': rating,
      'comment': comment,
    };

    try {
      final response = await _client.dio.put('${ApiEndpoints.feedbacks}/$id', data: body);
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is Map) {
          return FeedbackModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
      throw Exception('Không nhận được phản hồi hợp lệ từ máy chủ');
    } on DioException catch (dioErr) {
      final serverMessage = dioErr.response?.data?['message']?.toString();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        throw Exception(serverMessage);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
