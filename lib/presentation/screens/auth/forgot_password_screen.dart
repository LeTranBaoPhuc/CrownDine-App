import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // 1: Email, 2: OTP, 3: Reset Password
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Timer? _resendTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackbar('Vui lòng nhập địa chỉ email hợp lệ', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final msg = await repo.sendForgotPasswordOtp(email);
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
      _startTimer();
      _showSnackbar(msg);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showSnackbar('Vui lòng nhập đúng 6 chữ số mã OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.verifyForgotPasswordOtp(email: email, otp: otp);
      setState(() {
        _currentStep = 3;
        _isLoading = false;
      });
      _showSnackbar('Xác thực OTP thành công! Vui lòng thiết lập mật khẩu mới');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final pass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (pass.length < 6) {
      _showSnackbar('Mật khẩu mới tối thiểu 6 ký tự', isError: true);
      return;
    }
    if (pass != confirmPass) {
      _showSnackbar('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      final msg = await repo.resetPasswordWithOtp(
        email: email,
        otp: otp,
        password: pass,
        confirmPassword: confirmPass,
      );
      setState(() => _isLoading = false);
      _showSnackbar(msg);

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF141210), const Color(0xFF1F1A17), const Color(0xFF0F0E0C)]
                : [const Color(0xFFFBF8F5), const Color(0xFFF3ECE6), const Color(0xFFEDE4DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Back button & Title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Bảo mật tài khoản',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Crown Logo / Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.gold],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.lock_reset, color: Colors.white, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Khôi Phục Mật Khẩu',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currentStep == 1
                          ? 'Nhập email liên kết với tài khoản CrownDine để nhận mã xác thực OTP 6 số.'
                          : (_currentStep == 2
                              ? 'Mã OTP 6 số đã được gửi tới email ${_emailController.text}.'
                              : 'Tạo mật khẩu mới an toàn cho tài khoản của bạn.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Step Indicator
                    _buildStepIndicator(isDark),
                    const SizedBox(height: 24),

                    // Card Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_currentStep == 1) ..._buildStep1Fields(isDark),
                          if (_currentStep == 2) ..._buildStep2Fields(isDark),
                          if (_currentStep == 3) ..._buildStep3Fields(isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(1, 'Email', _currentStep >= 1, isDark),
        _stepLine(_currentStep >= 2, isDark),
        _stepCircle(2, 'Nhập OTP', _currentStep >= 2, isDark),
        _stepLine(_currentStep >= 3, isDark),
        _stepCircle(3, 'Đổi MK', _currentStep >= 3, isDark),
      ],
    );
  }

  Widget _stepCircle(int step, String label, bool active, bool isDark) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : (isDark ? Colors.grey[800] : Colors.grey[300]),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.gold : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: TextStyle(
                color: active ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? AppColors.primary : (isDark ? Colors.grey[500] : Colors.grey[600]),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active, bool isDark) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: active ? AppColors.primary : (isDark ? Colors.grey[800] : Colors.grey[300]),
    );
  }

  List<Widget> _buildStep1Fields(bool isDark) {
    return [
      Text(
        'Email tài khoản',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'vidu@crowndine.vn',
          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleSendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Gửi mã OTP qua Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ];
  }

  List<Widget> _buildStep2Fields(bool isDark) {
    return [
      Text(
        'Nhập mã OTP (6 số)',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
        decoration: InputDecoration(
          hintText: '123456',
          counterText: '',
          prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        ),
      ),
      const SizedBox(height: 12),

      // Countdown / Resend
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _secondsRemaining > 0 ? 'Mã hết hạn sau: ${_secondsRemaining}s' : 'Mã đã hết hạn',
            style: TextStyle(
              fontSize: 12,
              color: _secondsRemaining > 0 ? AppColors.textSecondary : AppColors.error,
            ),
          ),
          TextButton(
            onPressed: (_secondsRemaining == 0 && !_isLoading) ? _handleSendOtp : null,
            child: const Text('Gửi lại mã OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
      const SizedBox(height: 16),

      SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleVerifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Xác thực OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ];
  }

  List<Widget> _buildStep3Fields(bool isDark) {
    return [
      Text(
        'Mật khẩu mới',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          hintText: 'Tối thiểu 6 ký tự',
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        ),
      ),
      const SizedBox(height: 14),

      Text(
        'Xác nhận mật khẩu mới',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: InputDecoration(
          hintText: 'Nhập lại mật khẩu mới',
          prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primary, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 18),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        ),
      ),
      const SizedBox(height: 20),

      SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Hoàn tất đặt lại mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ),
    ];
  }
}
