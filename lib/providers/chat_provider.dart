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

  List<ChatMessageModel> get currentMessages =>
      activeConversation?.messages ?? [];

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
  ref.watch(authProvider.select((state) => state.user?.id));
  return ChatRepository();
});

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repo;
  int _generation = 0;
  bool _valid(int generation) => mounted && generation == _generation;
  ChatNotifier(this._repo) : super(const ChatState()) {
    loadConversations();
  }

  /// Tải danh sách các cuộc trò chuyện
  Future<void> loadConversations() async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true,
      isSending: false,
      isTyping: false,
      clearError: true,
    );
    try {
      final list = await _repo.getConversations();
      if (!_valid(generation)) return;
      state = state.copyWith(isLoading: false, conversations: list);

      // Nếu chưa có activeConversation và danh sách có dữ liệu, chọn cuộc trò chuyện gần nhất
      if (state.activeConversation == null && list.isNotEmpty) {
        await selectConversation(list.first.id);
      }
    } catch (e) {
      if (!_valid(generation)) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách cuộc trò chuyện: $e',
      );
    }
  }

  /// Chọn một cuộc trò chuyện để xem và chat
  Future<void> selectConversation(int conversationId) async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true,
      isSending: false,
      isTyping: false,
      clearError: true,
    );
    try {
      final conversation = await _repo.getConversation(conversationId);
      if (!_valid(generation)) return;
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
      if (!_valid(generation)) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi khi tải chi tiết cuộc trò chuyện: $e',
      );
    }
  }

  /// Khởi tạo cuộc trò chuyện mới
  Future<ChatConversationModel?> startNewConversation({
    String title = 'Cuộc trò chuyện mới',
  }) async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true,
      isSending: false,
      isTyping: false,
      clearError: true,
    );
    try {
      final created = await _repo.createConversation(title: title);
      if (!_valid(generation)) return null;
      final updatedList = [created, ...state.conversations];
      state = state.copyWith(
        isLoading: false,
        conversations: updatedList,
        activeConversation: created,
      );
      return created;
    } catch (e) {
      if (!_valid(generation)) return null;
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
    if (trimmed.isEmpty || state.isLoading || state.isSending || state.isTyping)
      return;
    final generation = ++_generation;
    state = state.copyWith(isSending: true, clearError: true);
    var accepted = false;
    try {
      var active = state.activeConversation;
      if (active == null) {
        active = await _repo.createConversation(
          title:
              trimmed.length > 30 ? '${trimmed.substring(0, 30)}...' : trimmed,
        );
        if (!_valid(generation)) return;
        state = state.copyWith(
          activeConversation: active,
          conversations: [active, ...state.conversations],
        );
      }
      final count = active.messages.length;
      final pending = ChatMessageModel(
        id: -1,
        role: 'user',
        content: trimmed,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(
        isTyping: true,
        activeConversation: active.copyWith(
          messages: [...active.messages, pending],
        ),
      );
      final sent = await _repo.sendMessage(
        conversationId: active.id,
        content: trimmed,
      );
      if (!_valid(generation)) return;
      accepted = true;
      state = state.copyWith(
        isSending: false,
        activeConversation: active.copyWith(
          messages: [...active.messages, sent],
        ),
      );
      final reply = await _repo.waitForAssistantReply(
        conversationId: active.id,
        initialMessageCount: count + 1,
      );
      if (!_valid(generation)) return;
      if (reply == null)
        throw StateError('Không tải được phản hồi AI. Vui lòng thử lại.');
      state = state.copyWith(
        isTyping: false,
        activeConversation: reply,
        conversations: state.conversations
            .map((c) => c.id == reply.id ? reply : c)
            .toList(),
        errorMessage: reply.messages.isNotEmpty && reply.messages.last.isError
            ? reply.messages.last.content
            : null,
      );
    } catch (error) {
      if (_valid(generation)) {
        state = state.copyWith(
          isSending: false,
          isTyping: false,
          activeConversation: !accepted && state.activeConversation != null
              ? state.activeConversation!.copyWith(
                  messages:
                      state.currentMessages.where((m) => m.id != -1).toList())
              : state.activeConversation,
          errorMessage: 'Không nhận được phản hồi AI: $error',
        );
      }
    }
  }

  /// Xóa cuộc trò chuyện
  Future<bool> deleteConversation(int conversationId) async {
    final generation = ++_generation;
    state = state.copyWith(isSending: false, isTyping: false);
    try {
      final success = await _repo.deleteConversation(conversationId);
      if (!_valid(generation)) return false;
      if (success) {
        final updatedList =
            state.conversations.where((c) => c.id != conversationId).toList();
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
      if (!_valid(generation)) return false;
      state = state.copyWith(errorMessage: 'Không thể xóa cuộc trò chuyện: $e');
    }
    return false;
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  ref.watch(authProvider.select((state) => state.user?.id));
  return ChatNotifier(repo);
});
