import 'package:crowndine/data/repositories/menu_repository.dart';
import 'package:crowndine/data/models/item_model.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crowndine/core/network/api_client.dart';
import 'package:crowndine/data/repositories/attendance_repository.dart';

class Adapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) respond;
  Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody body(int status, Object data) =>
    ResponseBody.fromString(jsonEncode(data), status, headers: {
      Headers.contentTypeHeader: ['application/json']
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({
        'access_token': 'old',
        'refresh_token': 'refresh',
        'username': 'alice'
      }));
  test(
      'concurrent 401 responses share one refresh and preserve login on a business error',
      () async {
    final dio = Dio();
    final refresh = Dio();
    int calls = 0;
    refresh.httpClientAdapter = Adapter((_) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 15));
      return body(200, {
        'data': {'accessToken': 'new'}
      });
    });
    dio.httpClientAdapter = Adapter((o) async =>
        o.headers['Authorization'] == 'Bearer old'
            ? body(401, {})
            : body(o.path == 'invalid-write' ? 409 : 200, {}));
    ApiClient.forTesting(dio: dio, refreshDio: refresh);
    await Future.wait([dio.get('profile'), dio.get('wallet')]);
    expect(calls, 1);
    await expectLater(dio.post('invalid-write'), throwsA(isA<DioException>()));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), 'new');
    expect(prefs.getString('refresh_token'), 'refresh');
  });
  test('logout during refresh cannot recreate credentials or replay a write',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final dio = Dio(), refresh = Dio();
    int writes = 0;
    dio.httpClientAdapter = Adapter((_) async {
      writes++;
      return body(401, {});
    });
    refresh.httpClientAdapter = Adapter((_) async {
      started.complete();
      await release.future;
      return body(200, {
        'data': {'accessToken': 'new'}
      });
    });
    ApiClient.forTesting(dio: dio, refreshDio: refresh);
    final pending =
        expectLater(dio.post('orders'), throwsA(isA<DioException>()));
    await started.future;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('username');
    release.complete();
    await pending;
    expect(prefs.getString('access_token'), isNull);
    expect(writes, 1);
  });
  test('login does not send an expired bearer token', () async {
    final dio = Dio();
    dio.httpClientAdapter = Adapter((o) async {
      expect(o.headers.containsKey('Authorization'), false);
      return body(200, {});
    });
    ApiClient.forTesting(dio: dio, refreshDio: Dio());
    await dio.post('auth/login');
  });
  test('attendance API failures never become mock records or successful writes',
      () async {
    final dio = Dio()
      ..httpClientAdapter =
          Adapter((_) async => body(503, {'message': 'offline'}));
    await expectLater(AttendanceRepository(dio: dio).getWeeklySchedule(),
        throwsA(isA<DioException>()));
  });
  test('combo status changes use combo API and preserve constituent dishes',
      () async {
    final paths = <String>[];
    final dio = Dio()
      ..httpClientAdapter = Adapter((o) async {
        paths.add('${o.method} ${o.path}');
        if (o.method == 'GET')
          return body(200, {
            'status': 200,
            'data': {
              'id': 1,
              'name': 'Combo',
              'price': 200000,
              'items': [
                {'itemId': 7, 'quantity': 2}
              ]
            }
          });
        expect(o.data['items'], [
          {'itemId': 7, 'quantity': 2}
        ]);
        expect(o.data['status'], 'UNAVAILABLE');
        return body(200, {'status': 200});
      });
    final combo = ItemModel(
        id: 1,
        categoryId: 0,
        name: 'Combo',
        description: '',
        imageUrl: '',
        price: 200000,
        isCombo: true);
    expect(
        await MenuRepository(dio: dio).updateItemStatus(combo, 'UNAVAILABLE'),
        true);
    expect(paths, ['GET combos/1', 'PUT combos/1']);
  });
}
