import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  final ApiClient _client = ApiClient.instance;

  /// Lấy lịch chấm công hàng tuần theo ca (ScheduleByShift)
  Future<AttendanceScheduleResponse> getWeeklySchedule({
    String? date,
    String? search,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final queryParams = <String, dynamic>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _client.dio.get(
        ApiEndpoints.attendancesSchedule,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        if (body is Map<String, dynamic>) {
          return AttendanceScheduleResponse.fromJson(body);
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.getAttendanceSchedule(date: date, search: search);
  }

  /// Lấy bảng tổng hợp chấm công của nhân viên theo tuần/tháng (SummaryByEmployee)
  Future<AttendanceSummaryResponse> getAttendanceSummary({
    String? date,
    String? search,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final queryParams = <String, dynamic>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _client.dio.get(
        ApiEndpoints.attendancesSummary,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        if (body is Map<String, dynamic>) {
          return AttendanceSummaryResponse.fromJson(body);
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.getAttendanceSummary(date: date, search: search);
  }

  /// Lấy lịch sử chấm công của nhân viên
  Future<List<AttendanceHistoryItem>> getHistory(
    int userId, {
    int page = 0,
    int size = 10,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(
        ApiEndpoints.attendancesHistory(userId),
        queryParameters: {'page': page, 'size': size},
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        final list = (body['content'] as List?) ??
            (body['data'] as List?) ??
            (body as List?);
        if (list != null) {
          return list.map((e) => AttendanceHistoryItem.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.getAttendanceHistory(userId);
  }

  /// Lấy trạng thái hiện tại của nhân viên
  Future<AttendanceStatus> getEmployeeCurrentStatus(int userId) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(
        ApiEndpoints.attendancesEmployeeInfo(userId),
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        if (body is Map<String, dynamic>) {
          return AttendanceStatus.fromString(body['currentStatus']?.toString());
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.getEmployeeAttendanceStatus(userId);
  }

  /// Ghi nhận hoặc chỉnh sửa chấm công
  Future<bool> saveRecord(AttendanceRecordRequest request) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.post(
        ApiEndpoints.attendancesRecord,
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        MockData.recordAttendanceMock(request);
        return true;
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    MockData.recordAttendanceMock(request);
    return true;
  }
}

