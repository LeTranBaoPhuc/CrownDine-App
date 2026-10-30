import '../../core/utils/image_utils.dart';

enum UserRole {
  customer,
  staff,
  admin;

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
      case 'ROLE_ADMIN':
        return UserRole.admin;
      case 'STAFF':
      case 'ROLE_STAFF':
        return UserRole.staff;
      case 'USER':
      case 'ROLE_USER':
      case 'CUSTOMER':
      default:
        return UserRole.customer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị viên';
      case UserRole.staff:
        return 'Nhân viên';
      case UserRole.customer:
        return 'Khách hàng';
    }
  }
}

class UserModel {
  final int id;
  final String username;
  final String email;
  final String? phone;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final UserRole role;
  final int points;
  final String? membershipTier;
  final bool isActive;
  final String? gender;
  final String? dateOfBirth;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phone,
    this.firstName,
    this.lastName,
    this.avatar,
    this.role = UserRole.customer,
    this.points = 0,
    this.membershipTier = 'Silver',
    this.isActive = true,
    this.gender,
    this.dateOfBirth,
  });

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? avatar,
    UserRole? role,
    int? points,
    String? membershipTier,
    bool? isActive,
    String? gender,
    String? dateOfBirth,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      points: points ?? this.points,
      membershipTier: membershipTier ?? this.membershipTier,
      isActive: isActive ?? this.isActive,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  String get fullName {
    if (firstName != null || lastName != null) {
      return '${firstName ?? ''} ${lastName ?? ''}'.trim();
    }
    return username;
  }

  String? get avatarUrl => ImageUtils.getSafeImageUrl(avatar);

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString().toUpperCase();
    final bool active = statusStr == null
        ? (json['isActive'] is bool ? json['isActive'] : true)
        : (statusStr == 'ACTIVE');

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      avatar: json['avatar'] ?? json['avatarUrl'],
      role: UserRole.fromString(
        (json['role'] ??
            (json['roles'] is List && (json['roles'] as List).isNotEmpty
                ? ((json['roles'] as List).first is Map
                    ? ((json['roles'] as List).first['name'] ?? (json['roles'] as List).first['role'])
                    : (json['roles'] as List).first)
                : null))?.toString(),
      ),
      points: json['rewardPoints'] is int
          ? json['rewardPoints']
          : (json['points'] is int ? json['points'] : int.tryParse('${json['rewardPoints'] ?? json['points']}') ?? 0),
      membershipTier: json['membershipTier'] ?? (json['role'] == 'STAFF' ? 'Nhân viên' : 'Silver'),
      isActive: active,
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'avatar': avatar,
      'role': role.name.toUpperCase(),
      'points': points,
      'membershipTier': membershipTier,
    };
  }
}
