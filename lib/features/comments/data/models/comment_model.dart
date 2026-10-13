class CommentModel {
  final int id;
  final String body;
  final String username;
  final String? avatarUrl;
  final String createdAt;
  final bool canEdit;
  final bool canDelete;

  CommentModel({
    required this.id, 
    required this.body, 
    required this.username,
    this.avatarUrl, 
    required this.createdAt, 
    required this.canEdit, 
    required this.canDelete,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Безопасно достаем данные пользователя (Risk Control)
    final userData = json['user'] as Map<String, dynamic>?;

    return CommentModel(
      id: json['id'],
      body: json['body'] ?? '',
      username: userData?['username'] ?? 'User #${json['user_id']}', 
      avatarUrl: userData?['avatar_url'],
      createdAt: json['created_at_formatted'] ?? json['created_at'] ?? '',
      canEdit: json['permissions']?['can_edit'] ?? false,
      canDelete: json['permissions']?['can_delete'] ?? false,
    );
  }
} 