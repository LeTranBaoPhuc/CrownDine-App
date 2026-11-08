import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crowndine/presentation/screens/staff/floor_plan/floor_plan_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowndine/data/models/item_model.dart';
import 'package:crowndine/data/models/order_model.dart';
import 'package:crowndine/data/models/table_model.dart';
import 'package:crowndine/data/repositories/table_repository.dart';
import 'package:crowndine/data/repositories/order_repository.dart';
import 'package:crowndine/data/repositories/menu_repository.dart';
import 'package:crowndine/providers/menu_provider.dart';
import 'package:crowndine/providers/order_provider.dart';
import 'package:crowndine/providers/table_provider.dart';
import 'package:crowndine/presentation/screens/staff/floor_plan/table_items_sheet.dart';

Map<String, dynamic> tableJson([String status = 'AVAILABLE']) => {
      'id': 7,
      'name': 'Bàn A',
      'capacity': 4,
      'floorId': 3,
      'floorName': 'Tầng thật',
      'deposit': 250000,
      'status': status,
      'x': 120,
      'y': 80,
      'width': 100,
      'height': 60,
      'rotation': 45,
    };
Map<String, dynamic> orderJson({int tableId = 7}) => {
      'id': 11,
      'code': 'ORDER11',
      'tableId': tableId,
      'status': 'IN_PROGRESS',
      'orderDetails': [
        {
          'id': 1,
          'combo': {'name': 'Combo tối'},
          'quantity': 2,
          'status': 'PENDING',
          'totalPrice': 300000
        }
      ],
    };
ItemModel product({bool combo = false}) => ItemModel(
    id: 1,
    categoryId: 2,
    name: combo ? 'Combo tối' : 'Món chính',
    description: '',
    imageUrl: '',
    price: 150000,
    isCombo: combo);

class _Catalog extends MenuRepository {
  @override
  Future<List<ItemModel>> getItems(
          {int? categoryId,
          String? search,
          String? sortBy,
          String? dir,
          Map<int, String>? categoryNames}) async =>
      [product(), product(combo: true)];
}

class _Orders extends OrderRepository {
  final pending = Completer<OrderModel>();
  int calls = 0;
  List<TableOrderLine>? sent;
  int? expected;
  _Orders() : super(dio: Dio());
  @override
  Future<OrderModel?> getActiveTableOrder(int tableId) async =>
      OrderModel.fromJson(orderJson());
  @override
  Future<OrderModel> addItemsAtTable(int tableId, List<TableOrderLine> lines,
      {int? expectedOrderId}) {
    calls++;
    sent = lines;
    expected = expectedOrderId;
    return pending.future;
  }
}

