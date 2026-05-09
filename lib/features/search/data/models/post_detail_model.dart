import 'package:equatable/equatable.dart';

class PostDetailModel extends Equatable {
  final int id;
  final String title;
  final String text;
  final String? category; // Поле для динамического роутинга
  final String createdAt;
  final String local;
  final List<String> images;
  final AuthorModel author;
  final List<CommentModel> comments;
  
  // 👉 НОВОЕ ПОЛЕ ДЛЯ ПРАВ ДОСТУПА (UI Policy)
  final PermissionsModel permissions; 

  const PostDetailModel({
    required this.id,
    required this.title,
    required this.text,
    this.category,
    required this.createdAt,
    required this.local,
    required this.images,
    required this.author,
    required this.comments,
    required this.permissions, // Добавлено в конструктор
  });

  factory PostDetailModel.fromJson(Map<String, dynamic> json) {
    return PostDetailModel(
      id: json['id'] as int,
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      category: json['category'] ?? json['type'] ?? json['commentable_type'],
      createdAt: json['created_at_formatted'] ?? json['created_at'] ?? '',
      local: json['local'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      author: AuthorModel.fromJson(json['author'] ?? {}),
      comments: (json['comments'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
      // 👉 БЕЗОПАСНЫЙ ПАРСИНГ ПРАВ (Если сервер ничего не прислал - права закрыты)
      permissions: PermissionsModel.fromJson(json['permissions'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        text,
        category,
        images,
        author,
        comments,
        permissions, // Добавлено в props для сравнения состояний BLoC
      ];
}

class AuthorModel extends Equatable {
  final int id; // 👈 ДОБАВИЛИ ID
  final String username;
  final String? avatarUrl;

  const AuthorModel({
    required this.id, 
    required this.username, 
    this.avatarUrl
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] as int? ?? 0, // 👈 ПАРСИМ ID
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
    );
  }

  @override
  List<Object?> get props => [id, username, avatarUrl];
}

class CommentModel extends Equatable {
  final int id;
  final String username;
  final String? avatarUrl;
  final String body;
  final String createdAt;
  final bool canDelete; //

  const CommentModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
    this.canDelete = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] as Map<String, dynamic>?;

    return CommentModel(
      id: json['id'] as int,
      username: userData?['username'] ?? 'User #${json['user_id']}',
      avatarUrl: userData?['avatar_url'],
      body: json['body'] ?? '',
      createdAt: json['created_at_formatted'] ?? json['created_at'] ?? '',
      canDelete: json['permissions']?['can_delete'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, username, body, createdAt, canDelete];
}

// =========================================================
// 👉 НОВАЯ МОДЕЛЬ ДЛЯ ПРАВ ДОСТУПА ПОСТА
// =========================================================
class PermissionsModel extends Equatable {
  final bool canEdit;
  final bool canDelete;

  const PermissionsModel({
    required this.canEdit,
    required this.canDelete,
  });

  factory PermissionsModel.fromJson(Map<String, dynamic> json) {
    return PermissionsModel(
      canEdit: json['can_edit'] ?? false,
      canDelete: json['can_delete'] ?? false,
    );
  }

  @override
  List<Object?> get props => [canEdit, canDelete];
}