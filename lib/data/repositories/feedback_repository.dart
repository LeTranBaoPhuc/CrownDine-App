import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/feedback_model.dart';

class FeedbackRepository {
  final ApiClient _client = ApiClient.instance;

  Future<List<FeedbackModel>> getFeedbacksByItem(int itemId) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.feedbacksByItem(itemId));
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null && list.isNotEmpty) {
          return list.map((e) => FeedbackModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Filter from MockData.feedbacks
    final itemFeedbacks = MockData.feedbacks.where((f) => f.itemId == itemId).toList();
    if (itemFeedbacks.isNotEmpty) {
      return itemFeedbacks;
    }
    // Return sample feedbacks so the customer always sees reviews
    return MockData.feedbacks;
  }

  Future<List<FeedbackModel>> getAllFeedbacks() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.feedbacks);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null && list.isNotEmpty) {
          return list.map((e) => FeedbackModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return List<FeedbackModel>.from(MockData.feedbacks);
  }

  Future<FeedbackModel> createFeedback({
    required int rating,
    required String comment,
    int? itemId,
    int? comboId,
    int? orderId,
    String? authorName,
    String? authorAvatar,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();
    final body = {
      'rating': rating,
      'comment': comment,
      if (itemId != null) 'itemId': itemId,
      if (comboId != null) 'comboId': comboId,
      if (orderId != null) 'orderId': orderId,
    };

    try {
      final response = await _client.dio.post(ApiEndpoints.feedbacks, data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        return FeedbackModel.fromJson(data);
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Mock fallback creation
    final newFeedback = FeedbackModel(
      id: DateTime.now().millisecondsSinceEpoch,
      rating: rating,
      comment: comment,
      fullName: authorName ?? 'Thực khách CrownDine',
      avatarUrl: authorAvatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80',
      createdAt: 'Vừa xong',
      itemId: itemId,
    );
    MockData.feedbacks.insert(0, newFeedback);
    return newFeedback;
  }
}
