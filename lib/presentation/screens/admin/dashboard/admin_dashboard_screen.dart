import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/dashboard_model.dart';
import '../../../../providers/dashboard_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final List<String> _ranges = ['Hôm nay', '7 ngày qua', 'Tháng này'];
  int? _selectedBarIndex;
  bool _showTopByQuantity = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboardState = ref.watch(dashboardProvider);
    final notifier = ref.read(dashboardProvider.notifier);
    final data = dashboardState.data;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF100E0C) : const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => notifier.loadData(isRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Brand Header & Controls
              _buildTopHeader(isDark, dashboardState, notifier),
              const SizedBox(height: 16),

              if (dashboardState.isLoading && data == null)
                _buildLoadingState(isDark)
              else if (dashboardState.errorMessage != null && data == null)
                _buildErrorState(dashboardState.errorMessage!, notifier, isDark)
              else if (data != null) ...[
                // Master Hero Revenue Card
                _buildMasterHeroCard(data, dashboardState.timeRange, isDark),
                const SizedBox(height: 16),

                // Secondary Metric Cards
                _buildSecondaryMetricsGrid(data, dashboardState.timeRange, isDark),
                const SizedBox(height: 20),

                // Interactive Growth Chart
                _buildInteractiveChartSection(data, dashboardState, notifier, isDark),
                const SizedBox(height: 20),

                // Top Selling Items (Signature Dishes)
                _buildTopSellingSection(data, isDark),
                const SizedBox(height: 20),

                // Live Activity & Operations Timeline
                _buildActivityTimelineSection(data.recentActivities, isDark),
                const SizedBox(height: 36),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isDark, DashboardState state, DashboardNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'CROWNDINE REVENUE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Trung Tâm Doanh Thu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.textLight : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            // Quick Refresh Button
            IconButton(
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : AppColors.textPrimary,
                    ),
              tooltip: 'Cập nhật số liệu',
              onPressed: state.isLoading ? null : () => notifier.loadData(isRefresh: true),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Modern Segmented Time Range Pills
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: _ranges.map((range) {
              final isSelected = state.timeRange == range;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedBarIndex = null);
                    notifier.setTimeRange(range);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppColors.primary, Color(0xFFE8551E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      range,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white60 : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterHeroCard(DashboardSalesModel data, String timeRange, bool isDark) {
    final isToday = timeRange == 'Hôm nay';
    final totalRevenue = isToday ? data.completedTotalAmount : data.rangeTotalAmount;
    final isGrowthPositive = data.completedGrowthPercentage >= 0;
    final avgOrderValue = data.completedOrdersToday > 0
        ? (data.completedTotalAmount / data.completedOrdersToday)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF261D19),
                  const Color(0xFF1B1614),
                ]
              : [
                  const Color(0xFF2B211D),
                  const Color(0xFF1C1613),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Label & Trend Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isToday ? 'DOANH THU HÔM NAY' : 'TỔNG DOANH THU',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFFF3E8DF),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGrowthPositive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isGrowthPositive
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGrowthPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: isGrowthPositive ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isGrowthPositive ? '+' : ''}${data.completedGrowthPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isGrowthPositive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Revenue Figure
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              CurrencyFormatter.format(totalRevenue),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isToday
                ? 'Đã bao gồm các hóa đơn thanh toán hoàn tất trong ngày'
                : 'Thống kê tổng hợp theo khoảng thời gian $timeRange',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFB0A7A1),
            ),
          ),
          const SizedBox(height: 18),

          // Horizontal Divider with Gold hairline
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),

          // 3 Bottom Metrics embedded in Hero Card
          Row(
            children: [
              Expanded(
                child: _buildHeroSubMetric(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Đã hoàn tất',
                  value: '${data.completedOrdersToday} đơn',
                  subValue: 'Hôm qua: ${data.completedOrdersYesterday}',
                ),
              ),
              Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(
                child: _buildHeroSubMetric(
                  icon: Icons.table_restaurant_rounded,
                  label: 'Đang phục vụ',
                  value: '${data.servingOrdersToday} bàn',
                  subValue: CurrencyFormatter.format(data.servingTotalAmount),
                ),
              ),
              Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(
                child: _buildHeroSubMetric(
                  icon: Icons.analytics_outlined,
                  label: 'TB / Đơn (AOV)',
                  value: CurrencyFormatter.format(avgOrderValue),
                  subValue: 'Giá trị đơn TB',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSubMetric({
    required IconData icon,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFB0A7A1),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFF3E8DF),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.gold,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetricsGrid(DashboardSalesModel data, String timeRange, bool isDark) {
    final isToday = timeRange == 'Hôm nay';
    final customers = isToday ? data.totalCustomersToday : data.rangeTotalCustomers;
    final totalRevenue = isToday ? data.completedTotalAmount : data.rangeTotalAmount;
    final revPerCustomer = customers > 0 ? (totalRevenue / customers) : 0.0;

    return Row(
      children: [
        // Total Guests
        Expanded(
          child: _buildMetricCard(
            title: 'Lượt thực khách',
            value: '$customers khách',
            trend: '${data.customersGrowthPercentage >= 0 ? '+' : ''}${data.customersGrowthPercentage.toStringAsFixed(1)}%',
            isPositive: data.customersGrowthPercentage >= 0,
            icon: Icons.groups_rounded,
            color: const Color(0xFF6366F1),
            footer: 'So với kỳ trước',
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        // Revenue per Customer
        Expanded(
          child: _buildMetricCard(
            title: 'Chi tiêu TB / Khách',
            value: CurrencyFormatter.format(revPerCustomer),
            trend: 'RevPASH',
            isPositive: true,
            icon: Icons.person_pin_circle_outlined,
            color: AppColors.primary,
            footer: 'Hiệu suất mỗi khách',
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String trend,
    required bool isPositive,
    required IconData icon,
    required Color color,
    required String footer,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textLight : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white38 : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveChartSection(
    DashboardSalesModel data,
    DashboardState state,
    DashboardNotifier notifier,
    bool isDark,
  ) {
    final isRevenue = state.chartType == 'revenue';
    final chartList = isRevenue ? data.revenueChart : data.customerChart;

    if (chartList.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: const Text('Chưa có dữ liệu thống kê cho khoảng thời gian này'),
      );
    }

    double maxVal = 0.0;
    int peakIndex = 0;
    for (int i = 0; i < chartList.length; i++) {
      if (chartList[i].value > maxVal) {
        maxVal = chartList[i].value;
        peakIndex = i;
      }
    }
    if (maxVal == 0.0) maxVal = 1.0;

    final peakItem = chartList[peakIndex];
    final peakText = isRevenue
        ? '${peakItem.label} (${peakItem.value.toStringAsFixed(1)}M ₫)'
        : '${peakItem.label} (${peakItem.value.toInt()} khách)';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title & Segmented Metric Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isRevenue ? 'Biểu Đồ Doanh Thu' : 'Biểu Đồ Lượng Khách',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.textLight : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRevenue ? 'Đơn vị tính: Triệu VNĐ' : 'Đơn vị: Số lượt thực khách',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Segmented Toggle: Doanh thu / Khách
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181513) : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildChartPill(
                      label: 'Doanh thu',
                      isSelected: isRevenue,
                      onTap: () {
                        setState(() => _selectedBarIndex = null);
                        notifier.setChartType('revenue');
                      },
                    ),
                    _buildChartPill(
                      label: 'Khách',
                      isSelected: !isRevenue,
                      onTap: () {
                        setState(() => _selectedBarIndex = null);
                        notifier.setChartType('customers');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sub Controls: Peak Badge & ViewMode Popup (Theo giờ / ngày)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Peak Badge with Gold Glow
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      'Đỉnh điểm: $peakText',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),

              // ViewMode Popup
              PopupMenuButton<String>(
                initialValue: state.viewMode,
                onSelected: (mode) {
                  setState(() => _selectedBarIndex = null);
                  notifier.setViewMode(mode);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181513) : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        state.viewMode,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Theo giờ', child: Text('Xem theo giờ (07g - 22g)')),
                  const PopupMenuItem(value: 'Theo ngày', child: Text('Xem theo ngày')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Selected bar info tooltip banner
          if (_selectedBarIndex != null && _selectedBarIndex! < chartList.length) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isRevenue
                          ? 'Mốc ${chartList[_selectedBarIndex!].label}  •  Doanh thu: ${(chartList[_selectedBarIndex!].value * 1000000).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫'
                          : 'Mốc ${chartList[_selectedBarIndex!].label}  •  Lượng khách: ${chartList[_selectedBarIndex!].value.toInt()} khách',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bar Chart Canvas with Horizontal Scroll support
          SizedBox(
            height: 190,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barCount = chartList.length;
                final availableWidth = constraints.maxWidth;
                final isScrollable = (barCount * 46.0) > availableWidth;

                final chartContent = Row(
                  mainAxisAlignment: isScrollable ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(barCount, (index) {
                    final item = chartList[index];
                    final heightRatio = (item.value / maxVal).clamp(0.06, 1.0);
                    final isHighest = index == peakIndex && maxVal > 0;
                    final isSelected = _selectedBarIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBarIndex = (_selectedBarIndex == index) ? null : index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Top Bar Value
                            Text(
                              isRevenue
                                  ? (item.value > 0 ? '${item.value.toStringAsFixed(1)}M' : '0')
                                  : item.value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: (isHighest || isSelected) ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.gold
                                    : (isHighest ? AppColors.primary : AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Animated Bar with Luxury Gradient
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              width: isScrollable ? 26 : 28,
                              height: 130 * heightRatio,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [AppColors.gold, Color(0xFFFDE68A)],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      )
                                    : isHighest
                                        ? const LinearGradient(
                                            colors: [AppColors.primary, Color(0xFFF59E0B)],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          )
                                        : LinearGradient(
                                            colors: isDark
                                                ? [
                                                    Colors.white.withValues(alpha: 0.22),
                                                    Colors.white.withValues(alpha: 0.08)
                                                  ]
                                                : [
                                                    AppColors.primary.withValues(alpha: 0.35),
                                                    AppColors.primary.withValues(alpha: 0.12)
                                                  ],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          ),
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                                boxShadow: (isHighest || isSelected)
                                    ? [
                                        BoxShadow(
                                          color: (isSelected ? AppColors.gold : AppColors.primary)
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Bottom Axis Label
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: (isHighest || isSelected) ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.gold
                                    : (isHighest
                                        ? AppColors.primary
                                        : (isDark ? Colors.white70 : AppColors.textPrimary)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );

                if (isScrollable) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: chartContent,
                  );
                }
                return chartContent;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
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
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTopSellingSection(DashboardSalesModel data, bool isDark) {
    final list = _showTopByQuantity ? data.topProductsQuantity : data.topProducts;
    final double maxVal = list.isNotEmpty
        ? list.map((e) => e.value).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.military_tech_rounded, size: 18, color: AppColors.gold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Món Ăn Bán Chạy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              // Segmented Switch: Doanh thu / Số lượng
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF181513) : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildChartPill(
                      label: 'Doanh thu',
                      isSelected: !_showTopByQuantity,
                      onTap: () => setState(() => _showTopByQuantity = false),
                    ),
                    _buildChartPill(
                      label: 'Số lượng',
                      isSelected: _showTopByQuantity,
                      onTap: () => setState(() => _showTopByQuantity = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu món bán chạy trong khoảng thời gian này',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...list.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final ratio = maxVal > 0 ? (item.value / maxVal).clamp(0.05, 1.0) : 0.1;

              final valueFormatted = _showTopByQuantity
                  ? '${item.value.toInt()} suất'
                  : '${(item.value * 1000000).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫';

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rank Badge (Crown for #1, Silver for #2, Bronze for #3)
                        _buildRankBadge(idx),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppColors.textLight : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          valueFormatted,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: idx == 0 ? AppColors.gold : AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                          FractionallySizedBox(
                            widthFactor: ratio,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: idx == 0
                                      ? [AppColors.gold, const Color(0xFFFDE68A)]
                                      : [AppColors.primary, AppColors.gold],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildRankBadge(int idx) {
    if (idx == 0) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.workspace_premium, size: 15, color: Colors.white),
        ),
      );
    } else if (idx == 1) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '2',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    } else if (idx == 2) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFCD7F32),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '3',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${idx + 1}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildActivityTimelineSection(List<RecentActivityModel> activities, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nhật Ký Dòng Tiền & Vận Hành',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textLight : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Thời gian thực',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có hoạt động mới',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...activities.map((act) {
              final color = _getActivityColor(act.type);
              final icon = _getActivityIcon(act.type);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            act.action.isNotEmpty ? act.action : act.value,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: isDark ? AppColors.textLight : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${act.user} • ${act.value}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      act.time,
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

  Widget _buildLoadingState(bool isDark) {
    return Container(
      height: 350,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Đang phân tích số liệu kinh doanh...',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textLightSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message, DashboardNotifier notifier, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => notifier.loadData(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'sale':
      case 'payment':
        return AppColors.success;
      case 'kitchen':
      case 'order':
        return AppColors.gold;
      case 'table':
      case 'checkin':
        return AppColors.primary;
      case 'attendance':
      case 'staff':
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sale':
      case 'payment':
        return Icons.check_circle_outline_rounded;
      case 'kitchen':
      case 'order':
        return Icons.restaurant_rounded;
      case 'table':
      case 'checkin':
        return Icons.table_restaurant_rounded;
      case 'attendance':
      case 'staff':
        return Icons.person_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
