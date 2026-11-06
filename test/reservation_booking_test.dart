import 'dart:async';
import 'package:crowndine/data/models/item_model.dart';
import 'package:crowndine/data/models/reservation_model.dart';
import 'package:crowndine/data/models/table_model.dart';
import 'package:crowndine/data/repositories/reservation_booking_repository.dart';
import 'package:crowndine/data/repositories/reservation_repository.dart';
import 'package:crowndine/data/storage/payment_attempt_store.dart';
import 'package:crowndine/providers/reservation_provider.dart';
import 'package:crowndine/providers/reservation_checkout_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reservation_checkout_test.dart' show FakeCheckoutRepository;

ItemModel item(int id, {bool combo = false}) => ItemModel(
    id: id,
    categoryId: 1,
    name: 'Món $id',
    description: '',
    imageUrl: '',
    price: 100000,
    isCombo: combo);

class FakeBooking extends ReservationBookingRepository {
  FakeBooking() : super(dio: Dio());
  int creates = 0;
  int syncs = 0;
  bool failSync = true;
  Completer<int>? pending;
  @override
  Future<void> verifyTable(TableModel selected) async {}
  @override
  Future<int> create(
      {required String date,
      required String time,
      required int guests,
      required int tableId,
      required String note}) async {
    creates++;
    return pending == null ? 42 : await pending!.future;
  }

  @override
  Future<void> syncItems(int id, List<CartItemModel> desired) async {
    syncs++;
    if (failSync) throw StateError('Offline');
  }
}

class RejectedPaymentRepository extends FakeCheckoutRepository {
  @override
  Future<Uri> createPayment(String code) async {
    creates++;
    throw DioException(
        requestOptions: RequestOptions(path: 'payments/create'),
        response: Response(
            requestOptions: RequestOptions(path: 'payments/create'),
            statusCode: 400),
        type: DioExceptionType.badResponse);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'partial cart failure retains reservation ID; retry never creates another booking',
      () async {
    final repo = FakeBooking();
    final controller =
        ReservationNotifier(ReservationRepository(), booking: repo);
    addTearDown(controller.dispose);
    controller.selectTable(TableModel(
        id: 1,
        name: 'Bàn 1',
        capacity: 4,
        deposit: 200000,
        status: TableStatus.available));
    expect(await controller.prepareCheckout(), false);
    expect(controller.state.backendReservationId, 42);
    repo.failSync = false;
    expect(await controller.prepareCheckout(), true);
    expect(repo.creates, 1);
    expect(controller.state.currentStep, 4);
  });

  test('double tap and cart edits are blocked while creating reservation',
      () async {
    final repo = FakeBooking()
      ..pending = Completer<int>()
      ..failSync = false;
    final controller =
        ReservationNotifier(ReservationRepository(), booking: repo);
    addTearDown(controller.dispose);
    controller.selectTable(TableModel(
        id: 1,
        name: 'Bàn 1',
        capacity: 4,
        deposit: 200000,
        status: TableStatus.available));
    final first = controller.prepareCheckout();
    expect(await controller.prepareCheckout(), false);
    controller.addPreOrderItem(item(1));
    expect(controller.state.preOrderItems, isEmpty);
    repo.pending!.complete(42);
    await first;
    expect(repo.creates, 1);
  });

  test(
      'item and combo with same numeric ID stay separate and updates are immutable',
      () {
    final controller =
        ReservationNotifier(ReservationRepository(), booking: FakeBooking());
    addTearDown(controller.dispose);
    controller.addPreOrderItem(item(1));
    final before = controller.state.preOrderItems.single;
    controller.addPreOrderItem(item(1, combo: true));
    controller.updatePreOrderItemQuantity(1, 3, isCombo: true);
    expect(controller.state.preOrderItems.length, 2);
    expect(before.quantity, 1);
    expect(controller.state.preOrderItems.last.quantity, 3);
  });

