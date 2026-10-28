import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crowndine/core/theme/app_theme.dart';
import 'package:crowndine/presentation/screens/admin/admin_main_screen.dart';
import 'package:crowndine/presentation/screens/customer/customer_main_screen.dart';
import 'package:crowndine/presentation/screens/customer/profile/profile_screen.dart';
import 'package:crowndine/presentation/screens/staff/floor_plan/floor_plan_screen.dart';
import 'package:crowndine/presentation/screens/staff/staff_main_screen.dart';
import 'package:crowndine/presentation/widgets/crown_app_bar.dart';

const List<int> _kTransparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => Future.value(_FakeHttpClientRequest());
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => Future.value(_FakeHttpClientRequest());
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  Future<HttpClientResponse> close() => Future.value(_FakeHttpClientResponse());
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {}

class _FakeHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_kTransparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  testWidgets('CrownAppBar build smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            appBar: CrownAppBar(
              title: 'CrownDine Quản Trị',
              showRoleSwitcher: true,
            ),
            body: Center(child: Text('Admin View')),
          ),
        ),
      ),
    );

    expect(find.text('CrownDine Quản Trị'), findsOneWidget);
    expect(find.text('Admin View'), findsOneWidget);
  });

  testWidgets('ProfileScreen theme test (Light & Dark)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const ProfileScreen(),
        ),
      ),
    );

    expect(find.text('Tài khoản CrownDine'), findsOneWidget);
    expect(find.text('ĐIỂM TÍCH LŨY THÀNH VIÊN'), findsOneWidget);
    expect(find.text('Lịch sử đặt bàn'), findsOneWidget);
    expect(find.text('Quản trị viên (Admin Portal)'), findsOneWidget);
  });

  testWidgets('Staff FloorPlanScreen build smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: FloorPlanScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tầng 1 (Đại sảnh)'), findsOneWidget);
    expect(find.text('Tầng 2 (Phòng VIP)'), findsOneWidget);
    expect(find.text('Tất cả bàn'), findsOneWidget);
  });

  testWidgets('CustomerMainScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CustomerMainScreen(),
        ),
      ),
    );

    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Thực đơn'), findsOneWidget);
    expect(find.text('Đặt bàn'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });

  testWidgets('StaffMainScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StaffMainScreen(),
        ),
      ),
    );

    expect(find.text('Sơ đồ bàn'), findsOneWidget);
    expect(find.text('Đơn gọi món'), findsOneWidget);
    expect(find.text('Bếp KDS'), findsOneWidget);
  });

  testWidgets('AdminMainScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AdminMainScreen(),
        ),
      ),
    );

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Món ăn'), findsOneWidget);
    expect(find.text('Voucher'), findsOneWidget);
    expect(find.text('Nhân sự'), findsOneWidget);
  });
}
