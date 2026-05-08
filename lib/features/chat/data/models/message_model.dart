class MessageModel {
  final int id;
  final String body;
  final int senderId;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.body,
    required this.senderId,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      senderId: json['sender_id'] as int,
      // Rails отдает ISO 8601, Flutter отлично его парсит
      createdAt: DateTime.parse(json['created_at'].toString()).toLocal(),
      isRead: json['read'] == true,
    );
  }

  // На всякий случай для локального кэширования в будущем
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'sender_id': senderId,
      'created_at': createdAt.toIso8601String(),
      'read': isRead,
    };
  }
}