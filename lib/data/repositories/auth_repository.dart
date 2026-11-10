import 'package:flutter/foundation.dart';
import '../../core/network/api_response.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client = ApiClient.instance;
  int _attempt = 0;

  /// Đăng nhập bằng Google
  Future<UserModel> loginWithGoogle() async {
    final attempt = ++_attempt;
    final server = await ApiConfig.getBaseUrl();
    try {
      final clientId = await ApiConfig.getGoogleClientId();
      if (clientId.isEmpty) {
        throw Exception(
          'Chưa cấu hình Google Client ID. Vui lòng cấu hình qua --dart-define hoặc trong Cài đặt máy chủ.',
        );
      }

      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? clientId : null,
        serverClientId: kIsWeb ? null : clientId,
        scopes: ['email'],
      );

      // 1. Mở popup đăng nhập tài khoản Google
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        throw Exception('Đã hủy đăng nhập Google.');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final token = auth.idToken;

      if (token == null || token.isEmpty) {
        throw Exception('Không nhận được mã xác thực từ Google.');
      }

      // 3. Gửi token lên backend /api/auth/google-login
      final response = await _client.dio.post(
        ApiEndpoints.googleLogin,
        data: {
          'token': token,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final accessToken = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        final respUsername = data['username'] ?? account.email;

        if (accessToken is! String ||
            accessToken.isEmpty ||
            refreshToken is! String ||
            refreshToken.isEmpty)
          throw const FormatException(
              'Máy chủ không trả về phiên đăng nhập hợp lệ.');
        final prefs = await SharedPreferences.getInstance();
        if (attempt != _attempt || await ApiConfig.getBaseUrl() != server)
          throw StateError('Phiên đăng nhập hoặc máy chủ đã thay đổi.');
        await Future.wait([
          prefs.setString('access_token', accessToken),
          prefs.setString('refresh_token', refreshToken),
          prefs.setString('username', respUsername)
        ]);

        final profile =
            responseData(await _client.dio.get(ApiEndpoints.profile));
        if (attempt != _attempt || await ApiConfig.getBaseUrl() != server)
          throw StateError('Phiên đăng nhập hoặc máy chủ đã thay đổi.');
        return UserModel.fromJson(Map<String, dynamic>.from(profile));
      }

      throw Exception('Đăng nhập Google thất bại');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  /// Đăng nhập tài khoản
  Future<UserModel> login(
      {required String username, required String password}) async {
    final attempt = ++_attempt;
    final server = await ApiConfig.getBaseUrl();
    try {
      final response = await _client.dio.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final accessToken = data['accessToken'] ?? '';
        final refreshToken = data['refreshToken'] ?? '';
        final respUsername = data['username'] ?? username;

        if (accessToken is! String ||
            accessToken.isEmpty ||
            refreshToken is! String ||
            refreshToken.isEmpty)
          throw const FormatException(
              'Máy chủ không trả về phiên đăng nhập hợp lệ.');
        final prefs = await SharedPreferences.getInstance();
        if (attempt != _attempt || await ApiConfig.getBaseUrl() != server)
          throw StateError('Phiên đăng nhập hoặc máy chủ đã thay đổi.');
        await Future.wait([
          prefs.setString('access_token', accessToken),
          prefs.setString('refresh_token', refreshToken),
          prefs.setString('username', respUsername)
        ]);

        // Fetch user profile from Backend
        final profileRes = await _client.dio.get(ApiEndpoints.profile);
        if (profileRes.statusCode == 200 && profileRes.data != null) {
          if (attempt != _attempt || await ApiConfig.getBaseUrl() != server)
            throw StateError('Phiên đăng nhập đã thay đổi.');
          final profileData = profileRes.data['data'] ?? profileRes.data;
          return UserModel.fromJson(profileData);
        }

        throw const FormatException('Không tải được hồ sơ tài khoản.');
      }

      throw Exception('Đăng nhập không thành công');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Đăng ký tài khoản
  Future<String> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
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
        final message = response.data?['message'] ??
            'Đăng ký thành công! Vui lòng nhập mã OTP được gửi về email.';
        return message;
      }

      throw Exception(response.data?['message'] ?? 'Đăng ký thất bại');
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Xác thực OTP khi đăng ký
  Future<String> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.registerVerifyOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );
      return response.data?['message'] ??
          'Xác thực tài khoản thành công! Bạn có thể đăng nhập ngay.';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Gửi lại OTP khi đăng ký
  Future<String> resendRegisterOtp({
    required String email,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.registerResendOtp,
        data: {
          'email': email,
        },
      );
      return response.data?['message'] ??
          'Mã OTP mới đã được gửi vào email của bạn.';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Cấp phát token mới qua Refresh Token
  Future<String?> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      final response = await _client.dio.post(
        ApiEndpoints.refreshToken,
        options: Options(
          headers: {'X-Refresh-Token': refreshToken},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        final newAccessToken = data['accessToken'] ?? '';
        final newRefreshToken = data['refreshToken'] ?? refreshToken;

        if (newAccessToken.isNotEmpty) {
          await prefs.setString('access_token', newAccessToken);
          await prefs.setString('refresh_token', newRefreshToken);
          return newAccessToken;
        }
      }
    } catch (_) {
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    }
    return null;
  }

  /// Lấy thông tin profile người dùng hiện tại
  Future<UserModel?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) return null;

    try {
      final profileRes = await _client.dio.get(ApiEndpoints.profile);
      if (profileRes.statusCode == 200 && profileRes.data != null) {
        final profileData = profileRes.data['data'] ?? profileRes.data;
        return UserModel.fromJson(profileData);
      }
    } catch (_) {
      // ApiClient owns refresh and preserves credentials on temporary failures.
    }
    return null;
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    _attempt++;
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('username');

    try {
      final clientId = await ApiConfig.getGoogleClientId();
      final googleSignIn =
          GoogleSignIn(clientId: clientId.isNotEmpty ? clientId : null);
      await googleSignIn.signOut();
    } catch (_) {}

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _client.dio.post(
          ApiEndpoints.logout,
          options: Options(
            headers: {'X-Refresh-Token': refreshToken},
          ),
        );
      }
    } catch (_) {}
  }

  /// Gửi OTP quên mật khẩu
  Future<String> sendForgotPasswordOtp(String email) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.forgotPasswordSendOtp,
        data: {'email': email},
      );
      return response.data?['message'] ??
          'Mã OTP đã được gửi đến email của bạn';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Xác thực mã OTP quên mật khẩu
  Future<bool> verifyForgotPasswordOtp(
      {required String email, required String otp}) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.forgotPasswordVerifyOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Đặt lại mật khẩu mới bằng OTP
  Future<String> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.forgotPasswordResetByOtp,
        data: {
          'email': email,
          'otp': otp,
          'password': password,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data?['message'] ??
          'Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Cập nhật thông tin hồ sơ cá nhân
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    required String gender,
    required String dateOfBirth, // format "dd/MM/yyyy"
  }) async {
    try {
      final response = await _client.dio.put(
        ApiEndpoints.updateProfile,
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'gender': gender,
          'dateOfBirth': dateOfBirth,
        },
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> sendEmailOtp(String email) async {
    responseData(await _client.dio
        .post(ApiEndpoints.sendEmailOtp, data: {'newEmail': email}));
  }

  Future<void> verifyEmailOtp(String email, String otp) async {
    responseData(await _client.dio.post(ApiEndpoints.verifyEmailOtp,
        data: {'newEmail': email, 'otp': otp}));
  }

  Future<void> uploadAvatar(Uint8List bytes, String name) async {
    responseData(await _client.dio.patch(ApiEndpoints.uploadAvatar,
        data: FormData.fromMap(
            {'image': MultipartFile.fromBytes(bytes, filename: name)})));
  }

  /// Đổi mật khẩu tài khoản
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.changePassword,
        data: {
          'oldPassword': currentPassword,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmPassword,
          'confirmPassword': confirmPassword,
        },
      );
      return response.data?['message'] ?? 'Đổi mật khẩu thành công';
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  /// Trích xuất thông báo lỗi từ Backend API
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          final msg = data['message'].toString();
          if (msg == 'auth.bad_credentials') {
            return 'Tên đăng nhập hoặc mật khẩu không chính xác';
          }
          if (msg == 'auth.username_exists') {
            return 'Tên đăng nhập đã tồn tại trong hệ thống';
          }
          if (msg == 'auth.email_exists') {
            return 'Email đã được sử dụng bởi tài khoản khác';
          }
          if (msg == 'auth.phone_exists') {
            return 'Số điện thoại đã được đăng ký';
          }
          if (msg == 'auth.confirm_password_mismatch') {
            return 'Mật khẩu xác nhận không khớp';
          }
          return msg;
        }
        if (data['error'] != null) return data['error'].toString();
      }
    }

    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'Tên đăng nhập hoặc mật khẩu không chính xác';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Không thể kết nối đến máy chủ Backend (http://localhost:8080). Vui lòng đảm bảo backend đang chạy.';
    }

    return e.message ?? 'Đã có lỗi xảy ra trong quá trình xử lý';
  }
}
