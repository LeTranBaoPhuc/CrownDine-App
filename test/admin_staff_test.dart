import 'dart:async';
import 'dart:io';
import 'package:crowndine/data/mock/mock_data.dart';
import 'package:crowndine/presentation/screens/admin/staff/admin_staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('AdminStaffScreen Edit & Soft Delete Tests', () {
    test('UserModel supports soft delete and copyWith', () {
      final staff = MockData.staffList.first;
      expect(staff.isActive, true);

      final softDeleted = staff.copyWith(isActive: false);
      expect(softDeleted.isActive, false);
      expect(softDeleted.fullName, staff.fullName);

      final updated = staff.copyWith(phone: '0999888777', membershipTier: 'Đầu bếp chính');
      expect(updated.phone, '0999888777');
      expect(updated.membershipTier, 'Đầu bếp chính');
    });

    testWidgets('AdminStaffScreen renders Edit and Soft Delete actions and filter chips', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminStaffScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check header
      expect(find.text('Danh Sách Nhân Viên'), findsOneWidget);

      // Check filter chips & badges
      expect(find.textContaining('Tất cả'), findsWidgets);
      expect(find.textContaining('Đang làm việc'), findsWidgets);
      expect(find.textContaining('Đã xóa mềm'), findsWidgets);

      // Check Edit icon buttons exist
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);

      // Check Soft delete icon buttons exist
      expect(find.byIcon(Icons.person_off_outlined), findsWidgets);
    });
  });
}
