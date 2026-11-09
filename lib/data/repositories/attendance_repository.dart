import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  final Dio _dio;
  AttendanceRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  Future<AttendanceScheduleResponse> getWeeklySchedule(
          {String? date, String? search}) async =>
      AttendanceScheduleResponse.fromJson(Map<String, dynamic>.from(
          responseData(await _dio.get('attendances/schedule', queryParameters: {
        if (date != null) 'date': date,
        if (search != null) 'search': search,
      }))));
  Future<AttendanceSummaryResponse> getAttendanceSummary(
          {String? date, String? search}) async =>
      AttendanceSummaryResponse.fromJson(Map<String, dynamic>.from(
          responseData(await _dio.get('attendances/summary', queryParameters: {
        if (date != null) 'date': date,
        if (search != null) 'search': search,
      }))));
  Future<List<AttendanceHistoryItem>> getHistory(int userId,
          {int page = 0, int size = 10}) async =>
      responseList(responseData(await _dio.get('attendances/history/$userId',
              queryParameters: {'page': page, 'size': size})))
          .map((e) =>
              AttendanceHistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<AttendanceStatus> getEmployeeCurrentStatus(int userId) async {
    final data =
        responseData(await _dio.get('attendances/employee/$userId/info'));
    if (data is! Map || data['currentStatus'] is! String)
      throw const FormatException('Thiếu trạng thái chấm công.');
    return AttendanceStatus.fromString(data['currentStatus']);
  }

  Future<bool> saveRecord(AttendanceRecordRequest request) async {
    responseData(await _dio.post('attendances/record', data: request.toJson()));
    return true;
  }
}
