class ChartDataModel {
  final String label;
  final double value;

  ChartDataModel({
    required this.label,
    required this.value,
  });

  factory ChartDataModel.fromJson(Map<String, dynamic> json) {
    return ChartDataModel(
      label: json['label']?.toString() ?? '',
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}

class RecentActivityModel {
  final String id;
  final String user;
  final String action;
  final String value;
  final String time;
  final String type;
  final String? reason;

  RecentActivityModel({
    required this.id,
    required this.user,
    required this.action,
    required this.value,
    required this.time,
    required this.type,
    this.reason,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id']?.toString() ?? '',
      user: json['user']?.toString() ?? 'Hệ thống',
      action: json['action']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      type: json['type']?.toString() ?? 'sale',
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'action': action,
      'value': value,
      'time': time,
      'type': type,
      if (reason != null) 'reason': reason,
    };
  }
}

class DashboardSalesModel {
  final int completedOrdersToday;
  final double completedGrowthPercentage;
  final double completedTotalAmount;
  final int completedOrdersYesterday;

  final int servingOrdersToday;
  final double servingTotalAmount;

  final int totalCustomersToday;
  final int totalCustomersYesterday;
  final double customersGrowthPercentage;

  final double rangeTotalAmount;
  final int rangeTotalCustomers;

  final List<ChartDataModel> revenueChart;
  final List<ChartDataModel> customerChart;
  final List<ChartDataModel> topProducts;
  final List<ChartDataModel> topProductsQuantity;
  final List<RecentActivityModel> recentActivities;

  DashboardSalesModel({
    this.completedOrdersToday = 0,
    this.completedGrowthPercentage = 0.0,
    this.completedTotalAmount = 0.0,
    this.completedOrdersYesterday = 0,
    this.servingOrdersToday = 0,
    this.servingTotalAmount = 0.0,
    this.totalCustomersToday = 0,
    this.totalCustomersYesterday = 0,
    this.customersGrowthPercentage = 0.0,
    this.rangeTotalAmount = 0.0,
    this.rangeTotalCustomers = 0,
    this.revenueChart = const [],
    this.customerChart = const [],
    this.topProducts = const [],
    this.topProductsQuantity = const [],
    this.recentActivities = const [],
  });

  factory DashboardSalesModel.fromJson(Map<String, dynamic> json) {
    List<ChartDataModel> parseChart(dynamic list) {
      if (list is List) {
        return list.map((item) => ChartDataModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    }

    List<RecentActivityModel> parseActivities(dynamic list) {
      if (list is List) {
        return list.map((item) => RecentActivityModel.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    }

    return DashboardSalesModel(
      completedOrdersToday: (json['completedOrdersToday'] as num?)?.toInt() ?? 0,
      completedGrowthPercentage: (json['completedGrowthPercentage'] as num?)?.toDouble() ?? 0.0,
      completedTotalAmount: (json['completedTotalAmount'] as num?)?.toDouble() ?? 0.0,
      completedOrdersYesterday: (json['completedOrdersYesterday'] as num?)?.toInt() ?? 0,
      servingOrdersToday: (json['servingOrdersToday'] as num?)?.toInt() ?? 0,
      servingTotalAmount: (json['servingTotalAmount'] as num?)?.toDouble() ?? 0.0,
      totalCustomersToday: (json['totalCustomersToday'] as num?)?.toInt() ?? 0,
      totalCustomersYesterday: (json['totalCustomersYesterday'] as num?)?.toInt() ?? 0,
      customersGrowthPercentage: (json['customersGrowthPercentage'] as num?)?.toDouble() ?? 0.0,
      rangeTotalAmount: (json['rangeTotalAmount'] as num?)?.toDouble() ?? 0.0,
      rangeTotalCustomers: (json['rangeTotalCustomers'] as num?)?.toInt() ?? 0,
      revenueChart: parseChart(json['revenueChart']),
      customerChart: parseChart(json['customerChart']),
      topProducts: parseChart(json['topProducts']),
      topProductsQuantity: parseChart(json['topProductsQuantity']),
      recentActivities: parseActivities(json['recentActivities']),
    );
  }

  static DashboardSalesModel mock({String timeRange = '7 ngày qua', String viewMode = 'Theo ngày'}) {
    final isHour = viewMode == 'Theo giờ';
    final List<ChartDataModel> mockRevenue = isHour
        ? [
            ChartDataModel(label: '08g', value: 1.2),
            ChartDataModel(label: '10g', value: 3.5),
            ChartDataModel(label: '12g', value: 8.4),
            ChartDataModel(label: '14g', value: 2.1),
            ChartDataModel(label: '16g', value: 1.8),
            ChartDataModel(label: '18g', value: 11.2),
            ChartDataModel(label: '20g', value: 14.6),
            ChartDataModel(label: '22g', value: 4.8),
          ]
        : [
            ChartDataModel(label: 'Thứ 2', value: 12.4),
            ChartDataModel(label: 'Thứ 3', value: 15.8),
            ChartDataModel(label: 'Thứ 4', value: 14.2),
            ChartDataModel(label: 'Thứ 5', value: 19.5),
            ChartDataModel(label: 'Thứ 6', value: 22.8),
            ChartDataModel(label: 'Thứ 7', value: 28.4),
            ChartDataModel(label: 'CN', value: 18.5),
          ];

    final List<ChartDataModel> mockCustomers = isHour
        ? [
            ChartDataModel(label: '08g', value: 8),
            ChartDataModel(label: '10g', value: 18),
            ChartDataModel(label: '12g', value: 45),
            ChartDataModel(label: '14g', value: 12),
            ChartDataModel(label: '16g', value: 15),
            ChartDataModel(label: '18g', value: 58),
            ChartDataModel(label: '20g', value: 72),
            ChartDataModel(label: '22g', value: 25),
          ]
        : [
            ChartDataModel(label: 'Thứ 2', value: 65),
            ChartDataModel(label: 'Thứ 3', value: 78),
            ChartDataModel(label: 'Thứ 4', value: 70),
            ChartDataModel(label: 'Thứ 5', value: 92),
            ChartDataModel(label: 'Thứ 6', value: 115),
            ChartDataModel(label: 'Thứ 7', value: 142),
            ChartDataModel(label: 'CN', value: 98),
          ];

    final List<ChartDataModel> mockTopProducts = [
      ChartDataModel(label: 'Bò Wagyu A5 Áp Chảo', value: 41.42),
      ChartDataModel(label: 'Tôm Hùm Nướng Bơ Tỏi', value: 21.36),
      ChartDataModel(label: 'Combo Hoàng Gia Crown Royal', value: 33.48),
      ChartDataModel(label: 'Salad Cá Hồi Xông Khói', value: 7.59),
      ChartDataModel(label: 'Vang Đỏ Château Margaux', value: 18.20),
    ];

    final List<ChartDataModel> mockTopQuantity = [
      ChartDataModel(label: 'Bò Wagyu A5 Áp Chảo', value: 38),
      ChartDataModel(label: 'Salad Cá Hồi Xông Khói', value: 31),
      ChartDataModel(label: 'Tôm Hùm Nướng Bơ Tỏi', value: 24),
      ChartDataModel(label: 'Combo Hoàng Gia Crown Royal', value: 12),
      ChartDataModel(label: 'Vang Đỏ Château Margaux', value: 8),
    ];

    final List<RecentActivityModel> mockActivities = [
      RecentActivityModel(
        id: '1',
        user: 'Thu ngân 01',
        action: 'Thanh toán thành công đơn HD-8902',
        value: '1.695.000 ₫',
        time: '5 phút trước',
        type: 'sale',
      ),
      RecentActivityModel(
        id: '2',
        user: 'Lễ tân',
        action: 'Khách nhận bàn T1-04 (4 khách)',
        value: 'Bàn T1-04',
        time: '18 phút trước',
        type: 'table',
      ),
      RecentActivityModel(
        id: '3',
        user: 'Bếp trưởng',
        action: 'Hoàn tất chế biến món: Bò Wagyu A5',
        value: 'Bàn T2-01',
        time: '25 phút trước',
        type: 'kitchen',
      ),
      RecentActivityModel(
        id: '4',
        user: 'Hệ thống',
        action: 'Nhân viên Mai Thu Hương vào ca tối',
        value: 'Check-in thành công',
        time: '40 phút trước',
        type: 'attendance',
      ),
    ];

    final isToday = timeRange == 'Hôm nay';

    return DashboardSalesModel(
      completedOrdersToday: 42,
      completedGrowthPercentage: 14.2,
      completedTotalAmount: 18450000,
      completedOrdersYesterday: 36,
      servingOrdersToday: 8,
      servingTotalAmount: 6420000,
      totalCustomersToday: 128,
      totalCustomersYesterday: 114,
      customersGrowthPercentage: 12.0,
      rangeTotalAmount: isToday ? 18450000 : 131600000,
      rangeTotalCustomers: isToday ? 128 : 660,
      revenueChart: mockRevenue,
      customerChart: mockCustomers,
      topProducts: mockTopProducts,
      topProductsQuantity: mockTopQuantity,
      recentActivities: mockActivities,
    );
  }
}
