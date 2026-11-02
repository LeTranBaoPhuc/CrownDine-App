import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/feedback_model.dart';
import '../data/repositories/feedback_repository.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

final allFeedbacksProvider = FutureProvider<List<FeedbackModel>>((ref) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getAllFeedbacks();
});

final itemFeedbacksProvider = FutureProvider.family<List<FeedbackModel>, int>((ref, itemId) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getFeedbacksByItem(itemId);
});

final comboFeedbacksProvider = FutureProvider.family<List<FeedbackModel>, int>((ref, comboId) async {
  final repo = ref.watch(feedbackRepositoryProvider);
  return repo.getFeedbacksByCombo(comboId);
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
    int? orderDetailId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(feedbackRepositoryProvider);

      final result = await repo.createFeedback(
        rating: rating,
        comment: comment,
        itemId: itemId,
        comboId: comboId,
        orderId: orderId,
        orderDetailId: orderDetailId,
      );

      // Invalidate relevant providers to trigger UI refresh
      if (itemId != null) {
        _ref.invalidate(itemFeedbacksProvider(itemId));
      }
      if (comboId != null) {
        _ref.invalidate(comboFeedbacksProvider(comboId));
      }
      _ref.invalidate(allFeedbacksProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<FeedbackModel?> editFeedback({
    required int id,
    required int rating,
    required String comment,
    int? itemId,
    int? comboId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(feedbackRepositoryProvider);

      final result = await repo.updateFeedback(
        id: id,
        rating: rating,
        comment: comment,
      );

      if (itemId != null) {
        _ref.invalidate(itemFeedbacksProvider(itemId));
      }
      if (comboId != null) {
        _ref.invalidate(comboFeedbacksProvider(comboId));
      }
      _ref.invalidate(allFeedbacksProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final feedbackControllerProvider = StateNotifierProvider<FeedbackController, AsyncValue<void>>((ref) {
  return FeedbackController(ref);
});
