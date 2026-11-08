import 'dart:async';
import 'package:crowndine/data/models/reservation_checkout_model.dart';
import 'package:crowndine/data/repositories/reservation_checkout_repository.dart';
import 'package:crowndine/presentation/screens/customer/reservation/payos_payment_screen.dart';
import 'package:crowndine/presentation/screens/customer/reservation/reservation_payment_panel.dart';
import 'package:crowndine/providers/reservation_checkout_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> quote(
        {double deposit = 380000,
        int? orderId = 12,
        String status = 'PENDING'}) =>
    {
      'reservationId': 7,
      'reservationCode': 'CR-7',
      'orderId': orderId,
      'reservationStatus': status,
      'itemsTotal': 1000000,
      'discountAmount': 100000,
      'finalAmount': 900000,
      'tableDeposit': 200000,
      'depositAmount': deposit,
      'remainingAmount': 720000,
    };

class FakeCheckoutRepository extends ReservationCheckoutRepository {
  FakeCheckoutRepository() : super(dio: Dio());
  @override
  Future<Map<String, dynamic>?> latestPayment(int reservationId) async => null;

  Map<String, dynamic> response = quote();
  int creates = 0;
  int applies = 0;
  bool failRefresh = false;
  bool failCreate = false;
  bool failAfterApply = false;
  Completer<ReservationCheckoutModel>? pending;
  ReservationPaymentResult result = const ReservationPaymentResult(
      code: '99',
      reservationCode: 'CR-7',
      status: 'PENDING',
      target: 'RESERVATION',
      amount: 380000);

  @override
  Future<ReservationCheckoutModel> getCheckout(int id) async {
    if (pending != null) return pending!.future;
    if (failRefresh) throw StateError('Offline');
    return ReservationCheckoutModel.fromJson(response);
  }

  @override
  Future<void> applyVoucher(int id, String code) async {
    applies++;
    if (failAfterApply) failRefresh = true;
  }

  @override
  Future<Uri> createPayment(String code) async {
    creates++;
    if (failCreate) {
      throw DioException(
          requestOptions: RequestOptions(path: 'payments/create'),
          type: DioExceptionType.receiveTimeout);
    }
    return Uri.parse('https://pay.payos.vn/web/abc');
  }

  @override
  Future<ReservationPaymentResult> getPayment(String code) async => result;
}

