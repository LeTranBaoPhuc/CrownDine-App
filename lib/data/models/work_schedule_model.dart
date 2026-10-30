import 'package:flutter/material.dart';
import 'user_model.dart';

/// Trạng thái của ca làm việc
enum WorkScheduleStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static WorkScheduleStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return WorkScheduleStatus.approved;
      case 'PENDING':
        return WorkScheduleStatus.pending;
      case 'REJECTED':
        return WorkScheduleStatus.rejected;
      case 'CANCELLED':
        return WorkScheduleStatus.cancelled;
      default:
        return WorkScheduleStatus.pending;
    }
  }

  String get code {
    switch (this) {
      case WorkScheduleStatus.approved:
        return 'APPROVED';
      case WorkScheduleStatus.pending:
        return 'PENDING';
      case WorkScheduleStatus.rejected:
        return 'REJECTED';
      case WorkScheduleStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get displayName {
    switch (this) {
      case WorkScheduleStatus.approved:
        return 'Đã duyệt';
      case WorkScheduleStatus.pending:
        return 'Chờ duyệt';
      case WorkScheduleStatus.rejected:
        return 'Từ chối';
      case WorkScheduleStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Color get color {
    switch (this) {
      case WorkScheduleStatus.approved:
        return const Color(0xFF10B981); // Emerald green
      case WorkScheduleStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case WorkScheduleStatus.rejected:
        return const Color(0xFFEF4444); // Red
      case WorkScheduleStatus.cancelled:
        return const Color(0xFF9CA3AF); // Gray
    }
  }

  Color get backgroundColor {
    switch (this) {
      case WorkScheduleStatus.approved:
        return const Color(0xFFE6F4EA);
      case WorkScheduleStatus.pending:
        return const Color(0xFFFFFBEB);
      case WorkScheduleStatus.rejected:
        return const Color(0xFFFEE2E2);
      case WorkScheduleStatus.cancelled:
        return const Color(0xFFF3F4F6);
    }
  }
}

/// Ca làm việc (Shift)
class ShiftModel {
  final int id;
  final String name;
  final String startTime; // '08:00:00' or '08:00'
  final String endTime;   // '16:00:00' or '16:00'
  final String? colorHex;

  const ShiftModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.colorHex,
  });

  /// Hiển thị giờ định dạng ngắn gọn '08:00 - 16:00'
  String get displayTimeRange {
    final start = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final end = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$start - $end';
  }

  String get displayName => '$name ($displayTimeRange)';

  /// Giờ bắt đầu dạng int
  int get startHour => int.tryParse(startTime.split(':').first) ?? 0;

  /// Giờ kết thúc dạng int
  int get endHour => int.tryParse(endTime.split(':').first) ?? 0;

  /// Màu sắc đại diện cho ca
  Color get themeColor {
    if (colorHex != null && colorHex!.isNotEmpty) {
      try {
        final hex = colorHex!.replaceAll('#', '');
        return Color(int.parse('0xFF$hex'));
      } catch (_) {}
    }

    // Default colors based on shift name or hours
    final lower = name.toLowerCase();
    if (lower.contains('sáng') || lower.contains('morning')) {
      return const Color(0xFF10B981); // Xanh lá
    } else if (lower.contains('chiều') || lower.contains('afternoon')) {
      return const Color(0xFF3B82F6); // Xanh dương
    } else if (lower.contains('tối') || lower.contains('night')) {
      return const Color(0xFF8B5CF6); // Tím
    } else if (lower.contains('gãy') || lower.contains('trưa')) {
      return const Color(0xFFF59E0B); // Vàng hổ phách
    } else if (lower.contains('full')) {
      return const Color(0xFFEC4899); // Hồng ruby
    }
    return const Color(0xFF003A8C);
  }

  Color get lightBackgroundColor {
    final base = themeColor;
    return base.withValues(alpha: 0.12);
  }

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '00:00:00',
      endTime: json['endTime']?.toString() ?? '00:00:00',
      colorHex: json['colorHex']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime,
      'endTime': endTime,
      if (colorHex != null) 'colorHex': colorHex,
    };
  }

  ShiftModel copyWith({
    int? id,
    String? name,
    String? startTime,
    String? endTime,
    String? colorHex,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}

/// Lịch làm việc chi tiết (Work Schedule Item)
class WorkScheduleModel {
  final int id;
  final String workDate; // 'YYYY-MM-DD'
  final WorkScheduleStatus status;
  final String? note;
  final String? repeatGroupId;
  final UserModel user;
  final ShiftModel shift;
  final DateTime? createdAt;

  const WorkScheduleModel({
    required this.id,
    required this.workDate,
    required this.status,
    this.note,
    this.repeatGroupId,
    required this.user,
    required this.shift,
    this.createdAt,
  });

  /// Parse sang DateTime
  DateTime? get parsedDate => DateTime.tryParse(workDate);

  /// Kiểm tra xem có phải lịch trực của nhân viên hiện tại không
  bool isMyShift(int? currentUserId) {
    if (currentUserId == null) return false;
    return user.id == currentUserId;
  }

  /// Tên định danh nhân viên
  String get employeeCode => 'NV${user.id.toString().padLeft(6, '0')}';

  factory WorkScheduleModel.fromJson(Map<String, dynamic> json) {
    // Parse user object
    UserModel user;
    if (json['user'] is Map<String, dynamic>) {
      final u = json['user'] as Map<String, dynamic>;
      final fullName = u['fullName']?.toString() ?? '';
      final parts = fullName.trim().split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      user = UserModel(
        id: u['id'] is int ? u['id'] : int.tryParse('${u['id']}') ?? 0,
        username: u['username']?.toString() ?? fullName,
        email: u['email']?.toString() ?? '',
        firstName: u['firstName']?.toString() ?? firstName,
        lastName: u['lastName']?.toString() ?? lastName,
        avatar: u['avatarUrl']?.toString() ?? u['avatar']?.toString(),
        gender: u['gender']?.toString(),
        role: UserRole.staff,
      );
    } else {
      user = UserModel(
        id: 0,
        username: 'Nhân viên',
        email: '',
        role: UserRole.staff,
      );
    }

    // Parse shift object
    ShiftModel shift;
    if (json['shift'] is Map<String, dynamic>) {
      shift = ShiftModel.fromJson(json['shift'] as Map<String, dynamic>);
    } else {
      shift = const ShiftModel(
        id: 0,
        name: 'Ca làm',
        startTime: '08:00:00',
        endTime: '16:00:00',
      );
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString());
    }

    return WorkScheduleModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      workDate: json['workDate']?.toString() ?? '',
      status: WorkScheduleStatus.fromString(json['status']?.toString()),
      note: json['note']?.toString(),
      repeatGroupId: json['repeatGroupId']?.toString(),
      user: user,
      shift: shift,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workDate': workDate,
      'status': status.code,
      'note': note,
      if (repeatGroupId != null) 'repeatGroupId': repeatGroupId,
      'user': {
        'id': user.id,
        'fullName': user.fullName,
        'gender': user.gender,
        'avatarUrl': user.avatarUrl,
      },
      'shift': shift.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  WorkScheduleModel copyWith({
    int? id,
    String? workDate,
    WorkScheduleStatus? status,
    String? note,
    String? repeatGroupId,
    UserModel? user,
    ShiftModel? shift,
    DateTime? createdAt,
  }) {
    return WorkScheduleModel(
      id: id ?? this.id,
      workDate: workDate ?? this.workDate,
      status: status ?? this.status,
      note: note ?? this.note,
      repeatGroupId: repeatGroupId ?? this.repeatGroupId,
      user: user ?? this.user,
      shift: shift ?? this.shift,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

