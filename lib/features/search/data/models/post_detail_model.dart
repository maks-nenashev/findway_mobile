import 'package:equatable/equatable.dart';

class PostDetailModel extends Equatable {
  final int id;
  final String title;
  final String text;
  final String createdAt;
  final String local;
  final List<String> images;
  final AuthorModel author;
  final List<CommentModel> comments;

  const PostDetailModel({
    required this.id,
    required this.title,
    required this.text,
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
      createdAt: json['created_at'] ?? '',
      local: json['local'] ?? '',
      // Безопасное приведение списка строк
      images: List<String>.from(json['images'] ?? []),
      // Вложенная модель автора
      author: AuthorModel.fromJson(json['author'] ?? {}),
      // Маппинг списка комментариев
      comments: (json['comments'] as List? ?? [])
          .map((c) => CommentModel.fromJson(c))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, title, text, images, author, comments];
}

class AuthorModel extends Equatable {
  final String username;
  final String? avatarUrl;

  const AuthorModel({required this.username, this.avatarUrl});

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      username: json['username'] ?? 'Unknown',
      avatarUrl: json['avatar_url'],
    );
  }

  @override
  List<Object?> get props => [username, avatarUrl];
}

class CommentModel extends Equatable {
  final int id;
  final String username;
  final String? avatar;
  final String body;
  final String date;

  const CommentModel({
    required this.id,
    required this.username,
    this.avatar,
    required this.body,
    required this.date,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      username: json['username'] ?? 'Anonymous',
      avatar: json['avatar'],
      body: json['body'] ?? '',
      date: json['date'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, username, body, date];
}