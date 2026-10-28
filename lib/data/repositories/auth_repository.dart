import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client = ApiClient.instance;

  Future<UserModel> login({required String username, required String password}) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final accessToken = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);

        // Fetch profile
        final profileRes = await _client.dio.get(ApiEndpoints.profile);
        if (profileRes.statusCode == 200 && profileRes.data != null) {
          final profileData = profileRes.data['data'] ?? profileRes.data;
          return UserModel.fromJson(profileData);
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Fallback Mock Authentication
    if (username.toLowerCase().contains('staff') || username.toLowerCase().contains('nhanvien')) {
      return MockData.staffUser;
    }
    return MockData.customerUser;
  }

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'confirmPassword': password,
          'phone': phone,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      if (response.statusCode == 200) {
        return UserModel(
          id: 99,
          username: username,
          email: email,
          phone: phone,
          firstName: firstName,
          lastName: lastName,
          role: UserRole.customer,
        );
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return UserModel(
      id: 99,
      username: username,
      email: email,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      role: UserRole.customer,
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    try {
      await _client.dio.post(
        ApiEndpoints.logout,
        options: Options(
          headers: refreshToken != null ? {'X-Refresh-Token': refreshToken} : null,
        ),
      );
    } catch (_) {}

    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }
}
