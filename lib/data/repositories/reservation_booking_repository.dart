import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../models/reservation_model.dart';
import '../models/table_model.dart';

/// Writes the real reservation/cart. No mock fallback on any mutation.
class ReservationBookingRepository {
  final Dio _dio;
  ReservationBookingRepository({Dio? dio})
      : _dio = dio ?? ApiClient.instance.dio;

  Map<String, dynamic> _data(Response<dynamic> response) {
    final body = response.data;
    if (body is! Map || (body['status'] is num && body['status'] >= 400)) {
      throw const FormatException('Phản hồi đặt bàn không hợp lệ.');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Thiếu dữ liệu đặt bàn.');
    }
    return data;
  }

  Future<void> verifyTable(TableModel selected) async {
    final response = await _dio.get('restaurant-tables');
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const FormatException('Không thể kiểm tra bàn trên máy chủ.');
    }
    Map? matched;
    for (final raw in data) {
      if (raw is Map && raw['id'] == selected.id) {
        matched = raw;
        break;
      }
    }
    if (matched == null ||
        matched['name'] != selected.name ||
        matched['capacity'] != selected.capacity) {
      throw StateError(
          'Bàn đã chọn không khớp dữ liệu hiện tại. Vui lòng tải lại sơ đồ bàn.');
    }
    // Current floor status does not establish availability for a future slot.
    // The create endpoint validates the requested date and time.
  }

  Future<int> create(
      {required String date,
      required String time,
      required int guests,
      required int tableId,
      required String note}) async {
    final data = _data(await _dio.post('reservations/create', data: {
      'date': date,
      'startTime': time,
      'guestNumber': guests,
      'tableId': tableId,
      'note': note,
    }));
    final id = data['reservationId'];
    if (id is! int || id <= 0) {
      throw const FormatException('Thiếu mã đặt bàn từ máy chủ.');
    }
    return id;
  }

  Future<void> cancel(int reservationId) async {
    final response = await _dio.delete('reservations/$reservationId/cancel');
    final body = response.data;
    if (body is! Map || (body['status'] is num && body['status'] >= 400)) {
      throw const FormatException('Chưa xác nhận được việc hủy đặt bàn.');
    }
  }

  String _key(int id, bool combo) => '${combo ? 'COMBO' : 'ITEM'}:$id';
  Map<String, dynamic> _product(int id, bool combo) =>
      {combo ? 'comboId' : 'itemId': id};

  Map<String, Map<String, dynamic>> _lines(Map<String, dynamic> checkout) {
    final items = checkout['items'];
    if (items is! List) {
      throw const FormatException('Thiếu danh sách món từ máy chủ.');
    }
    final result = <String, Map<String, dynamic>>{};
    for (final raw in items) {
      if (raw is! Map<String, dynamic> ||
          raw['productId'] is! int ||
          raw['quantity'] is! int ||
          !['ITEM', 'COMBO'].contains(raw['type'])) {
        throw const FormatException('Danh sách món từ máy chủ không hợp lệ.');
      }
      final key = _key(raw['productId'] as int, raw['type'] == 'COMBO');
      if (result.containsKey(key)) {
        throw const FormatException(
            'Đơn có món trùng. Vui lòng liên hệ nhà hàng.');
      }
      result[key] = raw;
    }
    return result;
  }

  Future<Map<String, dynamic>> _checkout(int id) async {
    final data = _data(await _dio.get('reservations/$id/checkout'));
    if (data['reservationId'] != id || data['reservationStatus'] != 'PENDING') {
      throw StateError(
          'Đặt bàn không còn chờ thanh toán. Vui lòng kiểm tra lịch sử đặt bàn.');
    }
    final expiry = data['expiratedAt'];
    if (expiry != null) {
      final time = DateTime.tryParse(expiry.toString());
      if (time == null || !time.isAfter(DateTime.now())) {
        throw StateError('Đã hết thời gian giữ bàn. Vui lòng đặt bàn lại.');
      }
    }
    return data;
  }

  Future<void> syncItems(int reservationId, List<CartItemModel> desired) async {
    // Always read the server first: POST add-item increments existing quantities.
    // Retrying after a lost response must use PUT absolute quantity instead.
    final quote = await _checkout(reservationId);
    final current = _lines(quote);
    final wanted = {
      for (final line in desired) _key(line.item.id, line.item.isCombo): line
    };
    if (wanted.length != desired.length ||
        desired.any((e) => e.quantity <= 0 || e.item.id <= 0)) {
      throw StateError('Danh sách món không hợp lệ.');
    }
    final changed = current.length != wanted.length ||
        wanted.entries
            .any((e) => current[e.key]?['quantity'] != e.value.quantity);
    if (!changed) return;
    // A changed cart must revalidate any earlier discount before payment.
    if ((quote['discountAmount'] as num? ?? 0) > 0 &&
        quote['orderId'] != null) {
      await _dio.delete('orders/${quote['orderId']}/voucher');
    }
    for (final entry in current.entries) {
      if (!wanted.containsKey(entry.key)) {
        await _dio.delete('reservations/$reservationId/remove-item',
            data: _product(entry.value['productId'] as int,
                entry.value['type'] == 'COMBO'));
      }
    }
    for (final entry in wanted.entries) {
      final line = entry.value;
      final body = {
        ..._product(line.item.id, line.item.isCombo),
        'quantity': line.quantity,
        'note': line.note
      };
      if (!current.containsKey(entry.key)) {
        await _dio.post('reservations/$reservationId/add-item', data: body);
      } else if (current[entry.key]!['quantity'] != line.quantity) {
        await _dio.put('reservations/$reservationId/upd-item', data: body);
      }
    }
    final actual = _lines(await _checkout(reservationId));
    if (actual.length != wanted.length ||
        wanted.entries
            .any((e) => actual[e.key]?['quantity'] != e.value.quantity)) {
      throw StateError(
          'Món ăn chưa đồng bộ đầy đủ. Vui lòng thử lại trước khi thanh toán.');
    }
  }
}
