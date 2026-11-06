import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/repositories/reservation_booking_repository.dart';
import 'reservation_checkout_provider.dart';
import 'auth_provider.dart';
import '../data/storage/payment_attempt_store.dart';
import '../data/models/item_model.dart';
import '../data/models/reservation_model.dart';
import '../data/models/table_model.dart';
import '../data/repositories/reservation_repository.dart';

final reservationRepositoryProvider =
    Provider<ReservationRepository>((ref) => ReservationRepository());

final reservationBookingRepositoryProvider =
    Provider((ref) => ReservationBookingRepository());

class ReservationFormState {
  final int? backendReservationId;
  final bool creationUncertain;
  final int currentStep; // 1, 2, 3, 4
  final DateTime selectedDate;
  final String selectedTime;
  final int guestNumber;
  final TableModel? selectedTable;
  final List<CartItemModel> preOrderItems;
  final String guestName;
  final String guestPhone;
  final String note;
  final bool isSubmitting;
  final String? errorMessage;

  ReservationFormState({
    this.backendReservationId,
    this.creationUncertain = false,
    this.currentStep = 1,
    DateTime? selectedDate,
    this.selectedTime = '19:00',
    this.guestNumber = 2,
    this.selectedTable,
    this.preOrderItems = const [],
    this.guestName = '',
    this.guestPhone = '',
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
  }) : selectedDate =
            selectedDate ?? DateTime.now().add(const Duration(days: 1));

