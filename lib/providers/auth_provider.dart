import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/mock/mock_data.dart';

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

  AuthNotifier(this._repo) : super(AuthState(user: MockData.customerUser));

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
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Đăng nhập không thành công: ${e.toString()}',
      );
      return false;
    }
  }

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
      final user = await _repo.register(
        username: username,
        email: email,
        password: password,
        phone: phone,
        firstName: firstName,
        lastName: lastName,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        activeRole: user.role,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Đăng ký không thành công: ${e.toString()}',
      );
      return false;
    }
  }

  void switchRole(UserRole role) {
    if (role == UserRole.admin) {
      state = state.copyWith(
        user: MockData.adminUser,
        activeRole: UserRole.admin,
      );
    } else if (role == UserRole.staff) {
      state = state.copyWith(
        user: MockData.staffUser,
        activeRole: UserRole.staff,
      );
    } else {
      state = state.copyWith(
        user: MockData.customerUser,
        activeRole: UserRole.customer,
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
