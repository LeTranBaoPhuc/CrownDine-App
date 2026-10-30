import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;
  final UserRole activeRole;

  AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    UserRole? activeRole,
  }) : activeRole = activeRole ?? user?.role ?? UserRole.customer;

  bool get isAuthenticated => user != null;
  bool get isStaff => activeRole == UserRole.staff;
  bool get isAdmin => activeRole == UserRole.admin;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    UserRole? activeRole,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      activeRole: activeRole ?? this.activeRole,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthState(user: null)) {
    checkAuthStatus();
  }

  /// Kiểm tra trạng thái đăng nhập từ JWT Token đã lưu
  Future<void> checkAuthStatus() async {
    try {
      final user = await _repo.getProfile();
      if (user != null) {
        state = state.copyWith(
          user: user,
          activeRole: user.role,
        );
      }
    } catch (_) {}
  }

  /// Đăng nhập qua API
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.login(username: username, password: password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        activeRole: user.role,
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Đăng nhập bằng Google
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.loginWithGoogle();
      state = state.copyWith(
        user: user,
        isLoading: false,
        activeRole: user.role,
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Đăng ký qua API
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.register(
        username: username,
        email: email,
        password: password,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        errorMessage: msg,
      );
      return false;
    }
  }

  /// Chuyển đổi vai trò người dùng (cho tài khoản có nhiều quyền)
  void switchRole(UserRole role) {
    state = state.copyWith(activeRole: role);
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    await _repo.logout();
    state = AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
