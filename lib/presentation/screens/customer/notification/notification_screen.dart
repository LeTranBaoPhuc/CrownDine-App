import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/notification_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../widgets/crown_app_bar.dart';
import '../../auth/login_screen.dart';
import '../profile/reservation_history_screen.dart';
import '../profile/voucher_wallet_sheet.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  // 0: All, 1: Unread only, 2: Reservation only, 3: Voucher only
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifState = ref.watch(notificationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF100E0C) : const Color(0xFFF9FAFB),
      appBar: CrownAppBar(
        title: 'Thông Báo',
        showCart: false,
        actions: [
          if (authState.isAuthenticated && notifState.unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: const Text(
                'Đọc tất cả',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: !authState.isAuthenticated
          ? _buildGuestView(context, isDark)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(notificationProvider.notifier).loadNotifications(),
              child: notifState.isLoading && notifState.notifications.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 14),
                          Text('Đang tải thông báo...', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : _buildContent(context, notifState, isDark),
            ),
    );
  }

  Widget _buildGuestView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Đăng nhập để xem thông báo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhận các cập nhật quan trọng về lịch đặt bàn, ưu đãi giảm giá và voucher quà tặng từ CrownDine.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng nhập ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, NotificationState notifState, bool isDark) {
    final allList = notifState.notifications;
    final filteredList = allList.where((item) {
      if (_selectedFilter == 1) return !item.isRead;
      if (_selectedFilter == 2) return item.isReservation;
      if (_selectedFilter == 3) return item.isVoucher;
      return true;
    }).toList();

    return CustomScrollView(
      slivers: [
        // Filter Chips Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Tất cả (${allList.length})',
                    isSelected: _selectedFilter == 0,
                    onTap: () => setState(() => _selectedFilter = 0),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Chưa đọc (${notifState.unreadCount})',
                    isSelected: _selectedFilter == 1,
                    onTap: () => setState(() => _selectedFilter = 1),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Đặt bàn (${allList.where((n) => n.isReservation).length})',
                    isSelected: _selectedFilter == 2,
                    onTap: () => setState(() => _selectedFilter = 2),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Voucher (${allList.where((n) => n.isVoucher).length})',
                    isSelected: _selectedFilter == 3,
                    onTap: () => setState(() => _selectedFilter = 3),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Notification List or Empty State
        if (filteredList.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(isDark),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final notif = filteredList[index];
                  return _buildNotificationCard(context, notif, isDark);
                },
                childCount: filteredList.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF26201B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textLight : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF201B18) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _selectedFilter == 1 ? 'Không có thông báo chưa đọc' : 'Chưa có thông báo nào',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Khi có cập nhật về lịch đặt bàn hoặc mã voucher mới, thông báo sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationModel notif, bool isDark) {
    final isUnread = !notif.isRead;

    // Distinct theme per type
    IconData iconData = Icons.notifications_rounded;
    Color iconColor = AppColors.primary;
    Color iconBg = AppColors.primary.withValues(alpha: 0.12);

    if (notif.isReservation) {
      iconData = Icons.table_restaurant_rounded;
      iconColor = const Color(0xFF6366F1); // Indigo
      iconBg = const Color(0xFF6366F1).withValues(alpha: 0.12);
    } else if (notif.isVoucher) {
      iconData = Icons.confirmation_number_rounded;
      iconColor = AppColors.gold;
      iconBg = AppColors.gold.withValues(alpha: 0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? (isDark ? const Color(0xFF251C17) : const Color(0xFFFFF9F5))
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isUnread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Mark as read
          if (isUnread) {
            ref.read(notificationProvider.notifier).markAsRead(notif.id);
          }
          // Navigate if relevant
          _handleNotificationNavigation(context, notif);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),

              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            notif.typeDisplayName,
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notif.timeAgo,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        color: isDark ? AppColors.textLight : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),

                    // Quick Action Link
                    if (notif.isReservation || notif.isVoucher) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            notif.isReservation ? 'Xem lịch sử đặt bàn' : 'Xem Ví Voucher',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 10, color: iconColor),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationNavigation(BuildContext context, NotificationModel notif) {
    if (notif.isReservation) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReservationHistoryScreen()),
      );
    } else if (notif.isVoucher) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const VoucherWalletSheet(),
      );
    }
  }
}

