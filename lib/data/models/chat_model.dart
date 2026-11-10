class ChatMessageModel {
  final int id;
  final String role;
  final String content;
  final String? model;
  final DateTime? createdAt;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.model,
    this.createdAt,
  });

  bool get isUser => role.toLowerCase() == 'user';
  bool get isError => role.toLowerCase() == 'error';
  bool get isAssistant =>
      role.toLowerCase() == 'assistant' || role.toLowerCase() == 'model';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id']}') ?? 0,
      role: json['role']?.toString() ?? 'user',
      content: json['content']?.toString() ?? '',
      model: json['model']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'model': model,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class ChatConversationModel {
  final int id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ChatMessageModel> messages;

  ChatConversationModel({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory ChatConversationModel.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List?;
    final parsedMessages = rawMessages != null
        ? rawMessages
              .map(
                (m) => ChatMessageModel.fromJson(Map<String, dynamic>.from(m)),
              )
              .toList()
        : <ChatMessageModel>[];

    return ChatConversationModel(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? 'Cuộc trò chuyện',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      messages: parsedMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  ChatConversationModel copyWith({
    int? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessageModel>? messages,
  }) {
    return ChatConversationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
