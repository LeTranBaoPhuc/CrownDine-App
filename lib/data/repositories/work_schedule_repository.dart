import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/user_model.dart';
import '../models/work_schedule_model.dart';

class WorkScheduleRepository {
  final Dio _dio;
  WorkScheduleRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  Future<List<WorkScheduleModel>> getWorkSchedules(
          {String? fromDate,
          String? toDate,
          int? userId,
          String? status,
          int? shiftId}) async =>
      responseList(
              responseData(await _dio.get('work-schedules', queryParameters: {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (userId != null) 'userId': userId,
        if (status != null && status != 'ALL' && status != 'Tất cả')
          'status': status,
        if (shiftId != null) 'shiftId': shiftId,
      })))
          .map((e) => WorkScheduleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<List<ShiftModel>> getAllShifts() async =>
      responseList(responseData(await _dio.get('shifts')))
          .map((e) => ShiftModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<List<UserModel>> getAllStaffs() async =>
      responseList(responseData(await _dio.get('admin/staff/all')))
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<bool> createWorkSchedule(
      {required List<int> staffIds,
      required int shiftId,
      required String workDate,
      String? endDate,
      bool repeatWeekly = false,
      List<int> daysOfWeek = const [],
      bool applyToOthersStaff = false,
      List<int>? otherStaffIds,
      String? note}) async {
    responseData(await _dio.post('work-schedules/create', data: {
      'staffIds': staffIds,
      'shiftId': shiftId,
      'workDate': workDate,
      if (endDate != null) 'endDate': endDate,
      'repeatWeekly': repeatWeekly,
      'daysOfWeek': daysOfWeek,
      'applyToOthersStaff': applyToOthersStaff,
      if (otherStaffIds != null) 'otherStaffIds': otherStaffIds,
      if (note != null) 'note': note,
    }));
    return true;
  }

  Future<bool> deleteWorkSchedule(dynamic id,
      {bool? deletePattern, String? workDate}) async {
    responseData(await _dio.delete('work-schedules/$id', queryParameters: {
      if (deletePattern != null) 'deletePattern': deletePattern,
      if (workDate != null) 'workDate': workDate,
    }));
    return true;
  }
}
