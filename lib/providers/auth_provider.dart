import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../core/network/api_client.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isChecking;
  final String? errorMessage;
  final UserRole activeRole;

  AuthState({
    this.user,
    this.isLoading = false,
    this.isChecking = false,
    this.errorMessage,
    UserRole? activeRole,
  }) : activeRole = activeRole ?? user?.role ?? UserRole.customer;

  bool get isAuthenticated => user != null;
  bool get isStaff =>
      user != null &&
      activeRole == UserRole.staff &&
      (user!.role == UserRole.staff || user!.role == UserRole.admin);
  bool get isAdmin =>
      user?.role == UserRole.admin && activeRole == UserRole.admin;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isChecking,
    String? errorMessage,
    UserRole? activeRole,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isChecking: isChecking ?? this.isChecking,
      errorMessage: errorMessage,
      activeRole: activeRole ?? this.activeRole,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  int _generation = 0;
  late final void Function() _expire;

  AuthNotifier(this._repo) : super(AuthState(user: null, isChecking: true)) {
    _expire = () {
      if (mounted) {
        _generation++;
        state = AuthState();
      }
    };
    ApiClient.instance.onSessionExpired = _expire;
    checkAuthStatus();
  }

  /// Kiểm tra trạng thái đăng nhập từ JWT Token đã lưu
  @override
  void dispose() {
    if (identical(ApiClient.instance.onSessionExpired, _expire))
      ApiClient.instance.onSessionExpired = null;
    super.dispose();
  }

  Future<void> checkAuthStatus() async {
    final generation = _generation;
    try {
      final user = await _repo.getProfile();
      if (mounted && generation == _generation) state = AuthState(user: user);
    } catch (_) {
      if (mounted && generation == _generation) state = AuthState();
    }
  }

  /// Reload the point balance after a successful voucher exchange.
  Future<void> refreshProfile() async {
    final currentUserId = state.user?.id;
    if (currentUserId == null) return;
    final user = await _repo.getProfile();
    if (user == null) throw StateError('Không tải được số điểm hiện tại.');
    if (state.user?.id == currentUserId && user.id == currentUserId) {
      state = state.copyWith(user: user);
    }
  }

  /// Đăng nhập qua API
  Future<bool> login(String username, String password) async {
    final generation = ++_generation;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.login(username: username, password: password);
      if (!mounted || generation != _generation) return false;
      state = state.copyWith(
        user: user,
        isLoading: false,
        activeRole: user.role,
      );
      return true;
    } catch (e) {
      if (!mounted || generation != _generation) return false;
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
    final generation = ++_generation;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _repo.loginWithGoogle();
      if (!mounted || generation != _generation) return false;
      state = state.copyWith(
        user: user,
        isLoading: false,
        activeRole: user.role,
      );
      return true;
    } catch (e) {
      if (!mounted || generation != _generation) return false;
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
    final generation = ++_generation;
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
      if (!mounted || generation != _generation) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      if (!mounted || generation != _generation) return false;
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
    final actual = state.user?.role;
    if (actual == null ||
        (role != actual &&
            actual != UserRole.admin &&
            role != UserRole.customer)) return;
    state = state.copyWith(activeRole: role);
  }

  /// Đăng xuất tài khoản
  Future<void> logout() async {
    _generation++;
    state = AuthState(user: null);
    await _repo.logout();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
