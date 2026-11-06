import 'package:dio/dio.dart';
import '../data/storage/payment_attempt_store.dart';
import 'auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/reservation_checkout_model.dart';
import '../data/repositories/reservation_checkout_repository.dart';

/// Step 3 publishes a REAL reservation ID here only after all item API calls
/// succeed. Set null before changing the reservation/cart or starting a new one.
/// Intentionally independent from the legacy mock-capable reservation provider.
final checkoutReservationIdProvider = StateProvider.autoDispose<int?>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  return null;
});

final reservationCheckoutRepositoryProvider =
    Provider((ref) => ReservationCheckoutRepository());
final reservationCheckoutProvider = StateNotifierProvider.autoDispose
    .family<ReservationCheckoutNotifier, ReservationCheckoutState, int>(
        (ref, id) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  return ReservationCheckoutNotifier(
      ref.watch(reservationCheckoutRepositoryProvider), id,
      store: userId == null ? null : PaymentAttemptStore(userId));
});

class ReservationCheckoutState {
  final ReservationCheckoutModel? checkout;
  final bool busy;
  final bool paymentUncertain;
  final String? error;
  final String? voucherCode;
  final Uri? paymentUrl;
  final String? paymentCode;
  final ReservationPaymentResult? payment;

  const ReservationCheckoutState(
      {this.checkout,
      this.busy = false,
      this.paymentUncertain = false,
      this.error,
      this.voucherCode,
      this.paymentUrl,
      this.paymentCode,
      this.payment});

  bool get paid => payment?.status == 'SUCCESS';
  bool get paymentStarted =>
      paymentUrl != null || paymentCode != null || paymentUncertain;

  ReservationCheckoutState copyWith(
          {ReservationCheckoutModel? checkout,
          bool clearCheckout = false,
          bool? busy,
          bool? paymentUncertain,
          String? error,
          String? voucherCode,
          bool clearVoucher = false,
          Uri? paymentUrl,
          String? paymentCode,
          ReservationPaymentResult? payment}) =>
      ReservationCheckoutState(
        checkout: clearCheckout ? null : checkout ?? this.checkout,
        busy: busy ?? this.busy,
        paymentUncertain: paymentUncertain ?? this.paymentUncertain,
        error: error,
        voucherCode: clearVoucher ? null : voucherCode ?? this.voucherCode,
        paymentUrl: paymentUrl ?? this.paymentUrl,
        paymentCode: paymentCode ?? this.paymentCode,
        payment: payment ?? this.payment,
      );
}

