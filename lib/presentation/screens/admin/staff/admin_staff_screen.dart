import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/staff_repository.dart';

class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  List<UserModel> _staffList = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currentFilter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStaffs();
  }

  Future<void> _loadStaffs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ref.read(staffRepositoryProvider).getAllStaffs();
      if (mounted) {
        setState(() {
          _staffList = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showAddStaffSheet() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final dobController = TextEditingController();
    String selectedGender = 'MALE';
    bool obscurePassword = true;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Thêm Nhân Sự Mới',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Username & Password
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: usernameController,
                              decoration: InputDecoration(
                                labelText: 'Tên đăng nhập *',
                                hintText: 'vd: nhanvien01',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.account_circle_outlined, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setSheetState(() => obscurePassword = !obscurePassword);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // First & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                labelText: 'Họ và tên đệm *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Tên *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Email & Phone
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email liên hệ / nội bộ *',
                          hintText: 'vd: staff@crowndine.vn',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: dobController,
                              decoration: InputDecoration(
                                labelText: 'Ngày sinh (dd/MM/yyyy)',
                                hintText: '01/01/2000',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Gender selection
                      Row(
                        children: [
                          const Text('Giới tính:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'MALE',
                                groupValue: selectedGender,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedGender = val);
                                },
                              ),
                              const Text('Nam'),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'FEMALE',
                                groupValue: selectedGender,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedGender = val);
                                },
                              ),
                              const Text('Nữ'),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final username = usernameController.text.trim();
                                  final password = passwordController.text.trim();
                                  final firstName = firstNameController.text.trim();
                                  final lastName = lastNameController.text.trim();
                                  final email = emailController.text.trim();

                                  if (username.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng điền đầy đủ các thông tin bắt buộc (*)'),
                                        backgroundColor: AppColors.warning,
                                      ),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSubmitting = true);

                                  try {
                                    await ref.read(staffRepositoryProvider).createStaff(
                                      username: username,
                                      password: password,
                                      firstName: firstName,
                                      lastName: lastName,
                                      email: email,
                                      phone: phoneController.text.trim(),
                                      gender: selectedGender,
                                      dateOfBirth: dobController.text.trim(),
                                    );

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã thêm nhân viên $firstName $lastName thành công!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      _loadStaffs();
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString().replaceAll('Exception: ', '')),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Lưu Hồ Sơ Nhân Viên',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditStaffSheet(UserModel staff) {
    final firstNameController = TextEditingController(text: staff.firstName ?? '');
    final lastNameController = TextEditingController(text: staff.lastName ?? '');
    final phoneController = TextEditingController(text: staff.phone ?? '');
    final dobController = TextEditingController(text: staff.dateOfBirth ?? '');
    String selectedGender = staff.gender == 'FEMALE' ? 'FEMALE' : 'MALE';
    bool isActive = staff.isActive;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Chỉnh Sửa Nhân Sự',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Username & Email (read-only tags)
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.lightBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tài khoản', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(staff.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.lightBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Email', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(staff.email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // First & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: firstNameController,
                              decoration: InputDecoration(
                                labelText: 'Họ và tên đệm *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Tên *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Số điện thoại',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: dobController,
                              decoration: InputDecoration(
                                labelText: 'Ngày sinh (dd/MM/yyyy)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Gender selection
                      Row(
                        children: [
                          const Text('Giới tính:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'MALE',
                                groupValue: selectedGender,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedGender = val);
                                },
                              ),
                              const Text('Nam'),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Radio<String>(
                                value: 'FEMALE',
                                groupValue: selectedGender,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  if (val != null) setSheetState(() => selectedGender = val);
                                },
                              ),
                              const Text('Nữ'),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Switch
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.pause_circle_filled,
                                  color: isActive ? AppColors.success : AppColors.error,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isActive ? 'Đang làm việc (Hoạt động)' : 'Đã ngưng việc (Xóa mềm)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? AppColors.success : AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: isActive,
                              activeThumbColor: AppColors.success,
                              onChanged: (val) {
                                setSheetState(() => isActive = val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final firstName = firstNameController.text.trim();
                                  final lastName = lastNameController.text.trim();

                                  if (firstName.isEmpty || lastName.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Vui lòng nhập họ và tên!'),
                                        backgroundColor: AppColors.warning,
                                      ),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSubmitting = true);

                                  try {
                                    final repo = ref.read(staffRepositoryProvider);
                                    await repo.updateStaff(
                                      id: staff.id,
                                      firstName: firstName,
                                      lastName: lastName,
                                      phone: phoneController.text.trim(),
                                      gender: selectedGender,
                                      dateOfBirth: dobController.text.trim(),
                                    );

                                    if (isActive != staff.isActive) {
                                      await repo.changeStaffStatus(id: staff.id, isActive: isActive);
                                    }

                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Cập nhật nhân viên $firstName $lastName thành công!'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      _loadStaffs();
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.toString().replaceAll('Exception: ', '')),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Cập Nhật Thông Tin',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmSoftDelete(UserModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
            SizedBox(width: 8),
            Text('Xác nhận xóa mềm?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn ngưng hoạt động nhân viên "${staff.fullName}"?',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tài khoản sẽ chuyển sang trạng thái "Đã xóa mềm" (INACTIVE), ngưng quyền truy cập nhưng toàn bộ lịch sử phục vụ và dữ liệu hệ thống vẫn được bảo lưu trọn vẹn.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performSoftDelete(staff);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xác nhận xóa mềm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _performSoftDelete(UserModel staff) async {
    try {
      await ref.read(staffRepositoryProvider).changeStaffStatus(id: staff.id, isActive: false);
      if (!mounted) return;
      _loadStaffs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã ngưng hoạt động nhân viên ${staff.fullName} (xóa mềm).'),
          backgroundColor: AppColors.secondary,
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: AppColors.gold,
            onPressed: () => _restoreStaff(staff),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _restoreStaff(UserModel staff) async {
    try {
      await ref.read(staffRepositoryProvider).changeStaffStatus(id: staff.id, isActive: true);
      if (!mounted) return;
      _loadStaffs();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã khôi phục hoạt động cho nhân viên ${staff.fullName}!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _confirmHardDelete(UserModel staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Xóa vĩnh viễn?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản "${staff.fullName}"?',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cảnh báo: Dữ liệu tài khoản sẽ bị xóa hoàn toàn khỏi cơ sở dữ liệu. Nếu nhân viên này đã phát sinh đơn hàng, bàn ăn hoặc dữ liệu hệ thống, máy chủ sẽ yêu cầu dùng Xóa mềm.',
                      style: TextStyle(fontSize: 12, color: AppColors.error, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(staffRepositoryProvider).deleteStaff(staff.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã xóa vĩnh viễn nhân viên ${staff.fullName}.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadStaffs();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeCount = _staffList.where((s) => s.isActive).length;
    final inactiveCount = _staffList.where((s) => !s.isActive).length;

    // Apply Filter & Search query
    var filteredList = _staffList;
    if (_currentFilter == 'ACTIVE') {
      filteredList = _staffList.where((s) => s.isActive).toList();
    } else if (_currentFilter == 'INACTIVE') {
      filteredList = _staffList.where((s) => !s.isActive).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filteredList = filteredList.where((s) {
        return s.fullName.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            s.username.toLowerCase().contains(q) ||
            (s.phone != null && s.phone!.contains(q));
      }).toList();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStaffs,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Royal Stats Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.darkCard, AppColors.darkBackground]
                        : [AppColors.secondary, const Color(0xFF201B18)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStaffStat(
                      icon: Icons.people_alt_outlined,
                      label: 'Tổng nhân sự',
                      value: '${_staffList.length}',
                      color: Colors.white,
                    ),
                    Container(height: 40, width: 1, color: Colors.white12),
                    _buildStaffStat(
                      icon: Icons.check_circle_outline,
                      label: 'Đang làm việc',
                      value: '$activeCount',
                      color: AppColors.success,
                    ),
                    Container(height: 40, width: 1, color: Colors.white12),
                    _buildStaffStat(
                      icon: Icons.person_off_outlined,
                      label: 'Đã xóa mềm',
                      value: '$inactiveCount',
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Header & Add staff button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Danh Sách Nhân Viên',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Quản trị đội ngũ phục vụ & vận hành',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Làm mới danh sách',
                        onPressed: _loadStaffs,
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton.icon(
                        onPressed: _showAddStaffSheet,
                        icon: const Icon(Icons.person_add_alt_1, size: 16, color: Colors.white),
                        label: const Text('Thêm nhân viên', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email, tài khoản, số điện thoại...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter status chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tất cả (${_staffList.length})', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('ACTIVE', 'Đang làm việc ($activeCount)', isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('INACTIVE', 'Đã xóa mềm ($inactiveCount)', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loading or Error or List
              if (_isLoading && _staffList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (_errorMessage != null && _staffList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: AppColors.error),
                      const SizedBox(height: 10),
                      Text(
                        'Không thể tải danh sách nhân viên: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadStaffs,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                )
              else if (filteredList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      const Text(
                        'Không tìm thấy nhân viên phù hợp',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Thử đổi từ khóa tìm kiếm hoặc chọn bộ lọc khác',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => setState(() => _searchQuery = ''),
                          child: const Text('Xóa bộ lọc tìm kiếm'),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ...filteredList.map((staff) {
                  final isActive = staff.isActive;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                            : AppColors.error.withOpacity(0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar with active/inactive indicator
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              backgroundImage: staff.avatar != null && staff.avatar!.isNotEmpty
                                  ? NetworkImage(staff.avatar!)
                                  : null,
                              child: (staff.avatar == null || staff.avatar!.isEmpty)
                                  ? Text(
                                      staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : 'N',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.success : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? AppColors.darkCard : Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Staff info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      staff.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        decoration: isActive ? null : TextDecoration.lineThrough,
                                        color: isActive ? null : AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? AppColors.success.withOpacity(0.12)
                                          : AppColors.error.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isActive ? 'Đang làm việc' : 'Đã xóa mềm',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${staff.username}',
                                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    staff.phone?.isNotEmpty == true ? staff.phone! : 'Chưa cập nhật',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.email_outlined, size: 12, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      staff.email,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Action Buttons: Edit, Soft delete/Restore, Hard delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút Sửa
                            Tooltip(
                              message: 'Sửa thông tin',
                              child: InkWell(
                                onTap: () => _showEditStaffSheet(staff),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Nút Xóa mềm / Khôi phục
                            Tooltip(
                              message: isActive ? 'Ngưng việc (Xóa mềm)' : 'Khôi phục hoạt động',
                              child: InkWell(
                                onTap: () => isActive ? _confirmSoftDelete(staff) : _restoreStaff(staff),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isActive ? AppColors.warning : AppColors.success).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isActive ? Icons.person_off_outlined : Icons.restore_outlined,
                                    color: isActive ? AppColors.warning : AppColors.success,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Nút Xóa vĩnh viễn
                            Tooltip(
                              message: 'Xóa vĩnh viễn khỏi hệ thống',
                              child: InkWell(
                                onTap: () => _confirmHardDelete(staff),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _currentFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textLightSecondary : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.85)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
