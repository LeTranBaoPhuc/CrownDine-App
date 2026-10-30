import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';


class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedRange = 'Hôm nay';
  final List<String> _ranges = ['Hôm nay', '7 ngày qua', 'Tháng này'];

  // Sample revenue data points for 7 days
  final List<double> _weeklyRevenues = [12.4, 15.8, 14.2, 19.5, 22.8, 28.4, 18.5]; // in millions VND
  final List<String> _days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Range Filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Báo Cáo & Thống Kê',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hiệu suất kinh doanh nhà hàng CrownDine',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Time Range Pills
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _ranges.map((range) {
                      final isSelected = _selectedRange == range;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRange = range),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            range,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // KPI Metrics Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                return GridView.count(
                  crossAxisCount: isWide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isWide ? 1.6 : 1.15,
                  children: [
                    _buildKpiCard(
                      title: 'Doanh thu',
                      value: _selectedRange == 'Hôm nay' ? '18.450.000 ₫' : '131.600.000 ₫',
                      trend: '+14.2%',
                      isPositive: true,
                      icon: Icons.payments_outlined,
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    _buildKpiCard(
                      title: 'Tổng đơn hàng',
                      value: _selectedRange == 'Hôm nay' ? '42 đơn' : '318 đơn',
                      trend: '+8.5%',
                      isPositive: true,
                      icon: Icons.receipt_long_outlined,
                      color: AppColors.gold,
                      isDark: isDark,
                    ),
                    _buildKpiCard(
                      title: 'Lượt thực khách',
                      value: _selectedRange == 'Hôm nay' ? '128 khách' : '890 khách',
                      trend: '+12.0%',
                      isPositive: true,
                      icon: Icons.people_outline,
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                    ),
                    _buildKpiCard(
                      title: 'Bàn đang phục vụ',
                      value: '8 / 12 bàn',
                      trend: '67% công suất',
                      isPositive: true,
                      icon: Icons.table_restaurant_outlined,
                      color: AppColors.success,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Revenue Chart Container
            _buildChartSection(isDark),
            const SizedBox(height: 24),

            // Best Selling Items Section
            _buildTopDishesSection(isDark),
            const SizedBox(height: 24),

            // Recent System Activities
            _buildRecentActivitiesSection(isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 13,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      trend,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.success : AppColors.error,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(bool isDark) {
    const maxVal = 30.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Biểu Đồ Doanh Thu Tuần Này',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đơn vị tính: Triệu VNĐ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Đỉnh điểm: T7 (28.4M)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom animated bars
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_weeklyRevenues.length, (index) {
                final rev = _weeklyRevenues[index];
                final heightRatio = (rev / maxVal).clamp(0.1, 1.0);
                final isHighest = rev == 28.4;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${rev.toStringAsFixed(1)}M',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isHighest ? FontWeight.bold : FontWeight.w500,
                        color: isHighest ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: 28,
                      height: 130 * heightRatio,
                      decoration: BoxDecoration(
                        gradient: isHighest
                            ? const LinearGradient(
                                colors: [AppColors.primary, AppColors.gold],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                            : LinearGradient(
                                colors: isDark
                                    ? [Colors.white24, Colors.white12]
                                    : [AppColors.primary.withOpacity(0.4), AppColors.primary.withOpacity(0.2)],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _days[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isHighest ? FontWeight.bold : FontWeight.normal,
                        color: isHighest ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textPrimary),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopDishesSection(bool isDark) {
    final topDishes = [
      {'name': 'Bò Wagyu A5 Áp Chảo', 'sold': 38, 'revenue': '41.420.000 ₫', 'cat': 'Món chính', 'share': 0.85},
      {'name': 'Tôm Hùm Nướng Bơ Tỏi', 'sold': 24, 'revenue': '21.360.000 ₫', 'cat': 'Hải sản', 'share': 0.65},
      {'name': 'Combo Hoàng Gia Crown Royal', 'sold': 12, 'revenue': '33.480.000 ₫', 'cat': 'Set Combo', 'share': 0.72},
      {'name': 'Salad Cá Hồi Xông Khói', 'sold': 31, 'revenue': '7.595.000 ₫', 'cat': 'Khai vị', 'share': 0.45},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Món Bán Chạy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Doanh thu món',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topDishes.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: idx == 0
                              ? AppColors.gold
                              : (idx == 1 ? Colors.grey.shade400 : (idx == 2 ? const Color(0xFFCD7F32) : Colors.grey.shade300)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Đã bán: ${item['sold']} suất • ${item['cat']}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['revenue'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item['share'] as double,
                      minHeight: 6,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        idx == 0 ? AppColors.gold : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(bool isDark) {
    final activities = [
      {
        'title': 'Bàn T1-03 thanh toán thành công',
        'desc': 'Tổng tiền: 1.695.000 ₫ qua VietQR',
        'time': '5 phút trước',
        'icon': Icons.check_circle_outline,
        'color': AppColors.success,
      },
      {
        'title': 'Đơn đặt bàn mới: CR-8892',
        'desc': 'Khách Nguyễn Văn An • 4 khách • 19:00',
        'time': '18 phút trước',
        'icon': Icons.calendar_today_outlined,
        'color': AppColors.primary,
      },
      {
        'title': 'Bếp hoàn tất món: Bò Wagyu A5',
        'desc': 'Bàn T2-01 sẵn sàng phục vụ',
        'time': '25 phút trước',
        'icon': Icons.restaurant_outlined,
        'color': AppColors.gold,
      },
      {
        'title': 'Nhân viên Mai Thu Hương vào ca',
        'desc': 'Nhân viên phục vụ • Ca tối',
        'time': '40 phút trước',
        'icon': Icons.person_outline,
        'color': const Color(0xFF6366F1),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nhật Ký Hoạt Động Gần Đây',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...activities.map((act) {
            final color = act['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(act['icon'] as IconData, size: 16, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          act['desc'] as String,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    act['time'] as String,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
