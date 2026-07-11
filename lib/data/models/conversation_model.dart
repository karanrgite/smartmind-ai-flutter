class ConversationModel {
  final String id;
  final String title;
  final String? lastMessage;
  final DateTime? updatedAt;
  final String? persona;

  ConversationModel({
    required this.id,
    required this.title,
    this.lastMessage,
    this.updatedAt,
    this.persona,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'New Chat',
      lastMessage: json['lastMessage']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      persona: json['persona']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'lastMessage': lastMessage,
    'updatedAt': updatedAt?.toIso8601String(),
    'persona': persona,
  };
}