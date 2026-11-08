import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../models/reservation_model.dart';

class ReservationRepository {
  final Dio _dio;
  ReservationRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;
  Future<List<ReservationModel>> getReservationHistory() async =>
      responseList(responseData(await _dio
              .get('reservations/history', queryParameters: {'size': 100})))
          .map((e) => ReservationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<void> cancelReservation(int id) async {
    responseData(await _dio.delete('reservations/$id/cancel'));
  }

  Future<List<ReservationModel>> getAllReservations(
          {String? date,
          String? fromDate,
          String? toDate,
          String? status,
          int? page,
          int? size}) async =>
      responseList(
              responseData(await _dio.get('reservations/all', queryParameters: {
        if (fromDate != null || date != null) 'fromDate': fromDate ?? date,
        if (toDate != null || date != null) 'toDate': toDate ?? date,
        if (status != null && status != 'ALL' && status != 'Tất cả')
          'status': status,
        'page': page ?? 0,
        'size': size ?? 100,
      })))
          .map((e) => ReservationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
  Future<bool> checkInReservation(int id, {int? staffId}) async {
    responseData(await _dio.post('reservations/$id/check-in'));
    return true;
  }

  Future<bool> cancelReservationByStaff(int id) async {
    responseData(await _dio.post('reservations/$id/cancel'));
    return true;
  }

  Future<bool> completeReservation(int id) async {
    responseData(await _dio.post('reservations/$id/complete'));
    return true;
  }

  Future<ReservationModel> createWalkInReservation(
      {required String guestName,
      required String guestPhone,
      required String date,
      required String startTime,
      String? endTime,
      required int guestNumber,
      required int tableId,
      String? note,
      List<ReservationOrderDetailModel> orderDetails = const []}) async {
    if (orderDetails.isNotEmpty)
      throw StateError(
          'Tạo đặt chỗ trước, sau đó nhận bàn và gọi món tại sơ đồ bàn.');
    final data =
        responseData(await _dio.post('reservations/staff-create', data: {
      'guestName': guestName,
      'guestPhone': guestPhone,
      'date': date,
      'startTime': startTime,
      'guestNumber': guestNumber,
      'tableId': tableId,
      'note': note,
    }));
    if (data is! Map || data['reservationId'] is! int)
      throw const FormatException('Thiếu mã đặt chỗ từ máy chủ.');
    return ReservationModel.fromJson({
      ...Map<String, dynamic>.from(data),
      'id': data['reservationId'],
      'code': data['reservationCode'],
      'status': data['reservationStatus'],
      'tableId': data['table']?['id'],
      'tableName': data['table']?['name'],
      'guestName': guestName,
      'guestPhone': guestPhone,
      'date': date,
      'startTime': startTime,
      'guestNumber': guestNumber,
      'note': note,
    });
  }

  Future<bool> updateReservationTable(int id, int tableId) async {
    responseData(await _dio
        .put('reservations/$id/update-table', data: {'tableId': tableId}));
    return true;
  }
}
