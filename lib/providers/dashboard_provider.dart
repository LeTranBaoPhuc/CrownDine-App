import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/dashboard_model.dart';
import '../data/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

class DashboardState {
  final String timeRange;
  final String viewMode;
  final String chartType; // 'revenue' or 'customers'
  final DashboardSalesModel? data;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.timeRange = 'Hôm nay',
    this.viewMode = 'Theo giờ',
    this.chartType = 'revenue',
    this.data,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    String? timeRange,
    String? viewMode,
    String? chartType,
    DashboardSalesModel? data,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      timeRange: timeRange ?? this.timeRange,
      viewMode: viewMode ?? this.viewMode,
      chartType: chartType ?? this.chartType,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(DashboardState()) {
    loadData();
  }

  Future<void> loadData({bool isRefresh = false}) async {
    if (!isRefresh && state.data == null) {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final result = await _repository.getSalesResults(
        viewMode: state.viewMode,
        timeRange: state.timeRange,
      );
      state = state.copyWith(
        data: result,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải dữ liệu doanh thu: ${e.toString()}',
      );
    }
  }

  void setTimeRange(String range) {
    if (state.timeRange == range) return;
    // Auto-adjust default viewMode: "Hôm nay" defaults to "Theo giờ", "7 ngày qua" / "Tháng này" defaults to "Theo ngày"
    String newViewMode = state.viewMode;
    if (range == 'Hôm nay') {
      newViewMode = 'Theo giờ';
    } else if (state.viewMode == 'Theo giờ') {
      newViewMode = 'Theo ngày';
    }

    state = state.copyWith(
      timeRange: range,
      viewMode: newViewMode,
      isLoading: true,
      errorMessage: null,
    );
    loadData();
  }

  void setViewMode(String mode) {
    if (state.viewMode == mode) return;
    state = state.copyWith(
      viewMode: mode,
      isLoading: true,
      errorMessage: null,
    );
    loadData();
  }

  void setChartType(String type) {
    if (state.chartType == type) return;
    state = state.copyWith(chartType: type);
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return DashboardNotifier(repo);
});
