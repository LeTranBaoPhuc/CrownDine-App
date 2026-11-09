import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/chat_model.dart';
import '../../../../data/models/table_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/chat_provider.dart';
import '../../../../providers/reservation_checkout_provider.dart';
import '../../../../providers/reservation_provider.dart';
import '../../../../providers/table_provider.dart';
import '../customer_main_screen.dart';

class CustomerChatScreen extends ConsumerStatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  ConsumerState<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _ReservationIntent {
  final int step;
  final String tableName;
  final String dateStr;
  final String startTime;
  final int guests;

  const _ReservationIntent({
    required this.step,
    required this.tableName,
    required this.dateStr,
    required this.startTime,
    required this.guests,
  });

  static String _cleanVal(String? val) {
    if (val == null) return '';
    return val
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
  }

  static _ReservationIntent? tryParse(String content) {
    final match = RegExp(r'/reservation\?([^\s\n\r]+)').firstMatch(content);
    if (match == null) return null;
    try {
      final queryPart = match.group(1)!;
      final uri = Uri.parse('https://app.crowndine.vn/reservation?$queryPart');
      final params = uri.queryParameters;
      final step = int.tryParse(params['step'] ?? '3') ?? 3;
      final tableName = _cleanVal(params['tableName']);
      final dateStr = _cleanVal(params['date']);
      final startTime = _cleanVal(params['startTime']);
      final rawGuests = _cleanVal(params['guests']).replaceAll(RegExp(r'[^0-9]'), '');
      final guests = int.tryParse(rawGuests) ?? 2;

      if (tableName.isEmpty && dateStr.isEmpty) return null;
      return _ReservationIntent(
        step: step,
        tableName: tableName,
        dateStr: dateStr,
        startTime: startTime,
        guests: guests,
      );
    } catch (_) {
      return null;
    }
  }

  static String cleanContent(String content) {
    return content.replaceAll(RegExp(r'/reservation\?[^\s\n\r]+'), '').trim();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ReservationIntent &&
          runtimeType == other.runtimeType &&
          step == other.step &&
          tableName == other.tableName &&
          dateStr == other.dateStr &&
          startTime == other.startTime &&
          guests == other.guests;

  @override
  int get hashCode =>
      step.hashCode ^
      tableName.hashCode ^
      dateStr.hashCode ^
      startTime.hashCode ^
      guests.hashCode;
}

class _QuickPromptItem {
  final IconData icon;
  final String text;
  const _QuickPromptItem(this.icon, this.text);
}

class _CustomerChatScreenState extends ConsumerState<CustomerChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  _ReservationIntent? _lastHandledIntent;

