import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/item_model.dart';
import '../data/models/reservation_model.dart';
import '../data/models/table_model.dart';
import '../data/models/voucher_model.dart';
import '../data/repositories/reservation_repository.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) => ReservationRepository());

class ReservationFormState {
  final int currentStep; // 1, 2, 3, 4
  final DateTime selectedDate;
  final String selectedTime;
  final int guestNumber;
  final TableModel? selectedTable;
  final List<CartItemModel> preOrderItems;
  final VoucherModel? appliedVoucher;
  final String guestName;
  final String guestPhone;
  final String note;
  final bool isSubmitting;
  final String? errorMessage;
  final ReservationModel? completedReservation;

  ReservationFormState({
    this.currentStep = 1,
    DateTime? selectedDate,
    this.selectedTime = '19:00',
    this.guestNumber = 2,
    this.selectedTable,
    this.preOrderItems = const [],
    this.appliedVoucher,
    this.guestName = '',
    this.guestPhone = '',
    this.note = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.completedReservation,
  }) : selectedDate = selectedDate ?? DateTime.now().add(const Duration(days: 1));

  double get tableDeposit => selectedTable?.deposit ?? 100000.0;
  double get foodSubtotal => preOrderItems.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get totalBeforeDiscount => tableDeposit + foodSubtotal;

  double get discountAmount {
    if (appliedVoucher == null) return 0.0;
    final discount = (totalBeforeDiscount * appliedVoucher!.discountPercent) / 100;
    if (appliedVoucher!.maxDiscount != null && discount > appliedVoucher!.maxDiscount!) {
      return appliedVoucher!.maxDiscount!;
    }
    return discount;
  }

  double get finalAmount => (totalBeforeDiscount - discountAmount).clamp(0.0, double.infinity);

  ReservationFormState copyWith({
    int? currentStep,
    DateTime? selectedDate,
    String? selectedTime,
    int? guestNumber,
    TableModel? Function()? selectedTable,
    List<CartItemModel>? preOrderItems,
    VoucherModel? Function()? appliedVoucher,
    String? guestName,
    String? guestPhone,
    String? note,
    bool? isSubmitting,
    String? errorMessage,
    ReservationModel? Function()? completedReservation,
  }) {
    return ReservationFormState(
      currentStep: currentStep ?? this.currentStep,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      guestNumber: guestNumber ?? this.guestNumber,
      selectedTable: selectedTable != null ? selectedTable() : this.selectedTable,
      preOrderItems: preOrderItems ?? this.preOrderItems,
      appliedVoucher: appliedVoucher != null ? appliedVoucher() : this.appliedVoucher,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      note: note ?? this.note,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      completedReservation: completedReservation != null ? completedReservation() : this.completedReservation,
    );
  }
}

class ReservationNotifier extends StateNotifier<ReservationFormState> {
  final ReservationRepository _repo;

  ReservationNotifier(this._repo) : super(ReservationFormState());

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
    state = state.copyWith(
      selectedDate: date ?? state.selectedDate,
      selectedTime: time ?? state.selectedTime,
    );
  }

  void setGuests(int guests) {
    state = state.copyWith(guestNumber: guests);
  }

  void selectTable(TableModel table) {
    state = state.copyWith(selectedTable: () => table);
  }

  void addPreOrderItem(ItemModel item) {
    final list = List<CartItemModel>.from(state.preOrderItems);
    final idx = list.indexWhere((i) => i.item.id == item.id);
    if (idx != -1) {
      list[idx].quantity += 1;
    } else {
      list.add(CartItemModel(item: item, quantity: 1));
    }
    state = state.copyWith(preOrderItems: list);
  }

  void updatePreOrderItemQuantity(int itemId, int qty) {
    if (qty <= 0) {
      final list = state.preOrderItems.where((i) => i.item.id != itemId).toList();
      state = state.copyWith(preOrderItems: list);
    } else {
      final list = List<CartItemModel>.from(state.preOrderItems);
      final idx = list.indexWhere((i) => i.item.id == itemId);
      if (idx != -1) {
        list[idx].quantity = qty;
        state = state.copyWith(preOrderItems: list);
      }
    }
  }

  void applyVoucher(VoucherModel voucher) {
    state = state.copyWith(appliedVoucher: () => voucher);
  }

  void removeVoucher() {
    state = state.copyWith(appliedVoucher: () => null);
  }

  void setCustomerInfo({required String name, required String phone, String? note}) {
    state = state.copyWith(
      guestName: name,
      guestPhone: phone,
      note: note ?? state.note,
    );
  }

  Future<bool> submitReservation() async {
    if (state.selectedTable == null) {
      state = state.copyWith(errorMessage: 'Vui lòng chọn bàn trước khi tiếp tục');
      return false;
    }

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final res = await _repo.createReservation(
        date: state.selectedDate.toIso8601String().split('T').first,
        startTime: state.selectedTime,
        guestNumber: state.guestNumber,
        tableId: state.selectedTable!.id,
        note: state.note,
        guestName: state.guestName.isNotEmpty ? state.guestName : 'Khách hàng CrownDine',
        guestPhone: state.guestPhone.isNotEmpty ? state.guestPhone : '0901234567',
        items: state.preOrderItems,
      );

      state = state.copyWith(
        isSubmitting: false,
        completedReservation: () => res,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Lỗi đặt bàn: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = ReservationFormState();
  }
}

final reservationProvider = StateNotifierProvider<ReservationNotifier, ReservationFormState>((ref) {
  final repo = ref.watch(reservationRepositoryProvider);
  return ReservationNotifier(repo);
});

final reservationHistoryProvider = FutureProvider<List<ReservationModel>>((ref) async {
  final repo = ref.watch(reservationRepositoryProvider);
  return repo.getReservationHistory();
});
