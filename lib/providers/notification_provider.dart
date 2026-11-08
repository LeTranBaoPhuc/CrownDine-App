import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_model.dart';
import '../data/repositories/notification_repository.dart';
import 'auth_provider.dart';

class NotificationState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;
  final Ref _ref;

  NotificationNotifier(this._repo, this._ref)
      : super(const NotificationState()) {
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated) {
      loadNotifications();
    }
  }

  Future<void> loadNotifications() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) {
      state = const NotificationState();
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([
        _repo.getMyNotifications(page: 1, size: 50),
        _repo.getUnreadCount(),
      ]);

      if (!mounted) return;
      final notifs = results[0] as List<NotificationModel>;
      final unread = results[1] as int;

      state = state.copyWith(
        isLoading: false,
        notifications: notifs,
        unreadCount: unread,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông báo: $e',
      );
    }
  }

  Future<void> loadUnreadCount() async {
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    try {
      final unread = await _repo.getUnreadCount();
      if (mounted) state = state.copyWith(unreadCount: unread);
    } catch (_) {}
  }

  Future<void> markAsRead(int notificationId) async {
    final target = state.notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => NotificationModel(
        id: notificationId,
        type: '',
        title: '',
        message: '',
        createdAt: DateTime.now(),
      ),
    );

    // If already read, skip
    if (target.isRead) return;

    // Optimistic UI update
    final updatedList = state.notifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(readAt: DateTime.now());
      }
      return n;
    }).toList();

    final newUnread = (state.unreadCount > 0) ? state.unreadCount - 1 : 0;
    state = state.copyWith(notifications: updatedList, unreadCount: newUnread);

    try {
      await _repo.markAsRead(notificationId);
    } catch (_) {
      // Refresh to synchronize
      loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final unreadNotifs = state.notifications.where((n) => !n.isRead).toList();
    if (unreadNotifs.isEmpty) return;

    final updatedList = state.notifications.map((n) {
      return n.copyWith(readAt: DateTime.now());
    }).toList();
    state = state.copyWith(notifications: updatedList, unreadCount: 0);

    for (final notif in unreadNotifs) {
      try {
        await _repo.markAsRead(notif.id);
      } catch (_) {}
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repo, ref);
});
