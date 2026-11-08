import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _gender = 'MALE';
  DateTime? _selectedDob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _phoneController.text = user.phone ?? '';
      _gender = user.gender ?? 'MALE';
      _selectedDob = DateTime.tryParse(user.dateOfBirth ?? '');
      if (_selectedDob == null && user.dateOfBirth != null) {
        try {
          _selectedDob =
              DateFormat('dd/MM/yyyy').parseStrict(user.dateOfBirth!);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _handleSave() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showSnackbar('Vui lòng nhập đầy đủ họ và tên', isError: true);
      return;
    }

    if (_selectedDob == null) {
      _showSnackbar('Vui lòng chọn ngày sinh.', isError: true);
      return;
    }
    final dobString = _selectedDob != null
        ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
        : '';

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone.isNotEmpty ? phone : null,
        gender: _gender,
        dateOfBirth: dobString,
      );

      // Refresh current profile in provider
      await ref.read(authProvider.notifier).checkAuthStatus();

      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar('Cập nhật hồ sơ thành công!');

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    }
  }

  Future<void> _changeAvatar() async {
    if (_isLoading) return;
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
          requestFullMetadata: false);
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024)
        throw StateError('Vui lòng chọn ảnh nhỏ hơn 5 MB.');
      setState(() => _isLoading = true);
      await ref.read(authRepositoryProvider).uploadAvatar(bytes, image.name);
      await ref.read(authProvider.notifier).refreshProfile();
      if (mounted) _showSnackbar('Đã cập nhật ảnh đại diện.');
    } catch (e) {
      if (mounted) _showSnackbar(apiErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeEmail() async {
    final email = TextEditingController();
    final otp = TextEditingController();
    bool sent = false, busy = false;
    String? error;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Đổi email'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: email,
                        enabled: !sent && !busy,
                        keyboardType: TextInputType.emailAddress,
                        decoration:
                            const InputDecoration(labelText: 'Email mới')),
                    if (sent) ...[
                      const SizedBox(height: 12),
                      const Text(
                          'Nhập mã OTP đã gửi về email hiện tại. Mã có hiệu lực 5 phút.'),
                      TextField(
                          controller: otp,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration:
                              const InputDecoration(labelText: 'Mã OTP'))
                    ],
                    if (busy) const LinearProgressIndicator(),
                    if (error != null)
                      Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: busy ? null : () => Navigator.pop(context),
                        child: const Text('Đóng')),
                    FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email.text.trim())) {
                                  update(() => error = 'Email không hợp lệ.');
                                  return;
                                }
                                update(() {
                                  busy = true;
                                  error = null;
                                });
                                try {
                                  final repo = ref.read(authRepositoryProvider);
                                  if (!sent) {
                                    await repo.sendEmailOtp(email.text.trim());
                                    if (context.mounted)
                                      update(() => sent = true);
                                  } else {
                                    await repo.verifyEmailOtp(
                                        email.text.trim(), otp.text.trim());
                                    await ref
                                        .read(authProvider.notifier)
                                        .refreshProfile();
                                    if (context.mounted) Navigator.pop(context);
                                  }
                                } catch (e) {
                                  if (context.mounted)
                                    update(() => error = apiErrorMessage(e));
                                } finally {
                                  if (context.mounted)
                                    update(() => busy = false);
                                }
                              },
                        child: Text(sent ? 'Xác nhận đổi email' : 'Gửi mã OTP'))
                  ],
                )));
    email.dispose();
    otp.dispose();
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ cá nhân',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar section
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  ClipOval(
                    child: Image.network(
                      user?.avatarUrl ??
                          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&q=80',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: AppColors.primary.withOpacity(0.15),
                        child: const Icon(Icons.person,
                            size: 50, color: AppColors.primary),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                user?.username ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Center(
              child: Text(
                user?.email ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
              TextButton.icon(
                  onPressed: _isLoading ? null : _changeAvatar,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Đổi ảnh')),
              TextButton.icon(
                  onPressed: _isLoading ? null : _changeEmail,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('Đổi email')),
            ]),
            const SizedBox(height: 24),

            // Form container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Họ & tên đệm',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                hintText: 'Nguyễn Văn',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tên',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                hintText: 'An',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Số điện thoại liên hệ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '0912345678',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Giới tính',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _genderChoice('Nam', 'MALE'),
                      const SizedBox(width: 12),
                      _genderChoice('Nữ', 'FEMALE'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Ngày sinh',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _selectDateOfBirth,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.withOpacity(0.35)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              size: 20, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDob != null
                                ? DateFormat('dd/MM/yyyy').format(_selectedDob!)
                                : 'Chọn ngày sinh (dd/MM/yyyy)',
                            style: TextStyle(
                              color: _selectedDob != null
                                  ? null
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 20),
                label: const Text('Lưu thông tin hồ sơ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleSave,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderChoice(String label, String value) {
    final isSelected = _gender == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _gender = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.12)
                : Colors.transparent,
            border: Border.all(
              color:
                  isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
