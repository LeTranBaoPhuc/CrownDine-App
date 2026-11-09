import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../auth/login_screen.dart';
import '../customer_main_screen.dart';
import 'change_password_dialog.dart';
import 'edit_profile_screen.dart';
import 'reservation_history_screen.dart';
import 'reward_points_screen.dart';
import 'voucher_wallet_sheet.dart';
import '../favorite/favorites_screen.dart';
import '../notification/notification_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final avatarUrl = user?.avatarUrl;
    final notifState = ref.watch(notificationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CrownAppBar(
        title: 'Tài khoản CrownDine',
        showCart: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // USER INFO CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: (avatarUrl != null && avatarUrl.trim().isNotEmpty)
                        ? Image.network(
                            avatarUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 72,
                              height: 72,
                              color: AppColors.primary.withValues(alpha: 0.15),
                              child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                            ),
                          )
                        : Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName
                              : (user == null ? 'Khách ghé thăm' : 'Khách hàng CrownDine'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.phone ?? user?.email ?? (user == null ? 'Vui lòng đăng nhập tài khoản' : 'khachhang@crowndine.vn'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.membershipTier ?? (user == null ? 'Guest' : 'Member'),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MEMBERSHIP LOYALTY POINTS CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2B2623), Color(0xFF1E1815)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ĐIỂM TÍCH LŨY THÀNH VIÊN',
                          style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${user?.points ?? 0} CrownPoints',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) =>
                          user == null ? const LoginScreen() : const RewardPointsScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(user == null ? 'Đăng nhập' : 'Xem điểm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SETTINGS & ACTIONS LIST
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (user != null) ...[
                    _buildListTile(
                      icon: Icons.person_outline,
                      title: 'Thông tin cá nhân & Hồ sơ',
                      subtitle: 'Cập nhật họ tên, số điện thoại, ngày sinh',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      },
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      icon: Icons.lock_outline,
                      title: 'Đổi mật khẩu tài khoản',
                      subtitle: 'Thay đổi mật khẩu đăng nhập an toàn',
                      onTap: () {
                        ChangePasswordDialog.show(context);
                      },
                    ),
                    const Divider(height: 1),
                  ],
                  _buildListTile(
                    icon: Icons.favorite_outline_rounded,
                    title: 'Món ăn & Combo yêu thích',
                    subtitle: 'Danh sách món ăn bạn đã lưu',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Thông báo hệ thống',
                    subtitle: 'Cập nhật lịch đặt bàn, voucher & ưu đãi',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (notifState.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${notifState.unreadCount}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.history,
                    title: 'Lịch sử đặt bàn',
                    subtitle: 'Xem lại các lần đặt bàn trước đây',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationHistoryScreen()));
                    },
                  ),
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Ví Voucher & Ưu đãi',
                    subtitle: 'Xem voucher và sao chép mã ưu đãi',
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const VoucherWalletSheet(),
                      );
                    },
                  ),

                  const Divider(height: 1),
                  _buildListTile(
                    icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    title: isDark ? 'Chế độ Sáng' : 'Chế độ Tối (Dark mode)',
                    subtitle: 'Giao diện hiển thị sang trọng',
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // LOGOUT / LOGIN BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: user != null
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: AppColors.error),
                      label: const Text('Đăng xuất tài khoản', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const CustomerMainScreen(initialIndex: 0)),
                            (route) => false,
                          );
                        }
                      },
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.login, color: Colors.white),
                      label: const Text('Đăng nhập / Đăng ký', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
