import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/user_model.dart';

final staffRepositoryProvider = Provider<StaffRepository>((ref) => StaffRepository());

class StaffRepository {
  final ApiClient _client = ApiClient.instance;

  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'].toString();
      }
    }
    return e.message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại sau.';
  }

  /// Lấy danh sách toàn bộ nhân viên
  Future<List<UserModel>> getAllStaffs() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.adminStaffAll);
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data['data'] as List?) ?? (response.data as List?);
        if (list != null) {
          return list.map((e) => UserModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) {
        if (e is DioException) throw Exception(_extractErrorMessage(e));
        rethrow;
      }
    }

    return List<UserModel>.from(MockData.staffList);
  }

  /// Tìm kiếm nhân viên theo tên
  Future<List<UserModel>> searchStaff(String query) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(
        ApiEndpoints.adminStaffSearch,
        queryParameters: {'name': query},
      );
      if (response.statusCode == 200 && response.data != null) {
        final pageData = response.data['data'] ?? response.data;
        final list = (pageData['content'] as List?) ?? (pageData as List?);
        if (list != null) {
          return list.map((e) => UserModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) {
        if (e is DioException) throw Exception(_extractErrorMessage(e));
        rethrow;
      }
    }

    return MockData.staffList
        .where((s) => s.fullName.toLowerCase().contains(query.toLowerCase()) ||
                      s.email.toLowerCase().contains(query.toLowerCase()) ||
                      s.username.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  String? _toIsoDate(String? d) {
    if (d == null || d.trim().isEmpty) return null;
    final parts = d.trim().split('/');
    if (parts.length == 3) {
      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2];
      return '$year-$month-$day';
    }
    return d.trim();
  }

  String _toSlashDate(String? d) {
    if (d == null || d.trim().isEmpty) return '01/01/2000';
    final parts = d.trim().split('-');
    if (parts.length == 3) {
      final year = parts[0];
      final month = parts[1].padLeft(2, '0');
      final day = parts[2].padLeft(2, '0');
      return '$day/$month/$year';
    }
    return d.trim();
  }

  /// Tạo nhân viên mới
  Future<UserModel> createStaff({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? dateOfBirth,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();
    final isoDate = _toIsoDate(dateOfBirth);
    final body = {
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (isoDate != null) 'dateOfBirth': isoDate,
    };

    try {
      final response = await _client.dio.post(ApiEndpoints.adminStaff, data: body);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return UserModel.fromJson(data);
      }
      throw Exception(response.data?['message'] ?? 'Tạo nhân viên thất bại');
    } catch (e) {
      if (!useMock) {
        if (e is DioException) throw Exception(_extractErrorMessage(e));
        rethrow;
      }
    }

    final newStaff = UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      gender: gender,
      dateOfBirth: dateOfBirth,
      role: UserRole.staff,
      membershipTier: 'Nhân viên',
      isActive: true,
    );
    MockData.staffList.insert(0, newStaff);
    return newStaff;
  }

  /// Cập nhật thông tin nhân viên
  Future<UserModel> updateStaff({
    required int id,
    required String firstName,
    required String lastName,
    String? phone,
    String? gender,
    String? dateOfBirth,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();
    final slashDate = _toSlashDate(dateOfBirth);
    final body = {
      'firstName': firstName,
      'lastName': lastName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'gender': (gender != null && gender.isNotEmpty) ? gender : 'MALE',
      'dateOfBirth': slashDate,
    };

    try {
      final response = await _client.dio.put(ApiEndpoints.adminStaffById(id), data: body);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return UserModel.fromJson(data);
      }
      throw Exception(response.data?['message'] ?? 'Cập nhật nhân viên thất bại');
    } catch (e) {
      if (!useMock) {
        if (e is DioException) throw Exception(_extractErrorMessage(e));
        rethrow;
      }
    }

    final idx = MockData.staffList.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final updated = MockData.staffList[idx].copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
      );
      MockData.staffList[idx] = updated;
      return updated;
    }
    throw Exception('Không tìm thấy nhân viên');
  }

  /// Thay đổi trạng thái nhân viên (ACTIVE / INACTIVE)
  Future<bool> changeStaffStatus({
    required int id,
    required bool isActive,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();
    final statusStr = isActive ? 'ACTIVE' : 'INACTIVE';

    try {
      final response = await _client.dio.patch(
        ApiEndpoints.adminStaffStatus(id),
        queryParameters: {'status': statusStr},
      );
      return response.statusCode == 200;
    } catch (e) {
      if (!useMock) {
        if (e is DioException) throw Exception(_extractErrorMessage(e));
        rethrow;
      }
    }

    final idx = MockData.staffList.indexWhere((s) => s.id == id);
    if (idx != -1) {
      MockData.staffList[idx] = MockData.staffList[idx].copyWith(isActive: isActive);
      return true;
    }
    return false;
  }

  /// Xóa nhân viên
  Future<bool> deleteStaff(int id) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.delete(ApiEndpoints.adminStaffById(id));
      return response.statusCode == 200;
    } catch (e) {
      if (!useMock) {
        if (e is DioException) throw Exception(_extractErrorMessage(e));
        rethrow;
      }
    }

    MockData.staffList.removeWhere((s) => s.id == id);
    return true;
  }
}