void main() {
  test('missing server money cannot become a zero/default payable quote', () {
    final data = quote()..remove('depositAmount');
    expect(
        () => ReservationCheckoutModel.fromJson(data), throwsFormatException);
  });

  test(
      'expired and terminal reservations cannot pay; no-food cannot use voucher',
      () {
    final expired = quote()..['expiratedAt'] = '2020-01-01T00:00:00';
    expect(ReservationCheckoutModel.fromJson(expired).canPay, isFalse);
    expect(ReservationCheckoutModel.fromJson(quote(status: 'CONFIRMED')).canPay,
        isFalse);
    expect(
        ReservationCheckoutModel.fromJson(quote(orderId: null)).canApplyVoucher,
        isFalse);
  });

  test('changed deposit requires another review before creating payment',
      () async {
    final repo = FakeCheckoutRepository();
    final controller = ReservationCheckoutNotifier(repo, 7);
    addTearDown(controller.dispose);
    await controller.refresh();
    repo.response = quote(deposit: 400000);
    expect(await controller.startPayment(), isNull);
    expect(repo.creates, 0);
    expect(controller.state.checkout!.depositAmount, 400000);
    expect(controller.state.error, contains('thay đổi'));
    expect(await controller.startPayment(), isNotNull);
    expect(repo.creates, 1);
  });

  test('closing and reopening payment reuses the link; voucher is frozen',
      () async {
    final repo = FakeCheckoutRepository();
    final controller = ReservationCheckoutNotifier(repo, 7);
    addTearDown(controller.dispose);
    await controller.refresh();
    final first = await controller.startPayment();
    expect(await controller.startPayment(), first);
    await controller.changeVoucher('NEW');
    expect(repo.creates, 1);
    expect(repo.applies, 0);
  });

  test('double tap while refreshing does not create duplicate links', () async {
    final repo = FakeCheckoutRepository();
    final controller = ReservationCheckoutNotifier(repo, 7);
    addTearDown(controller.dispose);
    await controller.refresh();
    repo.pending = Completer<ReservationCheckoutModel>();
    final first = controller.startPayment();
    expect(await controller.startPayment(), isNull);
    repo.pending!.complete(ReservationCheckoutModel.fromJson(quote()));
    await first;
    expect(repo.creates, 1);
  });

  test('successful voucher mutation with failed refresh blocks stale payment',
      () async {
    final repo = FakeCheckoutRepository()..failAfterApply = true;
    final controller = ReservationCheckoutNotifier(repo, 7);
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.changeVoucher('SAVE');
    expect(controller.state.checkout, isNull);
    expect(await controller.startPayment(), isNull);
    expect(repo.creates, 0);
  });

  test('redirect PAID does not establish success; backend identity must match',
      () async {
    final callback = PayOSCallback.parse(
        'http://localhost:5173/thanh-toan/thanh-cong?orderCode=99&status=PAID');
    expect(callback!.paymentCode, '99');
    final repo = FakeCheckoutRepository();
    final controller = ReservationCheckoutNotifier(repo, 7);
    addTearDown(controller.dispose);
    await controller.refresh();
    await controller.verifyPayment(callback.paymentCode);
    expect(controller.state.paid, isFalse);
    repo.result = const ReservationPaymentResult(
        code: '99',
        reservationCode: 'CR-OTHER',
        status: 'SUCCESS',
        target: 'RESERVATION',
        amount: 380000);
    await controller.verifyPayment('99');
    expect(controller.state.paid, isFalse);
    expect(controller.state.error, contains('không khớp'));
    repo.result = const ReservationPaymentResult(
        code: '99',
        reservationCode: 'CR-7',
        status: 'SUCCESS',
        target: 'RESERVATION',
        amount: 380000);
    await controller.verifyPayment('99');
    expect(controller.state.paid, isTrue);
  });

  test('ambiguous create timeout blocks a second payment creation', () async {
    final repo = FakeCheckoutRepository()..failCreate = true;
    final controller = ReservationCheckoutNotifier(repo, 7);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(await controller.startPayment(), isNull);
    expect(controller.state.paymentUncertain, isTrue);
    expect(await controller.startPayment(), isNull);
    expect(repo.creates, 1);
  });

  test('callback parser ignores unrelated URLs and malformed codes', () {
    expect(
        PayOSCallback.parse('https://pay.payos.vn/?orderCode=99&status=PAID'),
        isNull);
    expect(
        PayOSCallback.parse(
            'http://localhost/thanh-toan/thanh-cong?orderCode=../../42'),
        isNull);
    expect(
        PayOSCallback.parse(
                'http://localhost/thanh-toan/that-bai?orderCode=99&cancel=true')!
            .cancelled,
        isTrue);
  });

  test(
      'repository uses backend payment amount, normalization and exact API paths',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests.add(options);
        handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'status': 200,
          'data': options.path == 'payments/create'
              ? 'https://pay.payos.vn/web/abc'
              : <String, dynamic>{},
        }));
      }));
    final repo = ReservationCheckoutRepository(dio: dio);
    await repo.applyVoucher(12, ' save ');
    await repo.createPayment('CR-7');
    expect(requests.map((r) => r.path),
        ['vouchers/validate', 'orders/12/voucher/apply', 'payments/create']);
    expect(requests.first.data, {'orderId': 12, 'code': 'SAVE'});
    expect(requests.last.data, {'reservationCode': 'CR-7', 'method': 'PAYOS'});
  });

  testWidgets('payment panel shows server deposit rather than full food total',
      (tester) async {
    final repo = FakeCheckoutRepository();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          reservationCheckoutRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ReservationPaymentPanel(reservationId: 7))))));
    await tester.pumpAndSettle();
    expect(find.text('Mã đặt bàn: CR-7'), findsOneWidget);
    expect(find.text('Cọc cần thanh toán'), findsOneWidget);
    expect(find.textContaining('380.000'), findsOneWidget);
    expect(find.text('Thanh toán cọc thành công'), findsNothing);
    expect(find.textContaining('tiền mặt'), findsNothing);
  });
}
