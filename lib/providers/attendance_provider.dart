import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/attendance_model.dart';
import '../data/repositories/attendance_repository.dart';

final attendanceRepositoryProvider =
    Provider<AttendanceRepository>((ref) => AttendanceRepository());

enum AttendanceViewMode {
  shift,    // Xem theo ca (Ma trận Ca x 7 Ngày trong tuần)
  employee; // Xem theo nhân viên (Bảng tổng hợp công, đi muộn, về sớm)

  bool get isShift => this == AttendanceViewMode.shift;
  bool get isEmployee => this == AttendanceViewMode.employee;

  String get displayName {
    switch (this) {
      case AttendanceViewMode.shift:
        return 'Xem theo ca';
      case AttendanceViewMode.employee:
        return 'Xem theo nhân viên';
    }
  }
}

class AttendanceState {
  final AttendanceScheduleResponse? scheduleData;
  final AttendanceSummaryResponse? summaryData;
  final bool isLoading;
  final bool isActionLoading;
  final String? errorMessage;
  final DateTime referenceDate;
  final AttendanceViewMode viewMode;
  final String searchQuery;

  // Modal State
  final int? modalUserId;
  final int? modalShiftId;
  final String? modalWorkDate;
  final List<AttendanceHistoryItem> userHistory;
  final bool isHistoryLoading;

  AttendanceState({
    this.scheduleData,
    this.summaryData,
    this.isLoading = false,
    this.isActionLoading = false,
    this.errorMessage,
    DateTime? referenceDate,
    this.viewMode = AttendanceViewMode.shift,
    this.searchQuery = '',
    this.modalUserId,
    this.modalShiftId,
    this.modalWorkDate,
    this.userHistory = const [],
    this.isHistoryLoading = false,
  }) : referenceDate = referenceDate ?? DateTime.now();

  /// Thứ Hai đầu tuần của tuần tham chiếu (00:00:00)
  DateTime get monday {
    final d = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Chủ Nhật cuối tuần (00:00:00)
  DateTime get sunday => monday.add(const Duration(days: 6));

  /// Chuỗi ngày bắt đầu 'yyyy-MM-dd'
  String get weekStartStr => DateFormatter.toApiDate(monday);

  /// Chuỗi ngày kết thúc 'yyyy-MM-dd'
  String get weekEndStr => DateFormatter.toApiDate(sunday);

  /// Số thứ tự tuần trong năm (Tuần 1 - 52)
  int get weekNumber {
    final firstDayOfYear = DateTime(referenceDate.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - 1;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    final diff = referenceDate.difference(firstMonday).inDays;
    return (diff / 7).floor() + 1;
  }

  /// Chuỗi hiển thị khoảng thời gian: "Tuần 44 - Th. 10 2026"
  String get periodLabel {
    final monthStr = monday.month.toString().padLeft(2, '0');
    return 'Tuần $weekNumber - Th. $monthStr ${monday.year}';
  }

  AttendanceState copyWith({
    AttendanceScheduleResponse? scheduleData,
    AttendanceSummaryResponse? summaryData,
    bool? isLoading,
    bool? isActionLoading,
    String? errorMessage,
    DateTime? referenceDate,
    AttendanceViewMode? viewMode,
    String? searchQuery,
    int? Function()? modalUserId,
    int? Function()? modalShiftId,
    String? Function()? modalWorkDate,
    List<AttendanceHistoryItem>? userHistory,
    bool? isHistoryLoading,
  }) {
    return AttendanceState(
      scheduleData: scheduleData ?? this.scheduleData,
      summaryData: summaryData ?? this.summaryData,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      errorMessage: errorMessage,
      referenceDate: referenceDate ?? this.referenceDate,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      modalUserId: modalUserId != null ? modalUserId() : this.modalUserId,
      modalShiftId: modalShiftId != null ? modalShiftId() : this.modalShiftId,
      modalWorkDate: modalWorkDate != null ? modalWorkDate() : this.modalWorkDate,
      userHistory: userHistory ?? this.userHistory,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRepository _repo;

  AttendanceNotifier(this._repo) : super(AttendanceState()) {
    init();
  }

  /// Khởi tạo dữ liệu ban đầu
  Future<void> init() async {
    await fetchData();
  }

  /// Tải dữ liệu chấm công theo tuần và chế độ xem hiện tại
  Future<void> fetchData({bool showLoading = true}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final date = state.weekStartStr;
      final search = state.searchQuery.trim().isNotEmpty ? state.searchQuery.trim() : null;

      if (state.viewMode.isShift) {
        final schedule = await _repo.getWeeklySchedule(date: date, search: search);
        state = state.copyWith(
          scheduleData: schedule,
          isLoading: false,
        );
      } else {
        final summary = await _repo.getAttendanceSummary(date: date, search: search);
        state = state.copyWith(
          summaryData: summary,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải dữ liệu chấm công: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  /// Chuyển đổi tuần theo ngày bất kỳ
  void changeDate(DateTime newDate) {
    state = state.copyWith(referenceDate: newDate);
    fetchData();
  }

  /// Chuyển sang tuần sau (+7 ngày)
  void goNextWeek() {
    changeDate(state.referenceDate.add(const Duration(days: 7)));
  }

  /// Lùi về tuần trước (-7 ngày)
  void goPrevWeek() {
    changeDate(state.referenceDate.subtract(const Duration(days: 7)));
  }

  /// Trở về tuần hiện tại
  void goToCurrentWeek() {
    changeDate(DateTime.now());
  }

  /// Thay đổi chế độ xem: 'Xem theo ca' / 'Xem theo nhân viên'
  void setViewMode(AttendanceViewMode mode) {
    if (state.viewMode != mode) {
      state = state.copyWith(viewMode: mode);
      fetchData();
    }
  }

  /// Nhập từ khóa tìm kiếm nhân viên / mã định danh
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchData(showLoading: false);
  }

  /// Mở modal chấm công cho nhân viên
  Future<void> openAttendanceModal(
    int userId, {
    int? shiftId,
    String? workDate,
  }) async {
    state = state.copyWith(
      modalUserId: () => userId,
      modalShiftId: () => shiftId,
      modalWorkDate: () => workDate,
      isHistoryLoading: true,
      userHistory: [],
    );

    try {
      final history = await _repo.getHistory(userId);
      state = state.copyWith(
        userHistory: history,
        isHistoryLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isHistoryLoading: false);
    }
  }

  /// Đóng modal chấm công
  void closeAttendanceModal() {
    state = state.copyWith(
      modalUserId: () => null,
      modalShiftId: () => null,
      modalWorkDate: () => null,
      userHistory: [],
    );
  }

  /// Tải lịch sử chấm công của nhân viên
  Future<void> fetchUserHistory(int userId) async {
    state = state.copyWith(isHistoryLoading: true);
    try {
      final history = await _repo.getHistory(userId);
      state = state.copyWith(
        userHistory: history,
        isHistoryLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isHistoryLoading: false);
    }
  }

  /// Lưu ghi nhận chấm công
  Future<bool> saveRecord(AttendanceRecordRequest request) async {
    state = state.copyWith(isActionLoading: true);

    try {
      final success = await _repo.saveRecord(request);
      if (success) {
        await fetchData(showLoading: false);
        if (state.modalUserId != null) {
          await fetchUserHistory(state.modalUserId!);
        }
        state = state.copyWith(isActionLoading: false);
        return true;
      }
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        errorMessage: 'Lưu chấm công thất bại: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }

    state = state.copyWith(isActionLoading: false);
    return false;
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return AttendanceNotifier(repo);
});

