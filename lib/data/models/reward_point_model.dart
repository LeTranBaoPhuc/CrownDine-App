class PointHistoryEntry {
  final int id;
  final int pointsChanged;
  final String reason;
  final int? referenceId;
  final DateTime createdAt;

  const PointHistoryEntry({
    required this.id,
    required this.pointsChanged,
    required this.reason,
    required this.referenceId,
    required this.createdAt,
  });

  factory PointHistoryEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final points = json['pointsChanged'];
    final reason = json['reason'];
    final referenceId = json['referenceId'];
    final createdAt = DateTime.tryParse('${json['createdAt'] ?? ''}');
    if (id is! int ||
        points is! int ||
        reason is! String ||
        createdAt == null ||
        (referenceId != null && referenceId is! int)) {
      throw const FormatException('Lịch sử điểm không hợp lệ.');
    }
    return PointHistoryEntry(
      id: id,
      pointsChanged: points,
      reason: reason,
      referenceId: referenceId as int?,
      createdAt: createdAt,
    );
  }

  String get description => switch (reason) {
        'EARN_FROM_ORDER' => 'Tích điểm từ đơn hàng',
        'SPEND_ON_VOUCHER' => 'Đổi voucher',
        'ADMIN_ADJUSTMENT' => 'Điều chỉnh điểm',
        _ => 'Biến động điểm',
      };
}

class PointHistoryPage {
  final List<PointHistoryEntry> entries;
  final int page;
  final int totalPages;

  const PointHistoryPage({
    required this.entries,
    required this.page,
    required this.totalPages,
  });
}

class RewardVoucher {
  final int id;
  final String name;
  final String code;
  final String description;
  final String type;
  final double discountValue;
  final int pointsRequired;

  const RewardVoucher({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.type,
    required this.discountValue,
    required this.pointsRequired,
  });

  factory RewardVoucher.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final code = json['code'];
    final type = json['type'];
    final value = json['discountValue'];
    final points = json['pointsRequired'];
    if (id is! int ||
        id <= 0 ||
        name is! String ||
        code is! String ||
        type is! String ||
        value is! num ||
        points is! int ||
        points <= 0) {
      throw const FormatException('Voucher điểm thưởng không hợp lệ.');
    }
    return RewardVoucher(
      id: id,
      name: name,
      code: code,
      description: json['description'] as String? ?? '',
      type: type,
      discountValue: value.toDouble(),
      pointsRequired: points,
    );
  }
}
