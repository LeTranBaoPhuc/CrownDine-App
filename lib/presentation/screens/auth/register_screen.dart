import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitRegister() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ các thông tin bắt buộc')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          username: username,
          email: email,
          phone: phone,
          firstName: firstName,
          lastName: lastName,
          password: password,
        );

    if (success && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Đăng ký thành công'),
            ],
          ),
          content: const Text(
            'Tài khoản của bạn đã được tạo thành công! Vui lòng kiểm tra email để kích hoạt tài khoản trước khi đăng nhập.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Quay về màn hình Login
              },
              child: const Text('Đến trang Đăng nhập'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký tài khoản')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gia nhập CrownDine Club',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nhận ngay voucher giảm 50.000₫ & tích điểm hạng thành viên cho lần đặt bàn đầu tiên.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Họ',
                      hint: 'Nguyễn',
                      controller: _lastNameController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Tên *',
                      hint: 'Văn An',
                      controller: _firstNameController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Tên đăng nhập *',
                hint: 'nguyenvanan',
                controller: _usernameController,
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Email *',
                hint: 'an.nguyen@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Số điện thoại *',
                hint: '0901234567',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Mật khẩu *',
                hint: 'Tối thiểu 6 ký tự',
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

              AppButton(
                text: 'Hoàn tất đăng ký',
                isLoading: authState.isLoading,
                onPressed: _submitRegister,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
