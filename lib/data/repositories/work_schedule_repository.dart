import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/user_model.dart';
import '../models/work_schedule_model.dart';

class WorkScheduleRepository {
  final ApiClient _client = ApiClient.instance;

  /// Lấy danh sách lịch làm việc theo khoảng thời gian (tuần/tháng) và bộ lọc
  Future<List<WorkScheduleModel>> getWorkSchedules({
    String? fromDate,
    String? toDate,
    int? userId,
    String? status,
    int? shiftId,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final queryParams = <String, dynamic>{};
      if (fromDate != null && fromDate.isNotEmpty) queryParams['fromDate'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['toDate'] = toDate;
      if (userId != null) queryParams['userId'] = userId;
      if (status != null && status.isNotEmpty && status != 'ALL' && status != 'Tất cả') {
        queryParams['status'] = status;
      }
      if (shiftId != null) queryParams['shiftId'] = shiftId;

      final response = await _client.dio.get(
        ApiEndpoints.workSchedules,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        final list = (body['data'] as List?) ??
            (body['content'] as List?) ??
            (body['items'] as List?) ??
            (body as List?);

        if (list != null) {
          return list.map((e) => WorkScheduleModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Fallback to mock data with filtering
    return MockData.getWorkSchedules(
      fromDate: fromDate,
      toDate: toDate,
      userId: userId,
      status: status,
      shiftId: shiftId,
    );
  }

  /// Lấy danh sách tất cả các ca làm việc mẫu (Shifts)
  Future<List<ShiftModel>> getAllShifts() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.shifts);
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        final list = (body['data'] as List?) ?? (body as List?);
        if (list != null) {
          return list.map((e) => ShiftModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.sampleShifts;
  }

  /// Lấy danh sách nhân viên để hiển thị bảng phân ca
  Future<List<UserModel>> getAllStaffs() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.adminStaffAll);
      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        final list = (body['data'] as List?) ?? (body as List?);
        if (list != null) {
          return list.map((e) => UserModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.sampleStaffs;
  }

  /// Thêm lịch làm việc mới (dành cho Admin / Quản lý phân ca)
  Future<bool> createWorkSchedule({
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
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.post(
        ApiEndpoints.workSchedulesCreate,
        data: {
          'staffIds': staffIds,
          'shiftId': shiftId,
          'workDate': workDate,
          if (endDate != null) 'endDate': endDate,
          'repeatWeekly': repeatWeekly,
          'daysOfWeek': daysOfWeek,
          'applyToOthersStaff': applyToOthersStaff,
          if (otherStaffIds != null) 'otherStaffIds': otherStaffIds,
          if (note != null) 'note': note,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Mock create logic
    final shift = MockData.sampleShifts.firstWhere(
      (s) => s.id == shiftId,
      orElse: () => MockData.sampleShifts.first,
    );

    final targetStaffIds = {...staffIds, if (applyToOthersStaff && otherStaffIds != null) ...otherStaffIds};
    for (final sId in targetStaffIds) {
      final staff = MockData.sampleStaffs.firstWhere(
        (st) => st.id == sId,
        orElse: () => UserModel(id: sId, username: 'NV$sId', email: '', role: UserRole.staff),
      );

      final newSchedule = WorkScheduleModel(
        id: DateTime.now().millisecondsSinceEpoch % 1000000 + sId,
        workDate: workDate,
        status: WorkScheduleStatus.approved,
        note: note,
        user: staff,
        shift: shift,
        createdAt: DateTime.now(),
      );
      MockData.sampleWorkSchedules.add(newSchedule);
    }

    return true;
  }

  /// Xóa lịch làm việc
  Future<bool> deleteWorkSchedule(
    dynamic id, {
    bool? deletePattern,
    String? workDate,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.delete(
        ApiEndpoints.workScheduleById(id),
        queryParameters: {
          if (deletePattern != null) 'deletePattern': deletePattern,
          if (workDate != null) 'workDate': workDate,
        },
      );
      if (response.statusCode == 200) {
        MockData.sampleWorkSchedules.removeWhere((s) => s.id.toString() == id.toString());
        return true;
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    MockData.sampleWorkSchedules.removeWhere((s) => s.id.toString() == id.toString());
    return true;
  }
}
