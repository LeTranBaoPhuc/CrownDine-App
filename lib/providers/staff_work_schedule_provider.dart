import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/user_model.dart';
import '../data/models/work_schedule_model.dart';
import '../data/repositories/work_schedule_repository.dart';
import 'auth_provider.dart';

final workScheduleRepositoryProvider =
    Provider<WorkScheduleRepository>((ref) => WorkScheduleRepository());

enum WorkScheduleViewMode {
  table,  // Dạng bảng ma trận (Nhân viên x 7 ngày trong tuần)
  agenda; // Dạng danh sách thẻ theo ngày (Tối ưu cho màn hình di động)

  bool get isTable => this == WorkScheduleViewMode.table;
  bool get isAgenda => this == WorkScheduleViewMode.agenda;
}

class StaffWorkScheduleState {
  final List<WorkScheduleModel> allSchedules;
  final List<ShiftModel> availableShifts;
  final List<UserModel> availableStaffs;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final DateTime referenceDate;
  final int? selectedStaffId;
  final int? selectedShiftId;
  final String selectedStatus; // 'ALL', 'APPROVED', 'PENDING', 'REJECTED', 'CANCELLED'
  final bool onlyMyShifts;
  final String searchQuery;
  final WorkScheduleViewMode viewMode;
  final WorkScheduleModel? selectedSchedule;
  final String? selectedDateForAction;
  final UserModel? selectedStaffForAction;

  StaffWorkScheduleState({
    this.allSchedules = const [],
    this.availableShifts = const [],
    this.availableStaffs = const [],
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    DateTime? referenceDate,
    this.selectedStaffId,
    this.selectedShiftId,
    this.selectedStatus = 'ALL',
    this.onlyMyShifts = false,
    this.searchQuery = '',
    this.viewMode = WorkScheduleViewMode.table,
    this.selectedSchedule,
    this.selectedDateForAction,
    this.selectedStaffForAction,
  }) : referenceDate = referenceDate ?? DateTime.now();