class ReservationCheckoutNotifier
    extends StateNotifier<ReservationCheckoutState> {
  final ReservationCheckoutRepository _repo;
  final int reservationId;
  final PaymentAttemptStore? _store;

  ReservationCheckoutNotifier(this._repo, this.reservationId,
      {PaymentAttemptStore? store})
      : _store = store,
        super(const ReservationCheckoutState());

  Future<void> refresh() async {
    if (state.busy) return;
    state = state.copyWith(busy: true);
    try {
      final checkout = await _repo.getCheckout(reservationId);
      final saved = await _store?.read(reservationId);
      if (!mounted) return;
      if (saved != null) {
        if (saved['reservationCode'] != checkout.reservationCode) {
          throw StateError(
              'Thông tin giao dịch đã lưu không khớp đặt bàn. Vui lòng liên hệ nhà hàng.');
        }
        if (saved['depositAmount'] != null &&
            saved['depositAmount'] != checkout.depositAmount) {
          throw StateError(
              'Số tiền cọc đã thay đổi. Vui lòng liên hệ nhà hàng để kiểm tra giao dịch trước đó.');
        }
        final url =
            saved['url'] == null ? null : Uri.tryParse(saved['url'] as String);
        if (url != null && (url.scheme != 'https' || url.host.isEmpty)) {
          throw const FormatException('Liên kết đã lưu không hợp lệ.');
        }
        state = state.copyWith(
            checkout: checkout,
            paymentUrl: url,
            paymentCode: saved['code'] as String?,
            paymentUncertain: saved['uncertain'] == true,
            error: saved['uncertain'] == true
                ? 'Giao dịch trước chưa rõ kết quả. Vui lòng kiểm tra với nhà hàng trước khi thanh toán lại.'
                : null,
            busy: false);
        if (state.paymentCode != null) await verifyPayment(state.paymentCode!);
      } else {
        state = state.copyWith(checkout: checkout, busy: false);
      }
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
            clearCheckout: true, busy: false, error: checkoutError(error));
      }
    }
  }

  Future<void> changeVoucher(String? code) async {
    final checkout = state.checkout;
    if (state.busy ||
        state.paymentStarted ||
        checkout == null ||
        !checkout.canApplyVoucher) {
      return;
    }
    if (code != null && code.trim().isEmpty) {
      state = state.copyWith(error: 'Vui lòng nhập mã voucher.');
      return;
    }
    state = state.copyWith(busy: true);
    try {
      if (code == null) {
        await _repo.removeVoucher(checkout.orderId!);
      } else {
        await _repo.applyVoucher(checkout.orderId!, code);
      }
      if (!mounted) return;
      // A mutation may have succeeded even if the subsequent refresh fails.
      // Never allow payment against the old quote in that case.
      state = state.copyWith(
          clearCheckout: true,
          voucherCode: code?.trim().toUpperCase(),
          clearVoucher: code == null);
      final updated = await _repo.getCheckout(reservationId);
      if (mounted) state = state.copyWith(checkout: updated, busy: false);
    } catch (error) {
      if (mounted) {
        state = state.copyWith(
            clearCheckout: true, busy: false, error: checkoutError(error));
      }
    }
  }

  Future<Uri?> startPayment() async {
    if (state.busy || state.paid || state.paymentUncertain) return null;
    // Reopen the same link after closing the WebView; do not create a second charge.
    if (state.paymentUrl != null) {
      if (state.checkout?.canPay != true) {
        state = state.copyWith(
            error:
                'Đặt bàn không còn chờ thanh toán hoặc đã hết hạn. Vui lòng kiểm tra lại trạng thái.');
        return null;
      }
      return state.paymentUrl;
    }
    var creatingLink = false;
    final previous = state.checkout;
    if (previous == null) return null;
    state = state.copyWith(busy: true);
    try {
      final current = await _repo.getCheckout(reservationId);
      if (!mounted) return null;
      state = state.copyWith(checkout: current);
      if (!current.canPay) {
        throw StateError('Đặt bàn đã hết hạn hoặc không còn chờ thanh toán.');
      }
      if (current.reservationCode != previous.reservationCode ||
          current.orderId != previous.orderId ||
          current.itemsTotal != previous.itemsTotal ||
          current.discountAmount != previous.discountAmount ||
          current.depositAmount != previous.depositAmount) {
        throw StateError(
            'Thông tin thanh toán đã thay đổi. Vui lòng kiểm tra lại số tiền và bấm thanh toán.');
      }
      // Persist intent before the request: process death/timeouts must not allow
      // a second create-payment request on the same device after reopening.
      await _store?.save(reservationId, {
        'reservationCode': current.reservationCode,
        'depositAmount': current.depositAmount,
        'uncertain': true
      });
      creatingLink = true;
      final url = await _repo.createPayment(current.reservationCode);
      await _store?.save(reservationId, {
        'reservationCode': current.reservationCode,
        'depositAmount': current.depositAmount,
        'url': url.toString(),
        'uncertain': false
      });
      if (!mounted) return null;
      state = state.copyWith(paymentUrl: url, busy: false);
      return url;
    } catch (error) {
      final status = error is DioException ? error.response?.statusCode : null;
      final uncertain = creatingLink && (status == null || status >= 500);
      if (creatingLink && !uncertain) {
        try {
          await _store?.remove(reservationId);
        } catch (_) {
          // Keep the persisted intent if local cleanup fails.
        }
      }
      if (mounted) {
        state = state.copyWith(
            busy: false,
            paymentUncertain: uncertain,
            error: uncertain
                ? 'Chưa xác định được kết quả tạo giao dịch. Vui lòng liên hệ nhà hàng để kiểm tra trước khi tạo thanh toán mới.'
                : checkoutError(error));
      }
      return null;
    }
  }

  /// Callback query parameters are untrusted. Only the authenticated backend
  /// response for this reservation can establish a successful payment.
  Future<void> verifyPayment(String code) async {
    if (state.busy || state.paid) return;
    state = state.copyWith(busy: true, paymentCode: code);
    try {
      final result = await _repo.getPayment(code);
      if (!mounted) return;
      if (result.code != code ||
          result.reservationCode != state.checkout?.reservationCode ||
          result.target != 'RESERVATION') {
        throw StateError('Giao dịch không khớp với đặt bàn này.');
      }
      await _store?.save(reservationId, {
        'reservationCode': result.reservationCode,
        'depositAmount': state.checkout?.depositAmount,
        'url': state.paymentUrl?.toString(),
        'code': code,
        'uncertain': false,
      });
      if (!mounted) return;
      state = state.copyWith(
          paymentCode: code,
          payment: result,
          busy: false,
          error: result.status == 'FAILED'
              ? 'Thanh toán chưa thành công. Vui lòng kiểm tra lại giao dịch.'
              : null);
    } catch (error) {
      if (mounted) {
        state = state.copyWith(busy: false, error: checkoutError(error));
      }
    }
  }
}

String checkoutError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    final message = data is Map ? data['message']?.toString() : null;
    const messages = {
      'order.voucher.min_value_not_met':
          'Giá trị món ăn chưa đạt mức tối thiểu của voucher.',
      'voucher.expired': 'Voucher đã hết hạn.',
      'voucher.usage_exhausted': 'Voucher đã hết lượt sử dụng.',
      'voucher.not_assigned_to_user': 'Voucher này chưa được cấp cho bạn.',
      'Voucher not found': 'Mã voucher không tồn tại.',
      'order.voucher.order_has_no_items':
          'Cần có món ăn trong đơn để áp voucher.',
    };
    if (message != null && message.isNotEmpty) {
      return messages[message] ?? message;
    }
    return 'Không thể kết nối máy chủ. Vui lòng thử lại.';
  }
  if (error is StateError) return error.message;
  if (error is FormatException) return error.message;
  return 'Không thể xử lý thanh toán. Vui lòng tải lại thông tin.';
}
