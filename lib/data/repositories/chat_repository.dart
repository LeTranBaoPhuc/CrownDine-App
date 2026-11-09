import 'package:dio/dio.dart';
import 'dart:async';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/chat_model.dart';

class ChatRepository {
  final Dio _dio;
  ChatRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  final Map<int, String> _guestTokens = {};
  Options _access(int id) => Options(
        headers: {
          if (_guestTokens[id] != null) 'X-Chat-Token': _guestTokens[id]
        },
      );

  /// Lấy danh sách tất cả các cuộc trò chuyện của user
  Future<List<ChatConversationModel>> getConversations() async {
    try {
      final response = await _dio.get(ApiEndpoints.chatConversations);
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'] ?? response.data;
        if (rawData is List) {
          return rawData
              .map(
                (e) => ChatConversationModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Lấy chi tiết một cuộc trò chuyện (bao gồm danh sách tin nhắn)
  Future<ChatConversationModel?> getConversation(int conversationId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.chatConversationById(conversationId),
        options: _access(conversationId),
      );
      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'] ?? response.data;
        if (rawData is Map) {
          return ChatConversationModel.fromJson(
            Map<String, dynamic>.from(rawData),
          );
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Tạo cuộc trò chuyện mới
  Future<ChatConversationModel> createConversation({
    String title = 'Cuộc trò chuyện mới',
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.chatConversations,
        data: {'title': title},
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final rawData = response.data['data'] ?? response.data;
        if (rawData is Map) {
          final conversation = ChatConversationModel.fromJson(
            Map<String, dynamic>.from(rawData),
          );
          final token = rawData['guestAccessToken'];
          if (token is String && token.isNotEmpty)
            _guestTokens[conversation.id] = token;
          return conversation;
        }
      }
      throw Exception('Không thể tạo cuộc trò chuyện mới');
    } catch (e) {
      rethrow;
    }
  }

  /// Gửi tin nhắn và nhận lại tin nhắn của user
  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.chatMessages,
        options: _access(conversationId),
        data: {'conversationId': conversationId, 'content': content},
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final rawData = response.data['data'] ?? response.data;
        if (rawData is Map) {
          return ChatMessageModel.fromJson(Map<String, dynamic>.from(rawData));
        }
      }
      throw Exception('Không thể gửi tin nhắn');
    } catch (e) {
      rethrow;
    }
  }

  /// Xóa cuộc trò chuyện
  Future<bool> deleteConversation(int conversationId) async {
    try {
      final response = await _dio.delete(
        ApiEndpoints.chatConversationById(conversationId),
        options: _access(conversationId),
      );
      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) _guestTokens.remove(conversationId);
      return success;
    } catch (e) {
      rethrow;
    }
  }

  /// Đợi phản hồi của AI bằng cách poll cuộc trò chuyện
  Future<ChatConversationModel?> waitForAssistantReply({
    required int conversationId,
    required int initialMessageCount,
    Duration pollInterval = const Duration(milliseconds: 1500),
    int maxAttempts = 25,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(pollInterval);
      final conversation = await getConversation(conversationId);
      if (conversation != null &&
          conversation.messages.length > initialMessageCount) {
        final lastMsg = conversation.messages.last;
        if (lastMsg.isAssistant || lastMsg.isError) {
          return conversation;
        }
      }
    }
    throw TimeoutException(
      'AI phản hồi quá lâu. Vui lòng tải lại hội thoại hoặc thử lại sau.',
    );
  }
}
