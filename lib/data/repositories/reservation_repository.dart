import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/reservation_model.dart';

class ReservationRepository {
  final ApiClient _client = ApiClient.instance;

  /// Đặt bàn dành cho khách hàng
  Future<ReservationModel> createReservation({
    required String date,
    required String startTime,
    required int guestNumber,
    required int tableId,
    String? note,
    String? guestName,
    String? guestPhone,
    List<CartItemModel> items = const [],
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.post(
        ApiEndpoints.reservationCreate,
        data: {
          'date': date,
          'startTime': startTime,
          'guestNumber': guestNumber,
          'tableId': tableId,
          'note': note,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return ReservationModel.fromJson(data);
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    final table = MockData.tables.firstWhere((t) => t.id == tableId, orElse: () => MockData.tables.first);
    final itemsSum = items.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
    final total = table.deposit + itemsSum;

    final newRes = ReservationModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      code: 'CR-${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}',
      date: date,
      startTime: startTime,
      guestNumber: guestNumber,
      tableId: tableId,
      tableName: table.name,
      floorName: 'Tầng ${table.floorId}',
      areaName: table.areaName,
      tableDeposit: table.deposit,
      itemsTotal: itemsSum,
      finalAmount: total,
      status: ReservationStatus.confirmed,
      note: note,
      customerName: guestName ?? 'Nguyễn Văn An',
      guestName: guestName ?? 'Nguyễn Văn An',
      guestPhone: guestPhone ?? '0901234567',
      items: items,
      createdAt: DateTime.now(),
    );

    MockData.sampleReservations.insert(0, newRes);
    return newRes;
  }

  /// Lấy lịch sử đặt bàn của khách hàng
  Future<List<ReservationModel>> getReservationHistory() async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.get(ApiEndpoints.reservationHistory);
      if (response.statusCode == 200 && response.data != null) {
        final pageData = response.data['data'] ?? response.data;
        final list = (pageData['items'] as List?) ?? (pageData['content'] as List?) ?? (pageData as List?);
        if (list != null && list.isNotEmpty) {
          return list.map((e) => ReservationModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    return MockData.sampleReservations;
  }

  /// Khách hàng hủy đặt bàn
  Future<void> cancelReservation(int reservationId) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      await _client.dio.delete('${ApiEndpoints.reservations}/$reservationId/cancel');
    } catch (e) {
      if (!useMock) rethrow;
    }

    final idx = MockData.sampleReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      final old = MockData.sampleReservations[idx];
      MockData.sampleReservations[idx] = old.copyWith(status: ReservationStatus.cancelled);
    }
  }

  /// [Staff] Lấy toàn bộ danh sách đặt bàn (hỗ trợ lọc theo ngày, trạng thái)
  Future<List<ReservationModel>> getAllReservations({
    String? date,
    String? fromDate,
    String? toDate,
    String? status,
    int? page,
    int? size,
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final queryParams = <String, dynamic>{};
      if (date != null && date.isNotEmpty) queryParams['date'] = date;
      if (fromDate != null && fromDate.isNotEmpty) queryParams['fromDate'] = fromDate;
      if (toDate != null && toDate.isNotEmpty) queryParams['toDate'] = toDate;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (page != null) queryParams['page'] = page;
      if (size != null) queryParams['size'] = size;

      final response = await _client.dio.get(
        ApiEndpoints.reservationAll,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final body = response.data['data'] ?? response.data;
        final list = (body['data'] as List?) ??
            (body['content'] as List?) ??
            (body['items'] as List?) ??
            (body as List?);

        if (list != null) {
          return list.map((e) => ReservationModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    // Mock data filter logic
    return MockData.sampleReservations.where((r) {
      if (date != null && date.isNotEmpty && r.date != date) {
        return false;
      }
      if (status != null && status.isNotEmpty && status != 'Tất cả') {
        if (r.status.code.toUpperCase() != status.toUpperCase() &&
            r.status.displayName.toLowerCase() != status.toLowerCase()) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// [Staff] Check-in nhận bàn cho khách
  Future<bool> checkInReservation(int reservationId, {int? staffId}) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final url = ApiEndpoints.reservationCheckIn(reservationId, staffId: staffId);
      final response = await _client.dio.post(url);
      if (response.statusCode == 200) {
        _updateMockStatus(reservationId, ReservationStatus.checkedIn);
        return true;
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    _updateMockStatus(reservationId, ReservationStatus.checkedIn);
    return true;
  }

  /// [Staff] Nhân viên hủy đặt bàn
  Future<bool> cancelReservationByStaff(int reservationId) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final url = ApiEndpoints.reservationCancelByStaff(reservationId);
      final response = await _client.dio.post(url);
      if (response.statusCode == 200) {
        _updateMockStatus(reservationId, ReservationStatus.cancelled);
        return true;
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    _updateMockStatus(reservationId, ReservationStatus.cancelled);
    return true;
  }

  /// [Staff] Tạo đơn đặt bàn tại chỗ (Walk-in / Phone call)
  Future<ReservationModel> createWalkInReservation({
    required String guestName,
    required String guestPhone,
    required String date,
    required String startTime,
    String? endTime,
    required int guestNumber,
    required int tableId,
    String? note,
    List<ReservationOrderDetailModel> orderDetails = const [],
  }) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final response = await _client.dio.post(
        ApiEndpoints.reservationStaffCreate,
        data: {
          'guestName': guestName,
          'guestPhone': guestPhone,
          'date': date,
          'startTime': startTime,
          'endTime': endTime,
          'guestNumber': guestNumber,
          'tableId': tableId,
          'note': note,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return ReservationModel.fromJson(data);
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    final table = MockData.tables.firstWhere((t) => t.id == tableId, orElse: () => MockData.tables.first);
    final itemsSum = orderDetails.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
    final total = table.deposit + itemsSum;

    final newRes = ReservationModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      code: 'CR-${(DateTime.now().millisecondsSinceEpoch % 9000) + 1000}',
      customerName: guestName,
      guestName: guestName,
      guestPhone: guestPhone,
      date: date,
      startTime: startTime,
      endTime: endTime ?? _calculateDefaultEndTime(startTime),
      guestNumber: guestNumber,
      tableId: tableId,
      tableName: table.name,
      floorName: 'Tầng ${table.floorId}',
      areaName: table.areaName,
      tableDeposit: table.deposit,
      itemsTotal: itemsSum,
      finalAmount: total,
      status: ReservationStatus.confirmed,
      note: note,
      orderDetails: orderDetails,
      createdAt: DateTime.now(),
    );

    MockData.sampleReservations.insert(0, newRes);
    return newRes;
  }

  /// [Staff] Đổi hoặc gán bàn cho đặt chỗ
  Future<bool> updateReservationTable(int reservationId, int tableId) async {
    final useMock = await ApiConfig.isMockFallbackEnabled();

    try {
      final url = ApiEndpoints.reservationUpdateTable(reservationId);
      final response = await _client.dio.put(url, data: {'tableId': tableId});
      if (response.statusCode == 200) {
        _updateMockTable(reservationId, tableId);
        return true;
      }
    } catch (e) {
      if (!useMock) rethrow;
    }

    _updateMockTable(reservationId, tableId);
    return true;
  }

  void _updateMockStatus(int reservationId, ReservationStatus newStatus) {
    final idx = MockData.sampleReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      MockData.sampleReservations[idx] = MockData.sampleReservations[idx].copyWith(status: newStatus);
    }
  }

  void _updateMockTable(int reservationId, int tableId) {
    final idx = MockData.sampleReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) {
      final table = MockData.tables.firstWhere((t) => t.id == tableId, orElse: () => MockData.tables.first);
      MockData.sampleReservations[idx] = MockData.sampleReservations[idx].copyWith(
        tableId: tableId,
        tableName: table.name,
        floorName: 'Tầng ${table.floorId}',
        areaName: table.areaName,
      );
    }
  }

  String _calculateDefaultEndTime(String start) {
    try {
      final parts = start.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final endHour = (hour + 2) % 24;
      return '${endHour.toString().padLeft(2, '0')}:$minute';
    } catch (_) {
      return '';
    }
  }
}

