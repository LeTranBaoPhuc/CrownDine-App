import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/theme_provider.dart';
import '../screens/settings/server_config_screen.dart';

class CrownAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final bool showRoleSwitcher;
  final bool showCart;
  final List<Widget>? actions;

  const CrownAppBar({
    super.key,
    this.title,
    this.showRoleSwitcher = true,
    this.showCart = true,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      titleSpacing: 16,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0.5,
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.gold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Crown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const TextSpan(
                            text: 'Dine',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Nhà hàng sang trọng',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
      actions: [
        if (showRoleSwitcher)
          GestureDetector(
            onTap: () => _showRoleSelectorSheet(context, ref, authState.activeRole),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: authState.isAdmin
                    ? AppColors.primary
                    : (authState.isStaff ? AppColors.secondary : AppColors.primary.withOpacity(0.12)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: authState.isAdmin
                      ? AppColors.gold
                      : (authState.isStaff ? AppColors.gold : AppColors.primary),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    authState.isAdmin
                        ? Icons.admin_panel_settings_outlined
                        : (authState.isStaff ? Icons.badge_outlined : Icons.person_outline),
                    size: 14,
                    color: (authState.isAdmin || authState.isStaff) ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    authState.activeRole.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: (authState.isAdmin || authState.isStaff) ? Colors.white : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: (authState.isAdmin || authState.isStaff) ? Colors.white70 : AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(width: 8),

        // Server Settings
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerConfigScreen()),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(7),
              child: Icon(Icons.settings_ethernet, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Theme Toggle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        if (showCart && !authState.isStaff)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                onPressed: () {
                  _showCartSheet(context, ref);
                },
              ),
              if (cartState.totalItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Center(
                      child: Text(
                        '${cartState.totalItemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    );
  }

  void _showRoleSelectorSheet(BuildContext context, WidgetRef ref, UserRole currentRole) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Material(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_horiz, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chuyển đổi phân hệ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Chọn vai trò để trải nghiệm tính năng tương ứng',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildRoleItem(
                ctx: ctx,
                ref: ref,
                role: UserRole.customer,
                title: 'Khách hàng (Customer)',
                description: 'Đặt bàn, duyệt thực đơn, ưu đãi voucher & giỏ hàng',
                icon: Icons.person_outline,
                color: AppColors.primary,
                isSelected: currentRole == UserRole.customer,
              ),
              const SizedBox(height: 10),
              _buildRoleItem(
                ctx: ctx,
                ref: ref,
                role: UserRole.staff,
                title: 'Nhân viên (Staff / POS)',
                description: 'Sơ đồ bàn trực quan, mở bàn gọi món & màn hình bếp KDS',
                icon: Icons.badge_outlined,
                color: AppColors.gold,
                isSelected: currentRole == UserRole.staff,
              ),
              const SizedBox(height: 10),
              _buildRoleItem(
                ctx: ctx,
                ref: ref,
                role: UserRole.admin,
                title: 'Quản trị viên (Admin Portal)',
                description: 'Dashboard doanh thu, quản lý thực đơn, voucher & nhân sự',
                icon: Icons.admin_panel_settings_outlined,
                color: const Color(0xFF6366F1),
                isSelected: currentRole == UserRole.admin,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildRoleItem({
    required BuildContext ctx,
    required WidgetRef ref,
    required UserRole role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(ctx);
        if (!isSelected) {
          ref.read(authProvider.notifier).switchRole(role);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Đã chuyển sang phân hệ: ${role.displayName}'),
              duration: const Duration(seconds: 1),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CartQuickSheet(),
    );
  }
}

class _CartQuickSheet extends ConsumerWidget {
  const _CartQuickSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giỏ món ăn (${cartState.totalItemCount})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (cartState.items.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(cartProvider.notifier).clear(),
                  child: const Text('Xóa tất cả', style: TextStyle(color: AppColors.error)),
                ),
            ],
          ),
          const Divider(),
          if (cartState.items.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 60, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text('Chưa có món ăn nào trong giỏ', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.separated(
                itemCount: cartState.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cartItem = cartState.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            cartItem.item.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50,
                              height: 50,
                              color: AppColors.lightSurface,
                              child: const Icon(Icons.fastfood, size: 24, color: AppColors.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cartItem.item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${cartItem.item.displayPrice.toStringAsFixed(0)} ₫',
                                style: const TextStyle(color: AppColors.primary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                          onPressed: () => ref.read(cartProvider.notifier).updateQuantity(cartItem.item.id, cartItem.quantity - 1),
                        ),
                        Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                          onPressed: () => ref.read(cartProvider.notifier).updateQuantity(cartItem.item.id, cartItem.quantity + 1),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng cộng:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${cartState.subtotal.toStringAsFixed(0)} ₫',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tiếp tục chọn món', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
