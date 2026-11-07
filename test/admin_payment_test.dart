import 'package:crowndine/data/models/admin_payment_model.dart';
import 'package:crowndine/data/repositories/admin_payment_repository.dart';
import 'package:crowndine/presentation/screens/admin/payment/admin_payment_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> payment([int id = 7]) => {
      'id': id,
      'code': 123456,
      'amount': 150000,
      'username': 'johncena',
      'orderCode': null,
      'reservationCode': 'RSV-7',
      'transactionCode': 'BANK-1',
      'method': 'PAYOS',
      'status': 'SUCCESS',
      'type': 'DEPOSIT',
      'target': 'RESERVATION',
      'source': 'CLIENT_APP',
      'createdAt': '2026-11-07T10:30:00',
      'updatedAt': '2026-11-07T10:31:00',
    };

class FakeAdminPaymentRepository extends AdminPaymentRepository {
  FakeAdminPaymentRepository() : super(dio: Dio());
  int listCalls = 0;
  int detailCalls = 0;
  AdminPaymentFilter? lastFilter;

  @override
  Future<AdminPaymentPage> list({
    int page = 1,
    int size = 10,
    AdminPaymentFilter filter = const AdminPaymentFilter(),
  }) async {
    listCalls++;
    lastFilter = filter;
    return AdminPaymentPage(
        items: [AdminPayment.fromJson(payment())],
        page: page,
        totalPages: 1,
        totalItems: 1);
  }

  @override
  Future<AdminPayment> detail(int id) async {
    detailCalls++;
    return AdminPayment.fromJson(payment(id));
  }
}

void main() {
  test('admin payment API sends filters and uses separate list/detail paths',
      () async {
    final calls = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        calls.add(options);
        handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'status': 200,
          'data': options.path == 'payments'
              ? {
                  'page': 2,
                  'totalPages': 3,
                  'totalItems': 21,
                  'data': [payment()]
                }
              : payment()
        }));
      }));
    final repo = AdminPaymentRepository(dio: dio);
    final page = await repo.list(
        page: 2,
        filter: AdminPaymentFilter(
            search: ' RSV-7 ',
            status: 'SUCCESS',
            method: 'PAYOS',
            type: 'DEPOSIT',
            target: 'RESERVATION',
            source: 'CLIENT_APP',
            fromDate: DateTime(2026, 11, 1),
            toDate: DateTime(2026, 11, 7)));
    expect(page.items.single.amount, 150000);
    expect(page.totalItems, 21);
    expect(calls.first.path, 'payments');
    expect(calls.first.queryParameters, containsPair('search', 'RSV-7'));
    expect(calls.first.queryParameters, containsPair('status', 'SUCCESS'));
    expect(calls.first.queryParameters, containsPair('fromDate', '2026-11-01'));
    expect(calls.first.queryParameters, containsPair('toDate', '2026-11-07'));
    expect((await repo.detail(7)).code, 123456);
    expect(calls.last.path, 'payments/7');
  });

  test('malformed and mismatched payment data is rejected', () async {
    expect(() => AdminPayment.fromJson({...payment(), 'amount': '150000'}),
        throwsFormatException);
    expect(AdminPayment.fromJson({...payment(), 'source': null}).source,
        'UNKNOWN');
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'status': 200, 'data': payment(9)}));
      }));
    await expectLater(
        AdminPaymentRepository(dio: dio).detail(7), throwsFormatException);
    await expectLater(
        AdminPaymentRepository(dio: dio).list(
            filter: AdminPaymentFilter(
                fromDate: DateTime(2026, 11, 8),
                toDate: DateTime(2026, 11, 7))),
        throwsArgumentError);
  });

  testWidgets('admin can open transaction detail and refresh it',
      (tester) async {
    final repo = FakeAdminPaymentRepository();
    await tester
        .pumpWidget(MaterialApp(home: AdminPaymentScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('1 giao dịch'), findsOneWidget);
    expect(find.text('GD #123456'), findsOneWidget);
    await tester.tap(find.text('GD #123456'));
    await tester.pumpAndSettle();
    expect(find.text('BANK-1'), findsOneWidget);
    expect(find.text('johncena'), findsOneWidget);
    await tester.tap(find.byTooltip('Làm mới giao dịch'));
    await tester.pumpAndSettle();
    expect(repo.detailCalls, 2);
  });

  testWidgets('search and status filter restart the list', (tester) async {
    final repo = FakeAdminPaymentRepository();
    await tester
        .pumpWidget(MaterialApp(home: AdminPaymentScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), ' RSV-7 ');
    await tester.tap(find.byTooltip('Tìm kiếm'));
    await tester.pumpAndSettle();
    expect(repo.lastFilter?.search, ' RSV-7 ');

    await tester.tap(find.byTooltip('Bộ lọc giao dịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thành công').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Áp dụng bộ lọc'));
    await tester.tap(find.text('Áp dụng bộ lọc'));
    await tester.pumpAndSettle();
    expect(repo.lastFilter?.status, 'SUCCESS');
  });
}
