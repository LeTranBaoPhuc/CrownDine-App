import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/reservation_model.dart';
import '../data/repositories/reservation_repository.dart';
import 'auth_provider.dart';

final staffReservationRepositoryProvider = Provider<ReservationRepository>((ref) => ReservationRepository());

enum ReservationViewMode {
  list,
  calendar;

  bool get isList => this == ReservationViewMode.list;
  bool get isCalendar => this == ReservationViewMode.calendar;
}

class StaffReservationState {
  final List<ReservationModel> allReservations;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final DateTime selectedDate;
  final String selectedStatus; // 'ALL', 'CONFIRMED', 'CHECKED_IN', 'PENDING', 'COMPLETED', 'CANCELLED', 'NO_SHOW'
  final String selectedFloor;
  final String selectedArea;
  final String searchQuery;
  final ReservationViewMode viewMode;
  final ReservationModel? selectedReservation;

  StaffReservationState({
    this.allReservations = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    DateTime? selectedDate,
    this.selectedStatus = 'ALL',
    this.selectedFloor = 'Tất cả',
    this.selectedArea = 'Tất cả',
    this.searchQuery = '',
    this.viewMode = ReservationViewMode.list,
    this.selectedReservation,
  }) : selectedDate = selectedDate ?? DateTime.now();

  String get apiDateString => DateFormatter.toApiDate(selectedDate);

