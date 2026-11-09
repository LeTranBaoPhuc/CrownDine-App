import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowndine/data/repositories/admin_setup_repository.dart';
import 'package:crowndine/data/repositories/order_repository.dart';
import 'package:crowndine/providers/order_provider.dart';
import 'package:crowndine/presentation/screens/admin/setup/admin_setup_screen.dart';
import 'package:crowndine/presentation/screens/staff/orders/order_settlement_screen.dart';

class SetupRepo extends AdminSetupRepository {
  int writes = 0;
  @override
  Future<void> save(SetupKind kind, Map<String, dynamic> data,
      {int? id, int? parentId}) async {
    writes++;
    throw StateError('Máy chủ từ chối lưu');
  }
}

class SettlementRepo extends OrderRepository {
  SettlementRepo() : super(dio: Dio());
  int writes = 0;
  @override
  Future<Map<String, dynamic>> getCheckout(int id) async => {
        'orderId': id,
        'orderCode': 'O1',
        'status': 'SERVED',
        'totalAmount': 1500000,
        'voucherDiscount': 0,
        'orderDepositPaidAmount': 200000,
        'finalAmount': 1300000
      };
  @override
  Future<Map<String, dynamic>?> latestPayment(int id) async => {
        'code': 99,
        'target': 'ORDER',
        'orderCode': 'O1',
        'status': 'PENDING',
        'method': 'PAYOS'
      };
  @override
  Future<void> createSettlement(String orderCode, String method) async {
    writes++;
  }
}

void main() {
  testWidgets('pending PayOS blocks cash confirmation and never claims success',
      (tester) async {
    final repo = SettlementRepo();
    await tester.pumpWidget(ProviderScope(
        overrides: [orderRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: OrderSettlementScreen(orderId: 1))));
    await tester.pumpAndSettle();
    expect(find.text('Đã thanh toán thành công'), findsNothing);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Xác nhận thu tiền'))
            .onPressed,
        isNull);
    expect(repo.writes, 0);
  });
  testWidgets(
      'failed setup write retains form and error without success navigation',
      (tester) async {
    final repo = SetupRepo();
    await tester.pumpWidget(ProviderScope(
        overrides: [adminSetupRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
            home: SetupEditScreen(kind: SetupKind.category))));
    await tester.enterText(find.byType(TextFormField).first, 'Món chính');
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(find.byType(SetupEditScreen), findsOneWidget);
    expect(find.textContaining('Máy chủ từ chối lưu'), findsOneWidget);
  });
  testWidgets('combo cannot be saved without a dish', (tester) async {
    final repo = SetupRepo();
    await tester.pumpWidget(ProviderScope(overrides: [
      adminSetupRepositoryProvider.overrideWithValue(repo)
    ], child: const MaterialApp(home: SetupEditScreen(kind: SetupKind.combo))));
    await tester.enterText(find.byType(TextFormField).at(0), 'Combo tối');
    await tester.enterText(find.byType(TextFormField).at(2), '250000');
    await tester.scrollUntilVisible(find.text('Lưu thay đổi'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(repo.writes, 0);
    expect(find.text('Combo cần ít nhất một món.'), findsOneWidget);
  });
}
