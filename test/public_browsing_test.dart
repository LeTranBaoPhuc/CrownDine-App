import 'package:crowndine/data/repositories/admin_voucher_repository.dart';
import 'package:crowndine/providers/public_voucher_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'api_session_test.dart' show Adapter, body;

void main() {
  test('homepage fetches only the public promotion endpoint', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/'));
    dio.httpClientAdapter = Adapter((request) async {
      expect(request.path, 'vouchers/public');
      expect(request.queryParameters, {'page': 1, 'size': 20});
      return body(200, {
        'status': 200,
        'data': {
          'page': 1,
          'totalPages': 1,
          'totalItems': 1,
          'data': [
            {
              'id': 1,
              'code': 'WELCOME',
              'name': 'Welcome',
              'type': 'PERCENTAGE',
              'discountValue': 10,
            }
          ]
        }
      });
    });
    final container = ProviderContainer(overrides: [
      adminVoucherRepositoryProvider
          .overrideWithValue(AdminVoucherRepository(dio: dio)),
    ]);
    addTearDown(container.dispose);
    final vouchers = await container.read(publicVouchersProvider.future);
    expect(vouchers.single.code, 'WELCOME');
  });

  test('promotion failures remain errors so the homepage can offer retry',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/'));
    dio.httpClientAdapter = Adapter((_) async => body(503, {'status': 503}));
    final container = ProviderContainer(overrides: [
      adminVoucherRepositoryProvider
          .overrideWithValue(AdminVoucherRepository(dio: dio)),
    ]);
    addTearDown(container.dispose);
    await expectLater(container.read(publicVouchersProvider.future),
        throwsA(isA<DioException>()));
  });
}
