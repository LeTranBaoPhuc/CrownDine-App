import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../models/dashboard_model.dart';

class DashboardRepository {
  final ApiClient _client = ApiClient.instance;

  /// Lấy dữ liệu báo cáo doanh thu & hiệu suất kinh doanh
  Future<DashboardSalesModel> getSalesResults({
    String viewMode = 'Theo giờ',
    String timeRange = '7 ngày qua',
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(
        ApiEndpoints.dashboardSales,
        queryParameters: {
          'viewMode': viewMode,
          'timeRange': timeRange,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        if (data is Map<String, dynamic>) {
          return DashboardSalesModel.fromJson(data);
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return DashboardSalesModel.mock(timeRange: timeRange, viewMode: viewMode);
  }
}