  double get foodSubtotal =>
      preOrderItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  ReservationFormState copyWith({
    int? backendReservationId,
    bool clearBackendReservation = false,
    bool? creationUncertain,
    int? currentStep,
    DateTime? selectedDate,
    String? selectedTime,
    int? guestNumber,
    TableModel? Function()? selectedTable,
    List<CartItemModel>? preOrderItems,
    String? guestName,
    String? guestPhone,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return ReservationFormState(
      backendReservationId: clearBackendReservation
          ? null
          : backendReservationId ?? this.backendReservationId,
      creationUncertain: creationUncertain ?? this.creationUncertain,
      currentStep: currentStep ?? this.currentStep,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      guestNumber: guestNumber ?? this.guestNumber,
      selectedTable:
          selectedTable != null ? selectedTable() : this.selectedTable,
      preOrderItems: preOrderItems ?? this.preOrderItems,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class ReservationNotifier extends StateNotifier<ReservationFormState> {
  final ReservationBookingRepository _booking;
  final PaymentAttemptStore? _paymentStore;

  ReservationNotifier(ReservationRepository repo,
      {ReservationBookingRepository? booking,
      PaymentAttemptStore? paymentStore})
      : _paymentStore = paymentStore,
        _booking = booking ?? ReservationBookingRepository(),
        super(ReservationFormState());

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setDateTime({DateTime? date, String? time}) {
    if (state.isSubmitting || state.backendReservationId != null) return;
    state = state.copyWith(
      selectedDate: date ?? state.selectedDate,
      selectedTime: time ?? state.selectedTime,
    );
  }

  void setGuests(int guests) {
    if (state.isSubmitting || state.backendReservationId != null) return;
    state = state.copyWith(guestNumber: guests);
  }

  void selectTable(TableModel table) {
    if (state.isSubmitting || state.backendReservationId != null) return;
    state = state.copyWith(selectedTable: () => table);
  }

  void addPreOrderItem(ItemModel item) {
    if (state.isSubmitting || !item.isAvailable) return;
    final list = List<CartItemModel>.from(state.preOrderItems);
    final idx = list.indexWhere(
        (i) => i.item.id == item.id && i.item.isCombo == item.isCombo);
    if (idx != -1) {
      final old = list[idx];
      list[idx] = CartItemModel(
          item: old.item, quantity: old.quantity + 1, note: old.note);
    } else {
      list.add(CartItemModel(item: item, quantity: 1));
    }
    state = state.copyWith(preOrderItems: list);
  }

  void updatePreOrderItemQuantity(int itemId, int qty, {bool isCombo = false}) {
    if (state.isSubmitting) return;
    if (qty <= 0) {
      final list = state.preOrderItems
          .where((i) => i.item.id != itemId || i.item.isCombo != isCombo)
          .toList();
      state = state.copyWith(preOrderItems: list);
    } else {
      final list = List<CartItemModel>.from(state.preOrderItems);
      final idx = list
          .indexWhere((i) => i.item.id == itemId && i.item.isCombo == isCombo);
      if (idx != -1) {
        final old = list[idx];
        list[idx] =
            CartItemModel(item: old.item, quantity: qty, note: old.note);
        state = state.copyWith(preOrderItems: list);
      }
    }
  }

  void setCustomerInfo(
      {required String name, required String phone, String? note}) {
    state = state.copyWith(
      guestName: name,
      guestPhone: phone,
      note: note ?? state.note,
    );
  }

  Future<bool> prepareCheckout() async {
    if (state.isSubmitting || state.creationUncertain) return false;
    if (state.selectedTable == null) {
      state = state.copyWith(errorMessage: 'Vui lòng chọn bàn.');
      return false;
    }
    state = state.copyWith(isSubmitting: true);
    var creating = false;
    try {
      var id = state.backendReservationId;
      if (id == null) {
        await _booking.verifyTable(state.selectedTable!);
        creating = true;
        id = await _booking.create(
          date: state.selectedDate.toIso8601String().split('T').first,
          time: state.selectedTime,
          guests: state.guestNumber,
          tableId: state.selectedTable!.id,
          note: state.note,
        );
        if (!mounted) return false;
        state = state.copyWith(backendReservationId: id);
        creating = false;
      }
      if (await _paymentStore?.read(id) != null) {
        if (!mounted) return false;
        state = state.copyWith(
            isSubmitting: false,
            currentStep: 4,
            errorMessage:
                'Đặt bàn này đã có giao dịch đang xử lý. Kiểm tra thanh toán trước khi thay đổi món.');
        return true;
      }
      final items = state.preOrderItems
          .map((e) =>
              CartItemModel(item: e.item, quantity: e.quantity, note: e.note))
          .toList();
      await _booking.syncItems(id, items);
      if (!mounted) return false;
      state = state.copyWith(isSubmitting: false, currentStep: 4);
      return true;
    } catch (error) {
      if (!mounted) return false;
      final status = error is DioException ? error.response?.statusCode : null;
      final uncertain = creating && (status == null || status >= 500);
      state = state.copyWith(
          isSubmitting: false,
          creationUncertain: uncertain,
          errorMessage: uncertain
              ? 'Chưa xác định được kết quả đặt bàn. Vui lòng kiểm tra lịch sử hoặc liên hệ nhà hàng trước khi đặt lại.'
              : checkoutError(error));
      return false;
    }
  }

  Future<bool> releaseHeldReservation() async {
    if (state.isSubmitting || state.creationUncertain) return false;
    final id = state.backendReservationId;
    if (id == null) return true;
    state = state.copyWith(isSubmitting: true);
    try {
      if (await _paymentStore?.read(id) != null) {
        throw StateError(
            'Đặt bàn đã có giao dịch thanh toán. Vui lòng kiểm tra kết quả trước khi hủy.');
      }
      await _booking.cancel(id);
      if (!mounted) return false;
      state =
          state.copyWith(clearBackendReservation: true, isSubmitting: false);
      return true;
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
            isSubmitting: false, errorMessage: checkoutError(error));
      }
      return false;
    }
  }

  // Kept for callers using the old notifier entry point; now real API only.
  Future<bool> submitReservation() => prepareCheckout();

  void reset() {
    state = ReservationFormState();
  }
}

final reservationProvider =
    StateNotifierProvider<ReservationNotifier, ReservationFormState>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  final repo = ref.watch(reservationRepositoryProvider);
  return ReservationNotifier(repo,
      booking: ref.watch(reservationBookingRepositoryProvider),
      paymentStore: userId == null ? null : PaymentAttemptStore(userId));
});

final reservationHistoryProvider =
    FutureProvider<List<ReservationModel>>((ref) async {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  if (userId == null) return [];
  final repo = ref.watch(reservationRepositoryProvider);
  return repo.getReservationHistory();
});
