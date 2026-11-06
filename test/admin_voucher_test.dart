import 'package:crowndine/data/models/admin_voucher_model.dart';
import 'package:crowndine/data/repositories/admin_voucher_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> voucher([int id = 4]) => {
      'id': id,
      'code': 'SAVE20',
      'name': 'Giảm 20%',
      'type': 'PERCENTAGE',
      'discountValue': 20,
      'maxDiscountValue': 100000,
      'minValue': 200000,
      'description': 'Ưu đãi',
    };

void main() {
  test('admin voucher API uses paged list and exact CRUD methods', () async {
    final calls = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          calls.add(options);
          final data = options.method == 'DELETE'
              ? null
              : options.method == 'GET' && options.path == 'vouchers'
                  ? {
                      'page': 2,
                      'totalPages': 3,
                      'totalItems': 21,
                      'data': [voucher()]
                    }
                  : voucher();
          handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'status': 200, 'data': data}));
        },
      ));
    final repo = AdminVoucherRepository(dio: dio);
    final page = await repo.list(
        page: 2, search: 'SAVE', type: AdminVoucherType.percentage);
    expect(page.items.single.code, 'SAVE20');
    expect(page.totalItems, 21);
    expect(calls.first.queryParameters, containsPair('type', 'PERCENTAGE'));
    expect((await repo.get(4)).id, 4);
    const draft = AdminVoucherDraft(
        code: ' save20 ',
        name: 'Giảm 20%',
        type: AdminVoucherType.percentage,
        discountValue: 20,
        maxDiscountValue: 100000,
        minValue: 200000,
        description: 'Ưu đãi');
    await repo.create(draft);
    await repo.update(4, draft);
    await repo.delete(4);
    expect(calls.map((e) => '${e.method} ${e.path}'), [
      'GET vouchers',
      'GET vouchers/4',
      'POST vouchers',
      'PATCH vouchers/4',
      'DELETE vouchers/4'
    ]);
    expect(calls[2].data, containsPair('code', 'SAVE20'));
  });

  test('malformed voucher response does not become an empty success', () async {
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'status': 200,
            'data': {'data': []}
          },
        )),
      ));
    await expectLater(AdminVoucherRepository(dio: dio).list(),
        throwsA(isA<FormatException>()));
    expect(() => AdminVoucherModel.fromJson({...voucher(), 'type': 'UNKNOWN'}),
        throwsA(isA<FormatException>()));
  });
}
