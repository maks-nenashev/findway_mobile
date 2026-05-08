import 'package:equatable/equatable.dart';

class PostDetailModel extends Equatable {
  final int id;
  final String title;
  final String text;
  final String? category; // ✅ Поле для динамического роутинга
  final String createdAt;
  final String local;
  final List<String> images;
  final AuthorModel author;
  final List<CommentModel> comments;

  const PostDetailModel({
    required this.id,
    required this.title,
    required this.text,
    this.category, // ✅ Добавлено в конструктор
    required this.createdAt,
    required this.local,
    required this.images,
    required this.author,
    required this.comments,
  });

  factory PostDetailModel.fromJson(Map<String, dynamic> json) {
    return PostDetailModel(
      id: json['id'] as int,
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      // ✅ Маппинг категории (Rails может присылать разные ключи)
      category: json['category'] ?? json['type'] ?? json['commentable_type'],
      createdAt: json['created_at_formatted'] ?? json['created_at'] ?? '',
      local: json['local'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      author: AuthorModel.fromJson(json['author'] ?? {}),
      comments: (json['comments'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, title, text, category, images, author, comments];
}

class AuthorModel extends Equatable {
  final String username;
  final String? avatarUrl;

  const AuthorModel({required this.username, this.avatarUrl});

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'], // В Rails обычно avatar_url
    );
  }

  @override
  List<Object?> get props => [username, avatarUrl];
}

class CommentModel extends Equatable {
  final int id;
  final String username;
  final String? avatarUrl;
  final String body;
  final String createdAt;
  final bool canDelete; // Для отображения иконки удаления

  const CommentModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.body,
    required this.createdAt,
    this.canDelete = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Безопасный доступ к вложенному объекту юзера
    final userData = json['user'] as Map<String, dynamic>?;

    return CommentModel(
      id: json['id'] as int,
      username: userData?['username'] ?? 'User #${json['user_id']}',
      avatarUrl: userData?['avatar_url'],
      body: json['body'] ?? '',
      createdAt: json['created_at_formatted'] ?? json['created_at'] ?? '',
      // Проверка прав из JSON (Rails Pundit/Permissions)
      canDelete: json['permissions']?['can_delete'] ?? false,
    );
  }

  @override
  List<Object?> get props => [id, username, body, createdAt, canDelete];
}