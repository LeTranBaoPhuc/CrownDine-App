import 'package:crowndine/data/models/reward_point_model.dart';
import 'package:crowndine/data/models/user_model.dart';
import 'package:crowndine/data/repositories/auth_repository.dart';
import 'package:crowndine/data/repositories/reward_point_repository.dart';
import 'package:crowndine/presentation/screens/customer/profile/reward_points_screen.dart';
import 'package:crowndine/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRewardRepository extends RewardPointRepository {
  FakeRewardRepository() : super(dio: Dio());
  bool exchanged = false;

  @override
  Future<List<RewardVoucher>> rewards() async => const [
        RewardVoucher(
            id: 8,
            name: 'Quà 50 điểm',
            code: 'REWARD50',
            description: '',
            type: 'FIXED_AMOUNT',
            discountValue: 50000,
            pointsRequired: 50)
      ];

  @override
  Future<PointHistoryPage> history({int page = 1, int size = 20}) async =>
      PointHistoryPage(entries: const [], page: page, totalPages: 0);

  @override
  Future<void> exchange(int voucherId) async {
    expect(voucherId, 8);
    exchanged = true;
  }
}

class FakeRewardAuthNotifier extends AuthNotifier {
  final FakeRewardRepository rewards;
  FakeRewardAuthNotifier(this.rewards) : super(AuthRepository()) {
    state = AuthState(
        user: UserModel(id: 3, username: 'johncena', email: '', points: 100));
  }

  @override
  Future<void> checkAuthStatus() async {}

  @override
  Future<void> refreshProfile() async {
    state = state.copyWith(
        user: state.user!.copyWith(points: rewards.exchanged ? 50 : 100));
  }
}

void main() {
  test('loads paged point history and all redeemable vouchers', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests.add(options);
        dynamic data;
        if (options.path == 'users/profile/point-history') {
          data = {
            'page': 2,
            'totalPages': 3,
            'data': [
              {
                'id': 4,
                'pointsChanged': -50,
                'reason': 'SPEND_ON_VOUCHER',
                'referenceId': 8,
                'createdAt': '2026-11-07T12:00:00'
              }
            ]
          };
        } else {
          final page = options.queryParameters['page'];
          data = {
            'page': page,
            'totalPages': 2,
            'data': page == 1
                ? [
                    {
                      'id': 1,
                      'name': 'Voucher thường',
                      'code': 'FREE',
                      'type': 'FIXED_AMOUNT',
                      'discountValue': 10000,
                      'pointsRequired': null
                    }
                  ]
                : [
                    {
                      'id': 8,
                      'name': 'Quà 50 điểm',
                      'code': 'REWARD50',
                      'type': 'FIXED_AMOUNT',
                      'discountValue': 50000,
                      'pointsRequired': 50
                    }
                  ]
          };
        }
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'status': 200, 'data': data}));
      }));
    final repo = RewardPointRepository(dio: dio);
    expect((await repo.rewards()).single.code, 'REWARD50');
    final history = await repo.history(page: 2);
    expect(history.entries.single.pointsChanged, -50);
    expect(history.entries.single.description, 'Đổi voucher');
    expect(history.totalPages, 3);
    expect(requests.map((e) => e.path),
        ['vouchers', 'vouchers', 'users/profile/point-history']);
    expect(requests.last.queryParameters['page'], 2);
  });

  test('exchange calls its API and rejects malformed history', () async {
    final requests = <RequestOptions>[];
    var valid = true;
    final dio = Dio()
      ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: valid
                ? {'status': 200, 'data': null}
                : {
                    'status': 200,
                    'data': {'unexpected': true}
                  }));
      }));
    final repo = RewardPointRepository(dio: dio);
    await repo.exchange(8);
    expect(requests.single.method, 'POST');
    expect(requests.single.path, 'vouchers/8/exchange');
    valid = false;
    await expectLater(repo.history(), throwsA(isA<FormatException>()));
    expect(
        () => PointHistoryEntry.fromJson({
              'id': 1,
              'pointsChanged': '50',
              'reason': 'EARN_FROM_ORDER',
              'createdAt': '2026-11-07T12:00:00'
            }),
        throwsFormatException);
  });

  testWidgets('customer exchanges points and sees updated balance',
      (tester) async {
    final repo = FakeRewardRepository();
    final auth = FakeRewardAuthNotifier(repo);
    await tester.pumpWidget(ProviderScope(
        overrides: [authProvider.overrideWith((ref) => auth)],
        child: MaterialApp(home: RewardPointsScreen(repository: repo))));
    await tester.pumpAndSettle();
    expect(find.text('100 CrownPoints'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Đổi voucher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận đổi'));
    await tester.pumpAndSettle();
    expect(repo.exchanged, isTrue);
    expect(find.text('50 CrownPoints'), findsOneWidget);
    expect(find.textContaining('Đổi điểm thành công'), findsOneWidget);
  });
}
