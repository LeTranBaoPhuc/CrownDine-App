import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../admin/admin_main_screen.dart';
import '../customer/customer_main_screen.dart';
import '../settings/server_config_screen.dart';
import '../staff/staff_main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'johncena');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ tài khoản và mật khẩu')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(username, password);
    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user?.role == UserRole.admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      } else if (user?.role == UserRole.staff) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StaffMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        );
      }
    }
  }

  void _fillDemo(String user, String pass) {
    setState(() {
      _usernameController.text = user;
      _passwordController.text = pass;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_ethernet),
            tooltip: 'Cài đặt IP máy chủ',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ServerConfigScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Crown Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.white, size: 42),
                ),
              ),
              const SizedBox(height: 16),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Crown',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const TextSpan(
                      text: 'Dine',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hệ thống quản lý & Đặt bàn nhà hàng thông minh',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Inputs
              AppTextField(
                label: 'Tên đăng nhập / Email',
                hint: 'khachhang hoặc nhanvien',
                controller: _usernameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Mật khẩu',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              if (authState.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  authState.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: 'Đăng nhập',
                isLoading: authState.isLoading,
                onPressed: _submitLogin,
              ),
              const SizedBox(height: 20),

              // Quick Demo Fill Buttons
              const Text(
                'Tài khoản đăng nhập hệ thống (Mật khẩu: 123456):',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.person, size: 16),
                    label: const Text('Khách hàng (johncena)'),
                    onPressed: () => _fillDemo('johncena', '123456'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.badge, size: 16),
                    label: const Text('Nhân viên (nguyenkhoa)'),
                    onPressed: () => _fillDemo('nguyenkhoa', '123456'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFF6366F1)),
                    label: const Text('Quản trị viên (johndoe)'),
                    onPressed: () => _fillDemo('johndoe', '123456'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản? ', style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
