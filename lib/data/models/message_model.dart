class MessageModel {
  final String id;
  final String conversationId;
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      content: json['content'] ?? json['message'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'content': content,
    'role': role,
    'createdAt': createdAt.toIso8601String(),
  };
}