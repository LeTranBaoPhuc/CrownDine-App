import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/feedback_model.dart';
import '../data/repositories/feedback_repository.dart';
import 'auth_provider.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

final itemFeedbacksProvider = FutureProvider.family<List<FeedbackModel>, int>((ref, itemId) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getFeedbacksByItem(itemId);
});

final allFeedbacksProvider = FutureProvider<List<FeedbackModel>>((ref) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getAllFeedbacks();
});

class FeedbackController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  FeedbackController(this._ref) : super(const AsyncValue.data(null));

  Future<FeedbackModel?> submitFeedback({
    required int rating,
    required String comment,
    int? itemId,
    int? comboId,
    int? orderId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(feedbackRepositoryProvider);
      final currentUser = _ref.read(authProvider).user;

      final result = await repo.createFeedback(
        rating: rating,
        comment: comment,
        itemId: itemId,
        comboId: comboId,
        orderId: orderId,
        authorName: currentUser?.fullName ?? 'Thực khách CrownDine',
        authorAvatar: currentUser?.avatarUrl,
      );

      // Invalidate relevant providers to trigger UI refresh
      if (itemId != null) {
        _ref.invalidate(itemFeedbacksProvider(itemId));
      }
      _ref.invalidate(allFeedbacksProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final feedbackControllerProvider = StateNotifierProvider<FeedbackController, AsyncValue<void>>((ref) {
  return FeedbackController(ref);
});
