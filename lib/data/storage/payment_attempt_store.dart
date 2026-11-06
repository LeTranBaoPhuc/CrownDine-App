import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_config.dart';

/// A local recovery hint, never proof of payment. Scoped by API and account.
class PaymentAttemptStore {
  final int userId;
  PaymentAttemptStore(this.userId);

  Future<String> _key(int reservationId) async =>
      'payment_attempt:${Uri.encodeComponent(await ApiConfig.getBaseUrl())}:$userId:$reservationId';

  Future<Map<String, dynamic>?> read(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _key(reservationId));
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> save(int reservationId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(await _key(reservationId), jsonEncode(data))) {
      throw StateError('Không thể lưu thông tin khôi phục giao dịch.');
    }
  }

  Future<void> remove(int reservationId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(await _key(reservationId))) {
      throw StateError('Không thể xóa giao dịch chưa tạo.');
    }
  }
}