  /// Ngày Thứ Hai đầu tuần của tuần tham chiếu (00:00:00)
  DateTime get monday {
    final d = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Ngày Chủ Nhật cuối tuần (00:00:00)
  DateTime get sunday => monday.add(const Duration(days: 6));

  /// Danh sách 7 ngày trong tuần (Thứ Hai -> Chủ Nhật)
  List<DateTime> get weekDays {
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// Chuỗi ngày bắt đầu 'yyyy-MM-dd'
  String get fromDateStr => DateFormatter.toApiDate(monday);

  /// Chuỗi ngày kết thúc 'yyyy-MM-dd'
  String get toDateStr => DateFormatter.toApiDate(sunday);

  /// Số thứ tự tuần trong năm (Tuần 1 - 52)
  int get weekNumber {
    final firstDayOfYear = DateTime(referenceDate.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = referenceDate.difference(firstMonday).inDays;
    return (diff / 7).floor() + 1;
  }

  /// Chuỗi hiển thị khoảng thời gian của tuần: "Tuần 44 • 26/10 - 01/11/2026"
  String get weekRangeDisplay {
    final startFmt = DateFormat('dd/MM').format(monday);
    final endFmt = DateFormat('dd/MM/yyyy').format(sunday);
    return 'Tuần $weekNumber • $startFmt - $endFmt';
  }

  /// Lọc danh sách nhân sự (theo tìm kiếm và lựa chọn nhân viên cụ thể)
  List<UserModel> get filteredStaffs {
    var list = availableStaffs;

    if (selectedStaffId != null) {
      list = list.where((s) => s.id == selectedStaffId).toList();
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((s) {
        final nameMatch = s.fullName.toLowerCase().contains(query);
        final codeMatch = 'NV${s.id.toString().padLeft(6, '0')}'.toLowerCase().contains(query);
        return nameMatch || codeMatch;
      }).toList();
    }

    return list;
  }

  /// Danh sách lịch làm việc áp dụng toàn bộ bộ lọc
  List<WorkScheduleModel> getFilteredSchedules({int? currentUserId}) {
    final query = searchQuery.trim().toLowerCase();

    return allSchedules.where((s) {
      // 1. Lọc theo chỉ xem ca của tôi
      if (onlyMyShifts && currentUserId != null) {
        if (s.user.id != currentUserId) return false;
      }

      // 2. Lọc theo nhân viên cụ thể
      if (selectedStaffId != null && s.user.id != selectedStaffId) {
        return false;
      }

      // 3. Lọc theo ca làm (Shift)
      if (selectedShiftId != null && s.shift.id != selectedShiftId) {
        return false;
      }

      // 4. Lọc theo trạng thái duyệt
      if (selectedStatus != 'ALL') {
        if (s.status.code != selectedStatus) return false;
      }

      // 5. Tìm kiếm theo tên nhân viên hoặc mã ca
      if (query.isNotEmpty) {
        final matchUser = s.user.fullName.toLowerCase().contains(query);
        final matchCode = s.employeeCode.toLowerCase().contains(query);
        final matchShift = s.shift.name.toLowerCase().contains(query);
        if (!matchUser && !matchCode && !matchShift) return false;
      }

      return true;
    }).toList();
  }

  /// Lấy danh sách ca làm việc của 1 nhân viên trong 1 ngày cụ thể (YYYY-MM-DD)
  List<WorkScheduleModel> getShiftsForStaffAndDay(
    int staffId,
    String dateStr, {
    int? currentUserId,
  }) {
    return getFilteredSchedules(currentUserId: currentUserId).where((s) {
      return s.user.id == staffId && s.workDate == dateStr;
    }).toList();
  }

  /// Lấy danh sách ca làm việc của toàn bộ nhân viên trong 1 ngày cụ thể (YYYY-MM-DD)
  List<WorkScheduleModel> getShiftsForDay(
    String dateStr, {
    int? currentUserId,
  }) {
    final list = getFilteredSchedules(currentUserId: currentUserId).where((s) {
      return s.workDate == dateStr;
    }).toList();

    // Sắp xếp theo giờ bắt đầu ca tăng dần
    list.sort((a, b) => a.shift.startTime.compareTo(b.shift.startTime));
    return list;
  }

  /// Thống kê tổng số ca trong tuần
  int get totalShiftsInWeek => allSchedules.length;

  /// Thống kê số ca đã được phê duyệt
  int get approvedShiftsInWeek =>
      allSchedules.where((s) => s.status == WorkScheduleStatus.approved).length;

  /// Thống kê số ca đang chờ phê duyệt
  int get pendingShiftsInWeek =>
      allSchedules.where((s) => s.status == WorkScheduleStatus.pending).length;

  /// Thống kê ca làm của riêng nhân viên hiện tại trong tuần
  int countMyShifts(int? currentUserId) {
    if (currentUserId == null) return 0;
    return allSchedules.where((s) => s.user.id == currentUserId).length;
  }

  StaffWorkScheduleState copyWith({
    List<WorkScheduleModel>? allSchedules,
    List<ShiftModel>? availableShifts,
    List<UserModel>? availableStaffs,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    DateTime? referenceDate,
    int? Function()? selectedStaffId,
    int? Function()? selectedShiftId,
    String? selectedStatus,
    bool? onlyMyShifts,
    String? searchQuery,
    WorkScheduleViewMode? viewMode,
    WorkScheduleModel? Function()? selectedSchedule,
    String? Function()? selectedDateForAction,
    UserModel? Function()? selectedStaffForAction,
  }) {
    return StaffWorkScheduleState(
      allSchedules: allSchedules ?? this.allSchedules,
      availableShifts: availableShifts ?? this.availableShifts,
      availableStaffs: availableStaffs ?? this.availableStaffs,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: errorMessage,
      referenceDate: referenceDate ?? this.referenceDate,
      selectedStaffId: selectedStaffId != null ? selectedStaffId() : this.selectedStaffId,
      selectedShiftId: selectedShiftId != null ? selectedShiftId() : this.selectedShiftId,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      onlyMyShifts: onlyMyShifts ?? this.onlyMyShifts,
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      selectedSchedule: selectedSchedule != null ? selectedSchedule() : this.selectedSchedule,
      selectedDateForAction:
          selectedDateForAction != null ? selectedDateForAction() : this.selectedDateForAction,
      selectedStaffForAction:
          selectedStaffForAction != null ? selectedStaffForAction() : this.selectedStaffForAction,
    );
  }
}

class StaffWorkScheduleNotifier extends StateNotifier<StaffWorkScheduleState> {
  final WorkScheduleRepository _repo;
  final Ref _ref;

  StaffWorkScheduleNotifier(this._repo, this._ref)
      : super(StaffWorkScheduleState()) {
    init();
  }

  int? get _currentUserId => _ref.read(authProvider).user?.id;

  /// Khởi tạo dữ liệu ban đầu
  Future<void> init() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final shiftsFuture = _repo.getAllShifts();
      final staffsFuture = _repo.getAllStaffs();
      final schedulesFuture = _repo.getWorkSchedules(
        fromDate: state.fromDateStr,
        toDate: state.toDateStr,
      );

      final results = await Future.wait([
        shiftsFuture,
        staffsFuture,
        schedulesFuture,
      ]);

      state = state.copyWith(
        availableShifts: results[0] as List<ShiftModel>,
        availableStaffs: results[1] as List<UserModel>,
        allSchedules: results[2] as List<WorkScheduleModel>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải lịch làm việc: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  /// Tải lại lịch làm việc theo khoảng tuần hiện tại
  Future<void> fetchSchedules({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final schedules = await _repo.getWorkSchedules(
        fromDate: state.fromDateStr,
        toDate: state.toDateStr,
        userId: state.onlyMyShifts ? _currentUserId : state.selectedStaffId,
        status: state.selectedStatus,
        shiftId: state.selectedShiftId,
      );

      state = state.copyWith(
        allSchedules: schedules,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải lịch làm việc: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  /// Đổi tuần làm việc theo ngày bất kỳ
  void changeWeek(DateTime newDate) {
    state = state.copyWith(referenceDate: newDate);
    fetchSchedules();
  }

  /// Chuyển sang tuần tiếp theo (+7 ngày)
  void nextWeek() {
    changeWeek(state.referenceDate.add(const Duration(days: 7)));
  }

  /// Lùi về tuần trước (-7 ngày)
  void prevWeek() {
    changeWeek(state.referenceDate.subtract(const Duration(days: 7)));
  }

  /// Trở về tuần hiện tại (Hôm nay)
  void goToCurrentWeek() {
    changeWeek(DateTime.now());
  }

  /// Bật / tắt chỉ xem ca của tôi
  void toggleOnlyMyShifts(bool value) {
    state = state.copyWith(onlyMyShifts: value);
  }

  /// Chọn nhân viên để lọc
  void setSelectedStaff(int? staffId) {
    state = state.copyWith(selectedStaffId: () => staffId);
  }

  /// Chọn ca làm việc để lọc
  void setSelectedShift(int? shiftId) {
    state = state.copyWith(selectedShiftId: () => shiftId);
  }

  /// Lọc theo trạng thái phê duyệt ('ALL', 'APPROVED', 'PENDING', 'CANCELLED')
  void setSelectedStatus(String status) {
    state = state.copyWith(selectedStatus: status);
  }

  /// Nhập chuỗi tìm kiếm nhân viên / ca trực
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Chuyển đổi chế độ xem: Bảng ma trận / Danh sách thẻ
  void setViewMode(WorkScheduleViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Chuyển đổi qua lại giữa Bảng ma trận và Danh sách
  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == WorkScheduleViewMode.table
          ? WorkScheduleViewMode.agenda
          : WorkScheduleViewMode.table,
    );
  }

  /// Chọn ca trực để mở popup chi tiết
  void selectSchedule(WorkScheduleModel? schedule) {
    state = state.copyWith(selectedSchedule: () => schedule);
  }

  /// Thiết lập ô ngày và nhân viên chuẩn bị thêm ca trực
  void setActionTarget({UserModel? staff, String? dateStr}) {
    state = state.copyWith(
      selectedStaffForAction: () => staff,
      selectedDateForAction: () => dateStr,
    );
  }

  /// Đăng ký / Phân ca làm việc mới
  Future<bool> createSchedule({
    required List<int> staffIds,
    required int shiftId,
    required String workDate,
    String? endDate,
    bool repeatWeekly = false,
    List<int> daysOfWeek = const [],
    bool applyToOthersStaff = false,
    List<int>? otherStaffIds,
    String? note,
  }) async {
    state = state.copyWith(isActionLoading: true);

    try {
      final success = await _repo.createWorkSchedule(
        staffIds: staffIds,
        shiftId: shiftId,
        workDate: workDate,
        endDate: endDate,
        repeatWeekly: repeatWeekly,
        daysOfWeek: daysOfWeek,
        applyToOthersStaff: applyToOthersStaff,
        otherStaffIds: otherStaffIds,
        note: note,
      );

      if (success) {
        await fetchSchedules(showLoading: false);
        state = state.copyWith(isActionLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Phân ca thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }

    state = state.copyWith(isActionLoading: false);
    return false;
  }

  /// Xóa ca làm việc
  Future<bool> deleteSchedule(
    dynamic id, {
    bool? deletePattern,
    String? workDate,
  }) async {
    state = state.copyWith(isActionLoading: true);

    try {
      final success = await _repo.deleteWorkSchedule(
        id,
        deletePattern: deletePattern,
        workDate: workDate,
      );

      if (success) {
        await fetchSchedules(showLoading: false);
        state = state.copyWith(isActionLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Xóa ca thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }

    state = state.copyWith(isActionLoading: false);
    return false;
  }
}

final staffWorkScheduleProvider =
    StateNotifierProvider<StaffWorkScheduleNotifier, StaffWorkScheduleState>((ref) {
  final repo = ref.watch(workScheduleRepositoryProvider);
  return StaffWorkScheduleNotifier(repo, ref);
});