  test('cart sync retries a lost add response without doubling server quantity',
      () async {
    final lines = <Map<String, dynamic>>[];
    var loseResponse = true;
    var adds = 0;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        if (options.method == 'GET') {
          handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: {
            'data': {
              'reservationId': 42,
              'reservationStatus': 'PENDING',
              'items': List.of(lines),
            }
          }));
        } else if (options.method == 'POST') {
          adds++;
          final body = options.data as Map;
          lines.add({
            'productId': body['itemId'],
            'type': 'ITEM',
            'quantity': body['quantity']
          });
          if (loseResponse) {
            loseResponse = false;
            handler.reject(DioException(
                requestOptions: options,
                type: DioExceptionType.receiveTimeout));
          } else {
            handler.resolve(
                Response(requestOptions: options, statusCode: 200, data: {}));
          }
        }
      }));
    final repo = ReservationBookingRepository(dio: dio);
    final cart = [CartItemModel(item: item(1), quantity: 2)];
    await expectLater(repo.syncItems(42, cart), throwsA(isA<DioException>()));
    await repo.syncItems(42, cart);
    expect(adds, 1);
    expect(lines.single['quantity'], 2);
  });

  test(
      'sync uses absolute PUT, removes obsolete items and distinguishes combos',
      () async {
    final lines = <Map<String, dynamic>>[
      {'productId': 1, 'type': 'ITEM', 'quantity': 1},
      {'productId': 2, 'type': 'ITEM', 'quantity': 1},
    ];
    final mutations = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        if (options.method != 'GET') {
          mutations.add(options);
          final body = options.data as Map;
          if (options.method == 'DELETE') {
            lines.removeWhere((e) => e['productId'] == body['itemId']);
          }
          if (options.method == 'PUT') {
            lines.first['quantity'] = body['quantity'];
          }
          if (options.method == 'POST') {
            lines.add({
              'productId': body['comboId'],
              'type': 'COMBO',
              'quantity': body['quantity']
            });
          }
        }
        handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'data': {
            'reservationId': 42,
            'reservationStatus': 'PENDING',
            'items': List.of(lines),
          }
        }));
      }));
    await ReservationBookingRepository(dio: dio).syncItems(42, [
      CartItemModel(item: item(1), quantity: 3),
      CartItemModel(item: item(1, combo: true), quantity: 2),
    ]);
    expect(mutations.map((e) => e.method), ['DELETE', 'PUT', 'POST']);
    expect(mutations.last.data, containsPair('comboId', 1));
    expect(lines.map((e) => e['quantity']), [3, 2]);
  });

  test(
      'saved payment link is reused after provider recreation without another charge',
      () async {
    final repo = FakeCheckoutRepository();
    final store = PaymentAttemptStore(1);
    final first = ReservationCheckoutNotifier(repo, 7, store: store);
    await first.refresh();
    final url = await first.startPayment();
    first.dispose();
    final second = ReservationCheckoutNotifier(repo, 7, store: store);
    addTearDown(second.dispose);
    await second.refresh();
    expect(await second.startPayment(), url);
    expect(repo.creates, 1);
    expect(second.state.paid, isFalse);
  });

  test('unfinished persisted intent blocks creation and is scoped to customer',
      () async {
    final store = PaymentAttemptStore(1);
    await store.save(7, {'reservationCode': 'CR-7', 'uncertain': true});
    expect(await PaymentAttemptStore(2).read(7), isNull);
    final repo = FakeCheckoutRepository();
    final controller = ReservationCheckoutNotifier(repo, 7, store: store);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(await controller.startPayment(), isNull);
    expect(repo.creates, 0);
  });

  test('definite rejected payment clears saved intent for a later retry',
      () async {
    final store = PaymentAttemptStore(1);
    final repo = RejectedPaymentRepository();
    final controller = ReservationCheckoutNotifier(repo, 7, store: store);
    addTearDown(controller.dispose);
    await controller.refresh();
    expect(await controller.startPayment(), isNull);
    expect(await store.read(7), isNull);
    expect(controller.state.paymentUncertain, isFalse);
  });
}