class _Tables extends TableRepository {
  final update = Completer<TableModel>();
  _Tables() : super(dio: Dio());
  @override
  Future<List<FloorModel>> getFloors() async =>
      [FloorModel(id: 3, name: 'Tầng thật')];
  @override
  Future<List<TableModel>> getTables({int? floorId}) async =>
      [TableModel.fromJson(tableJson())];
  @override
  Future<TableModel> updateStatus(int tableId, TableStatus status) =>
      update.future;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('table API preserves empty data, real geometry, and exact status PATCH',
      () async {
    final calls = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        calls.add(options);
        handler.resolve(Response(requestOptions: options, data: {
          'status': 200,
          'data': options.path == 'layout/floors'
              ? []
              : options.method == 'PATCH'
                  ? tableJson('UNAVAILABLE')
                  : [tableJson()]
        }));
      }));
    final repo = TableRepository(dio: dio);
    expect(await repo.getFloors(), isEmpty);
    final table = (await repo.getTables()).single;
    expect(table.deposit, 250000);
    expect(table.x, 120);
    expect(table.rotation, 45);
    expect((await repo.updateStatus(7, TableStatus.unavailable)).status,
        TableStatus.unavailable);
    expect(calls.last.path, 'restaurant-tables/7');
    expect(calls.last.queryParameters, {'status': 'UNAVAILABLE'});
    expect(TableStatus.fromString('UNKNOWN'), TableStatus.unavailable);
  });

  test('API failure and malformed body never turn into mock tables or orders',
      () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 403)))));
    await expectLater(
        TableRepository(dio: dio).getTables(), throwsA(isA<DioException>()));
    await expectLater(
        OrderRepository(dio: dio).getAllOrders(), throwsA(isA<DioException>()));
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (o, h) =>
            h.resolve(Response(requestOptions: o, data: {'status': 200}))));
    await expectLater(
        TableRepository(dio: dio).getTables(), throwsA(isA<FormatException>()));
  });

  test(
      'new dishes use table ID, expected session and distinguish item from combo',
      () async {
    final calls = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        calls.add(options);
        handler.resolve(Response(requestOptions: options, data: {
          'status': 200,
          'data': options.path == 'orders/kitchen' ? [] : orderJson()
        }));
      }));
    final repo = OrderRepository(dio: dio);
    expect(await repo.getAllOrders(), isEmpty);
    expect((await repo.getActiveTableOrder(7))!.id, 11);
    final order = await repo.addItemsAtTable(
        7,
        [
          TableOrderLine(item: product(), quantity: 2, note: ' Không cay '),
          TableOrderLine(item: product(combo: true), quantity: 1),
        ],
        expectedOrderId: 11);
    expect(order.details.single.itemName, 'Combo tối');
    expect(calls.last.path, 'orders/tables/7/details');
    expect(calls.last.data, {
      'expectedOrderId': 11,
      'items': [
        {'itemId': 1, 'quantity': 2, 'note': 'Không cay'},
        {'comboId': 1, 'quantity': 1},
      ]
    });
  });

  test('wrong table response is rejected and no active order stays null',
      () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(
          onRequest: (o, h) => h.resolve(Response(
              requestOptions: o,
              data: {'status': 200, 'data': orderJson(tableId: 8)}))));
    final repo = OrderRepository(dio: dio);
    await expectLater(
        repo.getActiveTableOrder(7), throwsA(isA<FormatException>()));
    await expectLater(
        repo.addItemsAtTable(7, [TableOrderLine(item: product(), quantity: 1)]),
        throwsA(isA<FormatException>()));
    dio.interceptors.clear();
    dio.interceptors.add(InterceptorsWrapper(
        onRequest: (o, h) =>
            h.resolve(Response(requestOptions: o, data: {'status': 200}))));
    expect(await repo.getActiveTableOrder(7), isNull);
  });

  test(
      'table state waits for confirmation and does not change after failed mutation',
      () async {
    final repo = _Tables();
    final notifier = TableNotifier(repo);
    await Future<void>.delayed(Duration.zero);
    final request = notifier.updateTableStatus(7, TableStatus.reserved);
    expect(notifier.state.allTables.single.status, TableStatus.available);
    expect(await notifier.updateTableStatus(7, TableStatus.unavailable), false);
    repo.update.completeError(StateError('Bàn còn đơn'));
    expect(await request, false);
    expect(notifier.state.allTables.single.status, TableStatus.available);
    expect(notifier.state.errorMessage, 'Bàn còn đơn');
    notifier.dispose();
  });

  testWidgets(
      'staff can select quantity and notes; double tap sends once and waits for backend',
      (tester) async {
    final repo = _Orders();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          menuRepositoryProvider.overrideWithValue(_Catalog()),
          orderRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: TableItemsSheet(
                    table: TableModel.fromJson(tableJson('OCCUPIED')))))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Thêm Món chính'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const ValueKey('note-item:1')), 'Ít muối');
    final send = find.byKey(const ValueKey('send-table-items'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();
    await tester.tap(send);
    await tester.pump();
    expect(repo.calls, 1);
    expect(repo.expected, 11);
    expect(repo.sent!.single.quantity, 1);
    expect(repo.sent!.single.note, 'Ít muối');
    expect(find.text('Đang gửi…'), findsOneWidget);
    repo.pending.completeError(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.receiveTimeout));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa xác định được kết quả'), findsOneWidget);
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
  });
  testWidgets(
      'floor plan fits a phone and uses live table names in grid and map',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      tableRepositoryProvider.overrideWithValue(_Tables()),
    ], child: const MaterialApp(home: FloorPlanScreen())));
    await tester.pumpAndSettle();
    expect(find.text('Tầng thật'), findsOneWidget);
    expect(find.text('Bàn A'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Xem vị trí bàn'));
    await tester.pumpAndSettle();
    expect(find.text('Bàn A\nBàn trống'), findsOneWidget);
    await tester.tap(find.text('Bàn A\nBàn trống'));
    await tester.pumpAndSettle();
    expect(find.text('Mở bàn & gọi món'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
