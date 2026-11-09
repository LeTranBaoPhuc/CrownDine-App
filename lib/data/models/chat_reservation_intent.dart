class ChatReservationIntent {
  final int step;
  final String tableName;
  final String dateStr;
  final String startTime;
  final int guests;

  const ChatReservationIntent({
    required this.step,
    required this.tableName,
    required this.dateStr,
    required this.startTime,
    required this.guests,
  });

  static final _link = RegExp(r'/reservation\?[^\r\n]+');

  static ChatReservationIntent? tryParse(String content, {DateTime? now}) {
    final match = _link.firstMatch(content);
    if (match == null) return null;
    try {
      final raw = match
          .group(0)!
          .trim()
          .replaceFirst(RegExp('["\'<>).,]+\$'), '');
      final uri = Uri.parse(raw);
      if (uri.queryParametersAll.values.any((values) => values.length != 1))
        return null;
      final p = uri.queryParameters;
      final step = int.tryParse(p['step'] ?? '');
      final name = p['tableName']?.trim() ?? '';
      final date = p['date'] ?? '';
      final time = p['startTime'] ?? '';
      final guestText = p['guests'] ?? '';
      if ((step != 3 && step != 4) ||
          name.isEmpty ||
          name.length > 100 ||
          !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
          !RegExp(r'^(1\d|2[01]):[0-5]\d$').hasMatch(time) ||
          !RegExp(r'^[1-9]\d{0,2}$').hasMatch(guestText))
        return null;
      final day = DateTime.parse(date);
      if (day.toIso8601String().substring(0, 10) != date) return null;
      final parts = time.split(':');
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      if (!start.isAfter(now ?? DateTime.now())) return null;
      return ChatReservationIntent(
        step: step!,
        tableName: name,
        dateStr: date,
        startTime: time,
        guests: int.parse(guestText),
      );
    } catch (_) {
      return null;
    }
  }

  static String cleanContent(String content) =>
      content.replaceAll(_link, '').trim();
  static String normalTableName(String name) =>
      name.trim().toLowerCase().replaceFirst(RegExp(r'^b[aà]n\s+'), '');

  @override
  bool operator ==(Object other) =>
      other is ChatReservationIntent &&
      step == other.step &&
      tableName == other.tableName &&
      dateStr == other.dateStr &&
      startTime == other.startTime &&
      guests == other.guests;
  @override
  int get hashCode => Object.hash(step, tableName, dateStr, startTime, guests);
}
