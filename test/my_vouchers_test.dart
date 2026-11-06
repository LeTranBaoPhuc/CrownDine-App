import 'dart:async';
import 'package:crowndine/data/models/my_voucher_model.dart';
import 'package:crowndine/data/models/user_model.dart';
import 'package:crowndine/data/repositories/auth_repository.dart';
import 'package:crowndine/data/repositories/my_voucher_repository.dart';
import 'package:crowndine/presentation/screens/customer/profile/voucher_wallet_sheet.dart';
import 'package:crowndine/presentation/screens/customer/reservation/reservation_payment_panel.dart';
import 'package:crowndine/providers/auth_provider.dart';
import 'package:crowndine/providers/my_vouchers_provider.dart';
import 'package:crowndine/providers/reservation_checkout_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'reservation_checkout_test.dart' show FakeCheckoutRepository;

Map<String, dynamic> assignedVoucher({String type = 'FIXED_AMOUNT'}) => {
      'assignmentId': 1,
      'voucherId': 10,
      'voucherCode': 'SAVE50',
      'voucherName': 'Ưu đãi của tôi',
      'voucherType': type,
      'discountValue': type == 'PERCENTAGE' ? 10 : 50000,
      'maxDiscountValue': 100000,
      'minValue': 500000,
      'usageCount': 1,
      'usageLimit': 3,
      'expiredAt': '2099-12-31T23:59:00',
    };

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier() : super(AuthRepository());
  @override
  Future<void> checkAuthStatus() async {}
  void setUser(int? id) {
    state = AuthState(
        user: id == null
            ? null
            : UserModel(
                id: id, username: 'user$id', email: 'user$id@test.local'));
  }
}

class CountingRepository extends MyVoucherRepository {
  CountingRepository() : super(dio: Dio());
  int calls = 0;
  @override
  Future<List<MyVoucherModel>> getMyVouchers() async {
    calls++;
    return [
      MyVoucherModel.fromJson(assignedVoucher()..['voucherCode'] = 'CALL$calls')
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'parses assigned DTO with fixed amount, remaining uses and nullable limits',
      () {
    final voucher = MyVoucherModel.fromJson(assignedVoucher());
    expect(voucher.type, MyVoucherType.fixedAmount);
    expect(voucher.discountValue, 50000);
    expect(voucher.remainingUses, 2);
    expect(voucher.isAvailable, isTrue);
    final unlimited = assignedVoucher()
      ..['usageLimit'] = null
      ..['expiredAt'] = null;
    expect(MyVoucherModel.fromJson(unlimited).remainingUses, isNull);
    expect(MyVoucherModel.fromJson(unlimited).isAvailable, isTrue);
    expect(MyVoucherModel.fromJson(assignedVoucher(type: 'PERCENTAGE')).type,
        MyVoucherType.percentage);
  });

  test(
      'rejects unknown types and marks expired/exhausted assignments unavailable',
      () {
    expect(() => MyVoucherModel.fromJson(assignedVoucher(type: 'OTHER')),
        throwsFormatException);
    expect(
        MyVoucherModel.fromJson(
                assignedVoucher()..['expiredAt'] = '2020-01-01T00:00:00')
            .isAvailable,
        isFalse);
    expect(
        MyVoucherModel.fromJson(assignedVoucher()..['usageCount'] = 4)
            .remainingUses,
        0);
    expect(
        MyVoucherModel.fromJson(assignedVoucher()..['usageCount'] = 4)
            .isAvailable,
        isFalse);
  });

  test(
      'repository requests personal endpoint and surfaces errors without mock data',
      () async {
    var fail = false;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        expect(options.path, 'user-vouchers/my');
        if (fail) {
          handler.reject(DioException(
              requestOptions: options, type: DioExceptionType.connectionError));
        } else {
          handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: {
            'status': 200,
            'data': [assignedVoucher()]
          }));
        }
      }));
    final repo = MyVoucherRepository(dio: dio);
    expect((await repo.getMyVouchers()).single.code, 'SAVE50');
    fail = true;
    await expectLater(repo.getMyVouchers(), throwsA(isA<DioException>()));
  });

  test('account switch reloads wallet; logout cannot retain personal vouchers',
      () async {
    final auth = TestAuthNotifier()..setUser(1);
    final repo = CountingRepository();
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith((ref) => auth),
      myVoucherRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    container.listen(myVouchersProvider, (_, __) {});
    expect(
        (await container.read(myVouchersProvider.future)).single.code, 'CALL1');
    auth.setUser(2);
    expect(
        (await container.read(myVouchersProvider.future)).single.code, 'CALL2');
    auth.setUser(null);
    await expectLater(
        container.read(myVouchersProvider.future), throwsStateError);
    expect(repo.calls, 2);
  });

  testWidgets(
      'wallet shows fixed discount and copies exact code without closing',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(ProviderScope(overrides: [
      myVouchersProvider.overrideWith(
          (ref) async => [MyVoucherModel.fromJson(assignedVoucher())]),
    ], child: const MaterialApp(home: Scaffold(body: VoucherWalletSheet()))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Giảm 50.000'), findsOneWidget);
    expect(find.text('Còn 2 lượt sử dụng'), findsOneWidget);
    await tester.ensureVisible(find.text('Sao chép mã'));
    await tester.tap(find.text('Sao chép mã'));
    await tester.pumpAndSettle();
    expect(copied, 'SAVE50');
    expect(find.text('Ví voucher của tôi'), findsOneWidget);
  });

  testWidgets(
      'empty wallet and failed request are distinct; retry loads vouchers',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      myVouchersProvider.overrideWith((ref) async {
        attempts++;
        if (attempts == 1) throw StateError('Không có kết nối');
        return <MyVoucherModel>[];
      }),
    ], child: const MaterialApp(home: Scaffold(body: VoucherWalletSheet()))));
    await tester.pumpAndSettle();
    expect(find.text('Không có kết nối'), findsOneWidget);
    expect(find.text('Bạn chưa có voucher khả dụng.'), findsNothing);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có voucher khả dụng.'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('pending request shows loading rather than mock vouchers',
      (tester) async {
    final pending = Completer<List<MyVoucherModel>>();
    await tester.pumpWidget(ProviderScope(overrides: [
      myVouchersProvider.overrideWith((ref) => pending.future),
    ], child: const MaterialApp(home: Scaffold(body: VoucherWalletSheet()))));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('CROWNDINE50'), findsNothing);
    pending.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'selecting from wallet passes through real checkout validation flow',
      (tester) async {
    final repo = FakeCheckoutRepository();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          myVouchersProvider.overrideWith(
              (ref) async => [MyVoucherModel.fromJson(assignedVoucher())]),
          reservationCheckoutRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ReservationPaymentPanel(reservationId: 7))))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chọn từ ví voucher'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Áp dụng'));
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(repo.applies, 1);
    expect(find.text('Mã đã áp dụng: SAVE50'), findsOneWidget);
    expect(find.text('Chọn voucher'), findsNothing);
  });
}
