import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat_model.dart';
import '../data/repositories/chat_repository.dart';
import 'auth_provider.dart';

class ChatState {
  final bool isLoading;
  final bool isSending;
  final bool isTyping;
  final List<ChatConversationModel> conversations;
  final ChatConversationModel? activeConversation;
  final String? errorMessage;

  const ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.isTyping = false,
    this.conversations = const [],
    this.activeConversation,
    this.errorMessage,
  });

  List<ChatMessageModel> get currentMessages => activeConversation?.messages ?? [];

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    bool? isTyping,
    List<ChatConversationModel>? conversations,
    ChatConversationModel? activeConversation,
    bool clearActiveConversation = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isTyping: isTyping ?? this.isTyping,
      conversations: conversations ?? this.conversations,
      activeConversation: clearActiveConversation
          ? null
          : (activeConversation ?? this.activeConversation),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  final Ref _ref;

  ChatNotifier(this._repo, this._ref) : super(const ChatState()) {
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      loadConversations();
    }
    _ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated && (previous == null || !previous.isAuthenticated)) {
        loadConversations();
      } else if (!next.isAuthenticated) {
        state = const ChatState();
      }
    });
  }

  /// Tải danh sách các cuộc trò chuyện
  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getConversations();
      state = state.copyWith(
        isLoading: false,
        conversations: list,
      );

      // Nếu chưa có activeConversation và danh sách có dữ liệu, chọn cuộc trò chuyện gần nhất
      if (state.activeConversation == null && list.isNotEmpty) {
        await selectConversation(list.first.id);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách cuộc trò chuyện: $e',
      );
    }
  }

  /// Chọn một cuộc trò chuyện để xem và chat
  Future<void> selectConversation(int conversationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conversation = await _repo.getConversation(conversationId);
      if (conversation != null) {
        state = state.copyWith(
          isLoading: false,
          activeConversation: conversation,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Không tìm thấy cuộc trò chuyện',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải chi tiết cuộc trò chuyện: $e',
      );
    }
  }

  /// Khởi tạo cuộc trò chuyện mới
  Future<ChatConversationModel?> startNewConversation({String title = 'Cuộc trò chuyện mới'}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final created = await _repo.createConversation(title: title);
      final updatedList = [created, ...state.conversations];
      state = state.copyWith(
        isLoading: false,
        conversations: updatedList,
        activeConversation: created,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tạo cuộc trò chuyện: $e',
      );
      return null;
    }
  }

  /// Gửi tin nhắn tới AI và đợi câu trả lời
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // 1. Tạo conversation mới nếu chưa có
    ChatConversationModel? active = state.activeConversation;
    if (active == null) {
      active = await startNewConversation(
        title: trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed,
      );
      if (active == null) return;
    }

    final conversationId = active.id;
    final initialCount = active.messages.length;

    // 2. Optimistic update: Thêm ngay tin nhắn người dùng vào UI
    final tempUserMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    final updatedMessages = [...active.messages, tempUserMsg];
    final optimisticConversation = active.copyWith(messages: updatedMessages);

    state = state.copyWith(
      activeConversation: optimisticConversation,
      isSending: true,
      isTyping: true,
      clearError: true,
    );

    try {
      // 3. Gửi message lên backend
      await _repo.sendMessage(
        conversationId: conversationId,
        content: trimmed,
      );

      state = state.copyWith(isSending: false);

      // 4. Poll đợi AI phản hồi
      final updatedConv = await _repo.waitForAssistantReply(
        conversationId: conversationId,
        initialMessageCount: initialCount + 1,
      );

      if (updatedConv != null) {
        // Cập nhật cuộc trò chuyện và danh sách
        final updatedList = state.conversations.map((c) {
          if (c.id == updatedConv.id) return updatedConv;
          return c;
        }).toList();

        state = state.copyWith(
          isTyping: false,
          activeConversation: updatedConv,
          conversations: updatedList,
        );
      } else {
        state = state.copyWith(isTyping: false);
      }
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        isTyping: false,
        errorMessage: 'Gửi tin nhắn thất bại: $e',
      );
    }
  }

  /// Xóa cuộc trò chuyện
  Future<bool> deleteConversation(int conversationId) async {
    try {
      final success = await _repo.deleteConversation(conversationId);
      if (success) {
        final updatedList = state.conversations.where((c) => c.id != conversationId).toList();
        ChatConversationModel? nextActive;
        if (state.activeConversation?.id == conversationId) {
          nextActive = updatedList.isNotEmpty ? updatedList.first : null;
        } else {
          nextActive = state.activeConversation;
        }

        state = state.copyWith(
          conversations: updatedList,
          activeConversation: nextActive,
          clearActiveConversation: nextActive == null,
        );

        if (nextActive != null) {
          await selectConversation(nextActive.id);
        }
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Không thể xóa cuộc trò chuyện: $e',
      );
    }
    return false;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repo, ref);
});

