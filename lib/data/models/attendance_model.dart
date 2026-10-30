import 'package:flutter/material.dart';
import 'work_schedule_model.dart';

/// Trạng thái chấm công (khớp backend EAttendanceStatus)
enum AttendanceStatus {
  onTime,       // Đúng giờ (#3b82f6)
  lateEarly,    // Đi muộn / Về sớm (#a855f7)
  missingPunch, // Chấm công thiếu (#ef4444)
  notPunched,   // Chưa chấm công (#f59e0b)
  absentOff;    // Nghỉ làm (#9ca3af)

  static AttendanceStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'ON_TIME':
        return AttendanceStatus.onTime;
      case 'LATE_EARLY':
        return AttendanceStatus.lateEarly;
      case 'MISSING_PUNCH':
        return AttendanceStatus.missingPunch;
      case 'NOT_PUNCHED':
        return AttendanceStatus.notPunched;
      case 'ABSENT_OFF':
        return AttendanceStatus.absentOff;
      default:
        return AttendanceStatus.notPunched;
    }
  }

  String get code {
    switch (this) {
      case AttendanceStatus.onTime:
        return 'ON_TIME';
      case AttendanceStatus.lateEarly:
        return 'LATE_EARLY';
      case AttendanceStatus.missingPunch:
        return 'MISSING_PUNCH';
      case AttendanceStatus.notPunched:
        return 'NOT_PUNCHED';
      case AttendanceStatus.absentOff:
        return 'ABSENT_OFF';
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceStatus.onTime:
        return 'Đúng giờ';
      case AttendanceStatus.lateEarly:
        return 'Đi muộn / Về sớm';
      case AttendanceStatus.missingPunch:
        return 'Chấm công thiếu';
      case AttendanceStatus.notPunched:
        return 'Chưa chấm công';
      case AttendanceStatus.absentOff:
        return 'Nghỉ làm';
    }
  }

  Color get color {
    switch (this) {
      case AttendanceStatus.onTime:
        return const Color(0xFF3B82F6); // Blue
      case AttendanceStatus.lateEarly:
        return const Color(0xFFA855F7); // Purple
      case AttendanceStatus.missingPunch:
        return const Color(0xFFEF4444); // Red
      case AttendanceStatus.notPunched:
        return const Color(0xFFF59E0B); // Amber
      case AttendanceStatus.absentOff:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }
}

/// Hình thức chấm công (khớp backend EAttendanceType)
enum AttendanceType {
  working,                // Đi làm
  leaveWithPermission,    // Nghỉ có phép
  leaveWithoutPermission; // Nghỉ không phép

  static AttendanceType fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'WORKING':
        return AttendanceType.working;
      case 'LEAVE_WITH_PERMISSION':
        return AttendanceType.leaveWithPermission;
      case 'LEAVE_WITHOUT_PERMISSION':
        return AttendanceType.leaveWithoutPermission;
      default:
        return AttendanceType.working;
    }
  }

  String get code {
    switch (this) {
      case AttendanceType.working:
        return 'WORKING';
      case AttendanceType.leaveWithPermission:
        return 'LEAVE_WITH_PERMISSION';
      case AttendanceType.leaveWithoutPermission:
        return 'LEAVE_WITHOUT_PERMISSION';
    }
  }

  String get displayName {
    switch (this) {
      case AttendanceType.working:
        return 'Đi làm';
      case AttendanceType.leaveWithPermission:
        return 'Nghỉ có phép';
      case AttendanceType.leaveWithoutPermission:
        return 'Nghỉ không phép';
    }
  }
}

/// Nhân viên trong ô lịch chấm công
class AttendanceScheduleEmployee {
  final int userId;
  final String staffCode;
  final String fullName;
  final AttendanceStatus status;
  final String? avatarUrl;

  const AttendanceScheduleEmployee({
    required this.userId,
    required this.staffCode,
    required this.fullName,
    required this.status,
    this.avatarUrl,
  });

