import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../mock/mock_data.dart';
import '../models/reservation_model.dart';

class ReservationRepository {
  final ApiClient _client = ApiClient.instance;

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
      tableDeposit: table.deposit,
      itemsTotal: itemsSum,
      finalAmount: total,
      status: ReservationStatus.confirmed,
      note: note,
      guestName: guestName ?? 'Nguyễn Văn An',
      guestPhone: guestPhone ?? '0901234567',
      items: items,
      createdAt: DateTime.now(),
    );

    MockData.sampleReservations.insert(0, newRes);
    return newRes;
  }

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
      MockData.sampleReservations[idx] = ReservationModel(
        id: old.id,
        code: old.code,
        date: old.date,
        startTime: old.startTime,
        guestNumber: old.guestNumber,
        tableId: old.tableId,
        tableName: old.tableName,
        tableDeposit: old.tableDeposit,
        itemsTotal: old.itemsTotal,
        finalAmount: old.finalAmount,
        status: ReservationStatus.cancelled,
        note: old.note,
        guestName: old.guestName,
        guestPhone: old.guestPhone,
        items: old.items,
        createdAt: old.createdAt,
      );
    }
  }
}
