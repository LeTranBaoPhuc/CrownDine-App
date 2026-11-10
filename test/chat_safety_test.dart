import 'dart:async';
import 'package:crowndine/data/models/chat_model.dart';
import 'package:crowndine/data/models/chat_reservation_intent.dart';
import 'package:crowndine/data/repositories/chat_repository.dart';
import 'package:crowndine/providers/chat_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crowndine/data/models/table_model.dart';
import 'package:crowndine/data/repositories/table_repository.dart';
import 'package:crowndine/providers/table_provider.dart';
import 'package:crowndine/presentation/screens/customer/chat/chat_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'api_session_test.dart' show Adapter, body;

void main() {
  final now = DateTime(2030, 1, 1);
  const link =
      '/reservation?step=4&tableName=Bàn 01&date=2030-01-02&startTime=19:00&guests=4';
  testWidgets(
      'booking action requires a tap and never substitutes a different available table',
      (tester) async {
    final tables = _OtherTableRepository();
    await tester.pumpWidget(ProviderScope(overrides: [
      chatProvider.overrideWith((ref) => _StaticChatNotifier(link)),
      tableRepositoryProvider.overrideWithValue(tables),
    ], child: const MaterialApp(home: CustomerChatScreen())));
    await tester.pumpAndSettle();
    expect(tables.requests, 0);
    await tester.ensureVisible(find.text('Chuyển đến thanh toán đặt cọc'));
    await tester.tap(find.text('Chuyển đến thanh toán đặt cọc'));
    await tester.pumpAndSettle();
    expect(tables.requests, 1);
    expect(find.textContaining('Bàn không còn trống'), findsOneWidget);
    expect(find.byType(CustomerChatScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('booking links preserve spaces, unicode and encoded table names', () {
    for (final value in [link, link.replaceFirst('Bàn 01', 'B%C3%A0n%2001')]) {
      final intent =
          ChatReservationIntent.tryParse('Continue\n$value', now: now)!;
      expect(intent.tableName, 'Bàn 01');
      expect(intent.dateStr, '2030-01-02');
      expect(intent.startTime, '19:00');
      expect(intent.guests, 4);
      expect(intent.step, 4);
    }
    expect(ChatReservationIntent.normalTableName('Bàn T1-01'), 't1-01');
    expect(ChatReservationIntent.normalTableName('T1-01'), isNot('t1-010'));
  });
  test('missing, ambiguous, invalid and past booking values never get defaults',
      () {
    for (final value in [
      link.replaceFirst('&guests=4', ''),
      link.replaceFirst('guests=4', 'guests=0'),
      link.replaceFirst('guests=4', 'guests=4abc'),
      '$link&guests=8',
      link.replaceFirst('step=4', 'step=7'),
      link.replaceFirst('Bàn 01', ''),
      link.replaceFirst('2030-01-02', '2030-02-30'),
      link.replaceFirst('2030-01-02', '2029-01-02'),
      link.replaceFirst('19:00', '22:00'),
      link.replaceFirst('19:00', '09:00'),
    ]) {
      expect(ChatReservationIntent.tryParse(value, now: now), isNull,
          reason: value);
    }
  });
  test('guest token is carried only for its conversation and removed on delete',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api/'));
    var created = false, deleted = false;
    dio.httpClientAdapter = Adapter((request) async {
      if (request.method == 'POST' && request.path.endsWith('/conversations')) {
        created = true;
        expect(request.headers['X-Chat-Token'], isNull);
        return body(200, {
          'data': {
            'id': 1,
            'title': 'Guest',
            'messages': [],
            'guestAccessToken': 'private-token'
          }
        });
      }
      if (request.path.endsWith('/2')) {
        expect(request.headers['X-Chat-Token'], isNull);
      } else {
        expect(created, isTrue);
        expect(request.headers['X-Chat-Token'],
            deleted ? isNull : 'private-token');
      }
      if (request.method == 'DELETE') deleted = true;
      return body(200, {
        'data': {
          'id': 1,
          'role': 'user',
          'content': 'Hello',
          'title': 'Guest',
          'messages': []
        }
      });
    });
    final repo = ChatRepository(dio: dio);
    await repo.createConversation();
    await repo.getConversation(1);
    await repo.getConversation(2);
    await repo.sendMessage(conversationId: 1, content: 'Hello');
    await repo.deleteConversation(1);
    await repo.getConversation(1);
  });
  test('polling reports timeout and recognizes a persisted AI error', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api/'));
    bool failed = false;
    dio.httpClientAdapter = Adapter((_) async => body(200, {
          'data': {
            'id': 1,
            'title': 'Chat',
            'messages': [
              {'id': 1, 'role': 'user', 'content': 'Hello'},
              if (failed) {'id': 2, 'role': 'error', 'content': 'Please retry'},
            ],
          }
        }));
    final repo = ChatRepository(dio: dio);
    await expectLater(
        repo.waitForAssistantReply(
            conversationId: 1,
            initialMessageCount: 1,
            pollInterval: Duration.zero,
            maxAttempts: 1),
        throwsA(isA<TimeoutException>()));
    failed = true;
    final response = await repo.waitForAssistantReply(
        conversationId: 1,
        initialMessageCount: 1,
        pollInterval: Duration.zero,
        maxAttempts: 1);
    expect(response!.messages.last.isError, isTrue);
  });
  test(
      'double send is blocked and a late response cannot replace a selected chat',
      () async {
    final repo = _PendingChatRepository();
    final notifier = ChatNotifier(repo);
    addTearDown(notifier.dispose);
    await Future<void>.delayed(Duration.zero);
    final first = notifier.sendMessage('Hello');
    await notifier.sendMessage('Duplicate');
    await Future<void>.delayed(Duration.zero);
    expect(repo.sends, 1);
    expect(notifier.state.isTyping, isTrue);
    await notifier.selectConversation(2);
    repo.reply.complete(ChatConversationModel(id: 1, title: 'Old'));
    await first;
    expect(notifier.state.activeConversation!.id, 2);
    expect(notifier.state.isTyping, isFalse);
  });
}

class _OtherTableRepository extends TableRepository {
  _OtherTableRepository() : super(dio: Dio());
  int requests = 0;
  @override
  Future<List<TableModel>> getAvailableTables(
      {required String date,
      required String startTime,
      required int guestNumber}) async {
    requests++;
    return [
      TableModel(
          id: 2,
          name: 'Bàn 02',
          capacity: 4,
          deposit: 100000,
          status: TableStatus.available)
    ];
  }
}

class _StaticChatNotifier extends ChatNotifier {
  _StaticChatNotifier(String link) : super(_PendingChatRepository()) {
    state = ChatState(
        activeConversation:
            ChatConversationModel(id: 1, title: 'Chat', messages: [
      ChatMessageModel(id: 1, role: 'assistant', content: 'Tiếp tục\n$link'),
    ]));
  }
  @override
  Future<void> loadConversations() async {}
}

class _PendingChatRepository extends ChatRepository {
  _PendingChatRepository() : super(dio: Dio());
  int sends = 0;
  final reply = Completer<ChatConversationModel?>();
  @override
  Future<List<ChatConversationModel>> getConversations() async => [];
  @override
  Future<ChatConversationModel> createConversation(
          {String title = 'Chat'}) async =>
      ChatConversationModel(id: 1, title: title);
  @override
  Future<ChatConversationModel?> getConversation(int id) async =>
      ChatConversationModel(id: id, title: 'Selected');
  @override
  Future<ChatMessageModel> sendMessage(
      {required int conversationId, required String content}) async {
    sends++;
    return ChatMessageModel(id: 1, role: 'user', content: content);
  }

  @override
  Future<ChatConversationModel?> waitForAssistantReply(
          {required int conversationId,
          required int initialMessageCount,
          Duration pollInterval = const Duration(milliseconds: 1500),
          int maxAttempts = 25}) =>
      reply.future;
}