  final List<_QuickPromptItem> _quickPrompts = const [
    _QuickPromptItem(Icons.restaurant_menu_rounded, 'Xem thực đơn hôm nay'),
    _QuickPromptItem(Icons.table_restaurant_rounded, 'Đặt bàn 4 người vào tối mai'),
    _QuickPromptItem(Icons.auto_awesome_rounded, 'Gợi ý các món bò và combo đặc sắc'),
    _QuickPromptItem(Icons.access_time_rounded, 'Giờ mở cửa và chính sách đặt bàn'),
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuad,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  void _handleSendMessage([String? overrideText]) {
    final text = overrideText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (overrideText == null) {
      _textController.clear();
    }
    _focusNode.unfocus();

    ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _executeReservationNavigation(_ReservationIntent intent) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 12),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Đang chuẩn bị thông tin đặt bàn...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 1. Phân tích ngày đặt bàn
      DateTime targetDate;
      try {
        targetDate = DateTime.parse(intent.dateStr);
      } catch (_) {
        targetDate = DateTime.now();
      }

      // 2. Tải danh sách bàn nếu chưa có
      var tableState = ref.read(tableProvider);
      if (tableState.allTables.isEmpty) {
        await ref.read(tableProvider.notifier).loadLayout();
        tableState = ref.read(tableProvider);
      }

      // 3. Khớp bàn theo tên bàn
      TableModel? matched;
      final searchName = intent.tableName.trim().toLowerCase();
      for (final t in tableState.allTables) {
        if (t.name.trim().toLowerCase() == searchName) {
          matched = t;
          break;
        }
      }
      if (matched == null) {
        for (final t in tableState.allTables) {
          if (t.name.toLowerCase().contains(searchName) ||
              searchName.contains(t.name.toLowerCase())) {
            matched = t;
            break;
          }
        }
      }
      matched ??= tableState.allTables.isNotEmpty
          ? tableState.allTables.first
          : TableModel(
              id: 1,
              name: intent.tableName.isNotEmpty ? intent.tableName : 'SC-1',
              capacity: intent.guests,
              deposit: 100000.0,
              status: TableStatus.available,
            );

      // 4. Cập nhật state đặt bàn
      final notifier = ref.read(reservationProvider.notifier);
      notifier.setDateTime(date: targetDate, time: intent.startTime);
      notifier.setGuests(intent.guests);
      notifier.selectTable(matched);

      int targetStep = intent.step;
      final authState = ref.read(authProvider);

      if (targetStep == 4 && authState.isAuthenticated) {
        ref.read(checkoutReservationIdProvider.notifier).state = null;
        final ready = await notifier.prepareCheckout();
        if (ready) {
          ref.read(checkoutReservationIdProvider.notifier).state =
              ref.read(reservationProvider).backendReservationId;
        } else {
          targetStep = 3;
        }
      } else if (targetStep == 4 && !authState.isAuthenticated) {
        targetStep = 3;
      }

      notifier.setStep(targetStep);

      if (mounted) {
        Navigator.of(context).pop(); // Đóng loading dialog
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const CustomerMainScreen(initialIndex: 2),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chuyển đến đặt bàn: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildBrandAvatar({double size = 36}) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.restaurant_rounded,
          color: AppColors.primary,
          size: size * 0.55,
        ),
      ),
    );
  }

  void _showHistorySheet(BuildContext context, ChatState chatState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            final conversations = chatState.conversations;
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch sử trò chuyện',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textLight : AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(chatProvider.notifier).startNewConversation();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Đoạn chat mới'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: conversations.isEmpty
                      ? Center(
                          child: Text(
                            'Chưa có lịch sử trò chuyện',
                            style: TextStyle(
                              color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: conversations.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            final isActive = conv.id == chatState.activeConversation?.id;

                            return ListTile(
                              selected: isActive,
                              selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isActive
                                    ? AppColors.primary
                                    : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
                                child: Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                  color: isActive
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                                ),
                              ),
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  color: isDark ? AppColors.textLight : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                conv.updatedAt != null
                                    ? '${conv.updatedAt!.day}/${conv.updatedAt!.month}/${conv.updatedAt!.year} ${conv.updatedAt!.hour.toString().padLeft(2, '0')}:${conv.updatedAt!.minute.toString().padLeft(2, '0')}'
                                    : 'Vừa xong',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (dCtx) => AlertDialog(
                                      title: const Text('Xóa cuộc trò chuyện?'),
                                      content: const Text('Nội dung cuộc trò chuyện này sẽ bị xóa vĩnh viễn.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx, false),
                                          child: const Text('Hủy'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.error,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () => Navigator.pop(dCtx, true),
                                          child: const Text('Xóa'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    ref.read(chatProvider.notifier).deleteConversation(conv.id);
                                  }
                                },
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                ref.read(chatProvider.notifier).selectConversation(conv.id);
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Lắng nghe cập nhật tin nhắn và phát hiện ý định chuyển bước đặt bàn
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous?.currentMessages.length != next.currentMessages.length ||
          previous?.isTyping != next.isTyping) {
        _scrollToBottom();
      }

      // Khi trợ lý phản hồi xong câu có chứa link đặt bàn, tự động chuyển trang sau 1 giây
      if (previous?.isTyping == true && !next.isTyping && next.currentMessages.isNotEmpty) {
        final lastMsg = next.currentMessages.last;
        if (!lastMsg.isUser) {
          final intent = _ReservationIntent.tryParse(lastMsg.content);
          if (intent != null && intent != _lastHandledIntent) {
            _lastHandledIntent = intent;
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                _executeReservationNavigation(intent);
              }
            });
          }
        }
      }
    });

    final messages = chatState.currentMessages;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _buildBrandAvatar(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trợ lý CrownDine',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textLight : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Trực tuyến',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tạo cuộc trò chuyện mới',
                    icon: const Icon(Icons.add_comment_rounded, size: 20),
                    onPressed: () {
                      ref.read(chatProvider.notifier).startNewConversation();
                    },
                  ),
                  IconButton(
                    tooltip: 'Lịch sử trò chuyện',
                    icon: const Icon(Icons.history_rounded, size: 22),
                    onPressed: () => _showHistorySheet(context, chatState),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Error Banner if any
          if (chatState.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.errorContainer,
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                    onPressed: () => ref.read(chatProvider.notifier).loadConversations(),
                  ),
                ],
              ),
            ),

          // Message Body
          Expanded(
            child: chatState.isLoading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : messages.isEmpty
                    ? _buildEmptyWelcome(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: messages.length + (chatState.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length && chatState.isTyping) {
                            return _buildTypingIndicator(isDark);
                          }
                          final message = messages[index];
                          return _buildMessageBubble(message, isDark);
                        },
                      ),
          ),

          // Bottom Input Bar
          _buildInputBar(isDark, chatState.isSending || chatState.isTyping),
        ],
      ),
    );
  }

  Widget _buildEmptyWelcome(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildBrandAvatar(size: 72),
          const SizedBox(height: 16),
          Text(
            'Nhà hàng CrownDine',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textLight : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Xin chào quý khách! Tôi là trợ lý hỗ trợ trực tuyến của CrownDine. Quý khách có thể hỏi về thực đơn món ăn, kiểm tra bàn trống hoặc đặt bàn nhanh chóng ngay tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'GỢI Ý CÂU HỎI:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickPrompts.map((prompt) {
              return InkWell(
                onTap: () => _handleSendMessage(prompt.text),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(prompt.icon, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        prompt.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textLight : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isDark) {
    final isUser = message.isUser;
    final intent = !isUser ? _ReservationIntent.tryParse(message.content) : null;
    final displayContent = intent != null
        ? _ReservationIntent.cleanContent(message.content)
        : message.content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2),
              child: _buildBrandAvatar(size: 30),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isUser ? 0.08 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (displayContent.isNotEmpty)
                    SelectableText(
                      displayContent,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: isUser
                            ? Colors.white
                            : (isDark ? AppColors.textLight : AppColors.textPrimary),
                      ),
                    ),

                  // Thẻ xác nhận đặt bàn tương tác trực tiếp
                  if (intent != null) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.table_restaurant_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'XÁC NHẬN ĐẶT BÀN',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Bàn: ${intent.tableName} (${intent.guests} khách)\n• Thời gian: ${intent.startTime} · ${intent.dateStr}',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textLight : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _executeReservationNavigation(intent),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                intent.step == 4 ? Icons.payment_rounded : Icons.restaurant_menu_rounded,
                                size: 18,
                              ),
                              label: Text(
                                intent.step == 4 ? 'Chuyển đến thanh toán đặt cọc' : 'Chuyển đến bước đặt món',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 4),
                  Text(
                    message.createdAt != null
                        ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
                        : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white70
                          : (isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 2),
            child: _buildBrandAvatar(size: 30),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'CrownDine đang soạn tin nhắn...',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDark, bool isBusy) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.send,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: isBusy ? null : (_) => _handleSendMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập câu hỏi hoặc yêu cầu đặt bàn...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                onPressed: isBusy ? null : () => _handleSendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