  /// Danh sách đặt bàn sau khi áp dụng toàn bộ bộ lọc
  List<ReservationModel> get filteredReservations {
    final query = searchQuery.trim().toLowerCase();

    final filtered = allReservations.where((r) {
      // 1. Lọc theo ngày
      if (r.date.isNotEmpty && r.date != apiDateString) {
        return false;
      }

      // 2. Lọc theo trạng thái
      if (selectedStatus != 'ALL') {
        if (r.status.code != selectedStatus) {
          return false;
        }
      }

      // 3. Lọc theo Tầng
      if (selectedFloor != 'Tất cả' && r.floorName != null && r.floorName != selectedFloor) {
        return false;
      }

      // 4. Lọc theo Khu vực
      if (selectedArea != 'Tất cả' && r.areaName != null && r.areaName != selectedArea) {
        return false;
      }

      // 5. Tìm kiếm theo tên khách, SĐT, mã đặt bàn, tên bàn
      if (query.isNotEmpty) {
        final matchName = r.displayName.toLowerCase().contains(query);
        final matchPhone = r.displayPhone.toLowerCase().contains(query);
        final matchCode = r.code.toLowerCase().contains(query);
        final matchTable = (r.tableName ?? '').toLowerCase().contains(query);

        if (!matchName && !matchPhone && !matchCode && !matchTable) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sắp xếp theo giờ bắt đầu tăng dần
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }

  // Số lượng theo từng trạng thái trong ngày đã chọn
  int get countAll => allReservations.where((r) => r.date == apiDateString).length;
  int get countConfirmed => allReservations.where((r) => r.date == apiDateString && r.status == ReservationStatus.confirmed).length;
  int get countCheckedIn => allReservations.where((r) => r.date == apiDateString && r.status == ReservationStatus.checkedIn).length;
  int get countPending => allReservations.where((r) => r.date == apiDateString && r.status == ReservationStatus.pending).length;
  int get countCompleted => allReservations.where((r) => r.date == apiDateString && r.status == ReservationStatus.completed).length;
  int get countCancelled => allReservations.where((r) => r.date == apiDateString && (r.status == ReservationStatus.cancelled || r.status == ReservationStatus.noShow)).length;

  /// Danh sách Tầng có trong dữ liệu
  List<String> get availableFloors {
    final set = <String>{'Tất cả', 'Tầng 1', 'Tầng 2'};
    for (final r in allReservations) {
      if (r.floorName != null && r.floorName!.isNotEmpty) {
        set.add(r.floorName!);
      }
    }
    return set.toList();
  }

  /// Danh sách Khu vực theo Tầng được chọn
  List<String> get availableAreas {
    final set = <String>{'Tất cả'};
    for (final r in allReservations) {
      if (selectedFloor == 'Tất cả' || r.floorName == selectedFloor) {
        if (r.areaName != null && r.areaName!.isNotEmpty) {
          set.add(r.areaName!);
        }
      }
    }
    return set.toList();
  }

  StaffReservationState copyWith({
    List<ReservationModel>? allReservations,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    DateTime? selectedDate,
    String? selectedStatus,
    String? selectedFloor,
    String? selectedArea,
    String? searchQuery,
    ReservationViewMode? viewMode,
    ReservationModel? Function()? selectedReservation,
  }) {
    return StaffReservationState(
      allReservations: allReservations ?? this.allReservations,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: errorMessage,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      selectedArea: selectedArea ?? this.selectedArea,
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      selectedReservation: selectedReservation != null ? selectedReservation() : this.selectedReservation,
    );
  }
}

class StaffReservationNotifier extends StateNotifier<StaffReservationState> {
  final ReservationRepository _repo;
  final Ref _ref;

  StaffReservationNotifier(this._repo, this._ref) : super(StaffReservationState()) {
    fetchReservations();
  }

  /// Tải danh sách đơn đặt bàn từ Server / Mock
  Future<void> fetchReservations({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final list = await _repo.getAllReservations(
        date: state.apiDateString,
      );

      state = state.copyWith(
        allReservations: list,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Chọn ngày xem lịch
  void setDate(DateTime date) {
    if (DateFormatter.toApiDate(date) != state.apiDateString) {
      state = state.copyWith(selectedDate: date);
      fetchReservations();
    }
  }

  /// Ngày tiếp theo
  void nextDay() {
    setDate(state.selectedDate.add(const Duration(days: 1)));
  }

  /// Ngày trước đó
  void prevDay() {
    setDate(state.selectedDate.subtract(const Duration(days: 1)));
  }

  /// Trở về ngày hôm nay
  void setToday() {
    setDate(DateTime.now());
  }

  /// Lọc theo trạng thái đơn
  void setStatusFilter(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  /// Lọc theo Tầng
  void setFloorFilter(String floor) {
    state = state.copyWith(
      selectedFloor: floor,
      selectedArea: 'Tất cả',
    );
  }

  /// Lọc theo Khu vực
  void setAreaFilter(String area) {
    state = state.copyWith(selectedArea: area);
  }

  /// Tìm kiếm
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Chuyển đổi chế độ hiển thị: Danh sách / Lịch Timeline
  void setViewMode(ReservationViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ReservationViewMode.list
          ? ReservationViewMode.calendar
          : ReservationViewMode.list,
    );
  }

  /// Chọn đơn đặt bàn để xem chi tiết / thao tác
  void selectReservation(ReservationModel? res) {
    state = state.copyWith(selectedReservation: () => res);
  }

  /// [Action] Check-in đón khách vào bàn
  Future<bool> checkIn(int reservationId) async {
    state = state.copyWith(isActionLoading: true);
    final currentStaff = _ref.read(authProvider).user;

    try {
      final success = await _repo.checkInReservation(
        reservationId,
        staffId: currentStaff?.id,
      );

      if (success) {
        // Cập nhật ngay trên state cục bộ
        final updatedList = state.allReservations.map((r) {
          if (r.id == reservationId) {
            return r.copyWith(status: ReservationStatus.checkedIn);
          }
          return r;
        }).toList();

        ReservationModel? updatedSelected;
        if (state.selectedReservation?.id == reservationId) {
          updatedSelected = state.selectedReservation?.copyWith(status: ReservationStatus.checkedIn);
        }

        state = state.copyWith(
          allReservations: updatedList,
          isActionLoading: false,
          selectedReservation: () => updatedSelected ?? state.selectedReservation,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Check-in thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }

    state = state.copyWith(isActionLoading: false);
    return false;
  }

  /// [Action] Huỷ đặt bàn
  Future<bool> cancel(int reservationId) async {
    state = state.copyWith(isActionLoading: true);

    try {
      final success = await _repo.cancelReservationByStaff(reservationId);

      if (success) {
        final updatedList = state.allReservations.map((r) {
          if (r.id == reservationId) {
            return r.copyWith(status: ReservationStatus.cancelled);
          }
          return r;
        }).toList();

        ReservationModel? updatedSelected;
        if (state.selectedReservation?.id == reservationId) {
          updatedSelected = state.selectedReservation?.copyWith(status: ReservationStatus.cancelled);
        }

        state = state.copyWith(
          allReservations: updatedList,
          isActionLoading: false,
          selectedReservation: () => updatedSelected ?? state.selectedReservation,
        );
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Huỷ đặt bàn thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }

    state = state.copyWith(isActionLoading: false);
    return false;
  }

  /// [Action] Tạo đặt bàn tại chỗ (Walk-in / Phone call)
  Future<bool> createWalkIn({
    required String guestName,
    required String guestPhone,
    required String date,
    required String startTime,
    String? endTime,
    required int guestNumber,
    required int tableId,
    String? note,
    List<ReservationOrderDetailModel> orderDetails = const [],
  }) async {
    state = state.copyWith(isActionLoading: true);

    try {
      final newRes = await _repo.createWalkInReservation(
        guestName: guestName,
        guestPhone: guestPhone,
        date: date,
        startTime: startTime,
        endTime: endTime,
        guestNumber: guestNumber,
        tableId: tableId,
        note: note,
        orderDetails: orderDetails,
      );

      final updatedList = [newRes, ...state.allReservations];
      state = state.copyWith(
        allReservations: updatedList,
        isActionLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Tạo đặt bàn thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }

    state = state.copyWith(isActionLoading: false);
    return false;
  }

  /// [Action] Đổi hoặc gán bàn cho đặt chỗ
  Future<bool> updateTable(int reservationId, int newTableId) async {
    state = state.copyWith(isActionLoading: true);

    try {
      final success = await _repo.updateReservationTable(reservationId, newTableId);
      if (success) {
        await fetchReservations(showLoading: false);
        state = state.copyWith(isActionLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Đổi bàn thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }

    state = state.copyWith(isActionLoading: false);
    return false;
  }
}

final staffReservationProvider =
    StateNotifierProvider<StaffReservationNotifier, StaffReservationState>((ref) {
  final repo = ref.watch(staffReservationRepositoryProvider);
  return StaffReservationNotifier(repo, ref);
});

