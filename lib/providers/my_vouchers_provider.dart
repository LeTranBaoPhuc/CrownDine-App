import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/my_voucher_model.dart';
import '../data/repositories/my_voucher_repository.dart';
import 'auth_provider.dart';

final myVoucherRepositoryProvider = Provider((ref) => MyVoucherRepository());

final myVouchersProvider =
    FutureProvider.autoDispose<List<MyVoucherModel>>((ref) async {
  // Recompute on logout/account switch, so another customer's wallet cannot be reused.
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  if (userId == null) {
    throw StateError('Vui lòng đăng nhập để xem voucher của bạn.');
  }
  return ref.watch(myVoucherRepositoryProvider).getMyVouchers();
});

String myVouchersError(Object error) {
  if (error is StateError) return error.message;
  if (error is FormatException) return error.message;
  if (error is DioException &&
      [401, 403].contains(error.response?.statusCode)) {
    return 'Phiên đăng nhập đã hết hạn hoặc bạn chưa có quyền truy cập. Vui lòng đăng nhập lại.';
  }
  return 'Không tải được voucher. Kiểm tra kết nối và thử lại.';
}
