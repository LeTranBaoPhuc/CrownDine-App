class FeedbackModel {
  final int id;
  final int rating;
  final String comment;
  final String fullName;
  final String? avatarUrl;
  final String createdAt;
  final int? itemId;

  FeedbackModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.fullName,
    this.avatarUrl,
    required this.createdAt,
    this.itemId,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      rating: json['rating'] is int ? json['rating'] : int.tryParse('${json['rating']}') ?? 5,
      comment: json['comment'] ?? '',
      fullName: json['fullName'] ?? json['guestName'] ?? 'Thực khách CrownDine',
      avatarUrl: json['avatarUrl'],
      createdAt: json['createdAt'] ?? 'Vừa xong',
      itemId: json['itemId'] != null ? int.tryParse('${json['itemId']}') : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rating': rating,
        'comment': comment,
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt,
        'itemId': itemId,
      };
}
