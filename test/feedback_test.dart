import 'dart:async';
import 'dart:io';
import 'package:crowndine/data/mock/mock_data.dart';
import 'package:crowndine/data/repositories/feedback_repository.dart';
import 'package:crowndine/presentation/screens/customer/menu/menu_detail_sheet.dart';
import 'package:crowndine/presentation/widgets/write_feedback_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.setMockInitialValues({'mock_fallback_enabled': true});
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('Feedback & Reviews feature tests', () {
    test('FeedbackRepository gets and creates feedback', () async {
      final repo = FeedbackRepository();
      final feedbacks = await repo.getAllFeedbacks();
      expect(feedbacks.isNotEmpty, true);

      final newFb = await repo.createFeedback(
        rating: 5,
        comment: 'Món ăn tuyệt hảo, chất lượng 5 sao!',
        itemId: 101,
        authorName: 'Khách VIP',
      );

      expect(newFb.rating, 5);
      expect(newFb.comment, contains('tuyệt hảo'));
    });

    testWidgets('MenuDetailSheet renders feedback & reviews section', (tester) async {
      final item = MockData.items.first;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MenuDetailSheet(item: item),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check dish title
      expect(find.text(item.name), findsOneWidget);
      // Check Đánh giá & Bình luận section header
      expect(find.text('Đánh giá & Bình luận'), findsOneWidget);
      // Check Viết đánh giá button
      expect(find.text('Viết đánh giá'), findsOneWidget);
    });

    testWidgets('WriteFeedbackSheet renders 5 stars and input fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WriteFeedbackSheet(
                itemId: 101,
                itemName: 'Bò Wagyu A5 Áp Chảo',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Đánh giá món ăn'), findsOneWidget);
      expect(find.text('Bò Wagyu A5 Áp Chảo'), findsOneWidget);
      expect(find.text('Tuyệt hảo! Đỉnh cao ẩm thực'), findsOneWidget);
      expect(find.text('Gửi đánh giá'), findsOneWidget);
    });
  });
}