  factory AttendanceScheduleEmployee.fromJson(Map<String, dynamic> json) {
    return AttendanceScheduleEmployee(
      userId: json['userId'] is int ? json['userId'] : int.tryParse('${json['userId']}') ?? 0,
      staffCode: json['staffCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      status: AttendanceStatus.fromString(json['status']?.toString()),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'staffCode': staffCode,
      'fullName': fullName,
      'status': status.code,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

/// Ô dữ liệu chấm công (Ca x Ngày)
class AttendanceScheduleCell {
  final int shiftId;
  final String workDate; // 'yyyy-MM-dd'
  final String dayOfWeek; // 'Thứ 2'
  final String dateShort; // '26/10'
  final List<AttendanceScheduleEmployee> employees;

  const AttendanceScheduleCell({
    required this.shiftId,
    required this.workDate,
    required this.dayOfWeek,
    required this.dateShort,
    required this.employees,
  });

  factory AttendanceScheduleCell.fromJson(Map<String, dynamic> json) {
    final list = json['employees'] as List?;
    return AttendanceScheduleCell(
      shiftId: json['shiftId'] is int ? json['shiftId'] : int.tryParse('${json['shiftId']}') ?? 0,
      workDate: json['workDate']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      dateShort: json['dateShort']?.toString() ?? '',
      employees: list != null
          ? list.map((e) => AttendanceScheduleEmployee.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shiftId': shiftId,
      'workDate': workDate,
      'dayOfWeek': dayOfWeek,
      'dateShort': dateShort,
      'employees': employees.map((e) => e.toJson()).toList(),
    };
  }
}

/// Phản hồi cấu trúc bảng lịch chấm công theo tuần (ScheduleByShift)
class AttendanceScheduleResponse {
  final String weekStart; // 'yyyy-MM-dd'
  final String weekEnd;   // 'yyyy-MM-dd'
  final int weekNumber;
  final int year;
  final List<ShiftModel> shifts;
  final List<AttendanceScheduleCell> cells;

  const AttendanceScheduleResponse({
    required this.weekStart,
    required this.weekEnd,
    required this.weekNumber,
    required this.year,
    required this.shifts,
    required this.cells,
  });

  /// Map tra cứu nhanh ô dữ liệu theo `$shiftId-$workDate`
  AttendanceScheduleCell? getCell(int shiftId, String workDate) {
    for (final c in cells) {
      if (c.shiftId == shiftId && c.workDate == workDate) {
        return c;
      }
    }
    return null;
  }

  factory AttendanceScheduleResponse.fromJson(Map<String, dynamic> json) {
    final shiftsList = json['shifts'] as List?;
    final cellsList = json['cells'] as List?;

    return AttendanceScheduleResponse(
      weekStart: json['weekStart']?.toString() ?? '',
      weekEnd: json['weekEnd']?.toString() ?? '',
      weekNumber: json['weekNumber'] is int
          ? json['weekNumber']
          : int.tryParse('${json['weekNumber']}') ?? 1,
      year: json['year'] is int ? json['year'] : int.tryParse('${json['year']}') ?? DateTime.now().year,
      shifts: shiftsList != null
          ? shiftsList.map((s) => ShiftModel.fromJson(s as Map<String, dynamic>)).toList()
          : const [],
      cells: cellsList != null
          ? cellsList.map((c) => AttendanceScheduleCell.fromJson(c as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekStart,
      'weekEnd': weekEnd,
      'weekNumber': weekNumber,
      'year': year,
      'shifts': shifts.map((s) => s.toJson()).toList(),
      'cells': cells.map((c) => c.toJson()).toList(),
    };
  }
}

/// Tổng hợp chấm công của từng nhân viên (SummaryByEmployee)
class EmployeeAttendanceSummary {
  final int userId;
  final String staffCode;
  final String fullName;
  final int workShiftCount;
  final String workHoursTotal;
  final int leaveShiftCount;
  final int lateCount;
  final String lateDuration;
  final int earlyLeaveCount;
  final String earlyLeaveDuration;
  final String overtime;
  final bool noData;
  final String? avatarUrl;

  const EmployeeAttendanceSummary({
    required this.userId,
    required this.staffCode,
    required this.fullName,
    this.workShiftCount = 0,
    this.workHoursTotal = '0h 0m',
    this.leaveShiftCount = 0,
    this.lateCount = 0,
    this.lateDuration = '0m',
    this.earlyLeaveCount = 0,
    this.earlyLeaveDuration = '0m',
    this.overtime = '0m',
    this.noData = false,
    this.avatarUrl,
  });

  factory EmployeeAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceSummary(
      userId: json['userId'] is int ? json['userId'] : int.tryParse('${json['userId']}') ?? 0,
      staffCode: json['staffCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      workShiftCount: json['workShiftCount'] is int
          ? json['workShiftCount']
          : int.tryParse('${json['workShiftCount']}') ?? 0,
      workHoursTotal: json['workHoursTotal']?.toString() ?? '0h 0m',
      leaveShiftCount: json['leaveShiftCount'] is int
          ? json['leaveShiftCount']
          : int.tryParse('${json['leaveShiftCount']}') ?? 0,
      lateCount: json['lateCount'] is int
          ? json['lateCount']
          : int.tryParse('${json['lateCount']}') ?? 0,
      lateDuration: json['lateDuration']?.toString() ?? '0m',
      earlyLeaveCount: json['earlyLeaveCount'] is int
          ? json['earlyLeaveCount']
          : int.tryParse('${json['earlyLeaveCount']}') ?? 0,
      earlyLeaveDuration: json['earlyLeaveDuration']?.toString() ?? '0m',
      overtime: json['overtime']?.toString() ?? '0m',
      noData: json['noData'] is bool ? json['noData'] : false,
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'staffCode': staffCode,
      'fullName': fullName,
      'workShiftCount': workShiftCount,
      'workHoursTotal': workHoursTotal,
      'leaveShiftCount': leaveShiftCount,
      'lateCount': lateCount,
      'lateDuration': lateDuration,
      'earlyLeaveCount': earlyLeaveCount,
      'earlyLeaveDuration': earlyLeaveDuration,
      'overtime': overtime,
      'noData': noData,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

/// Phản hồi tổng hợp chấm công
class AttendanceSummaryResponse {
  final String periodLabel;
  final List<EmployeeAttendanceSummary> employees;

  const AttendanceSummaryResponse({
    required this.periodLabel,
    required this.employees,
  });

  factory AttendanceSummaryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['employees'] as List?;
    return AttendanceSummaryResponse(
      periodLabel: json['periodLabel']?.toString() ?? '',
      employees: list != null
          ? list.map((e) => EmployeeAttendanceSummary.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodLabel': periodLabel,
      'employees': employees.map((e) => e.toJson()).toList(),
    };
  }
}

/// Lịch sử chấm công của nhân viên
class AttendanceHistoryItem {
  final int id;
  final String time;
  final AttendanceStatus status;
  final String? content;

  const AttendanceHistoryItem({
    required this.id,
    required this.time,
    required this.status,
    this.content,
  });

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      time: json['time']?.toString() ?? '',
      status: AttendanceStatus.fromString(json['status']?.toString()),
      content: json['content']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'status': status.code,
      'content': content,
    };
  }
}

/// Yêu cầu ghi nhận / cập nhật chấm công
class AttendanceRecordRequest {
  final int userId;
  final String workDate; // 'yyyy-MM-dd'
  final int shiftId;
  final String? note;
  final AttendanceType attendanceType;
  final bool hasPunchIn;
  final bool hasPunchOut;
  final String? checkInAt;  // '08:00'
  final String? checkOutAt; // '16:00'

  const AttendanceRecordRequest({
    required this.userId,
    required this.workDate,
    required this.shiftId,
    this.note,
    this.attendanceType = AttendanceType.working,
    this.hasPunchIn = true,
    this.hasPunchOut = true,
    this.checkInAt,
    this.checkOutAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'workDate': workDate,
      'shiftId': shiftId,
      if (note != null && note!.isNotEmpty) 'note': note,
      'attendanceType': attendanceType.code,
      'hasPunchIn': hasPunchIn,
      'hasPunchOut': hasPunchOut,
      if (checkInAt != null) 'checkInAt': checkInAt,
      if (checkOutAt != null) 'checkOutAt': checkOutAt,
    };
  }
}

