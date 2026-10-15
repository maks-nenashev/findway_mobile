import 'package:flutter/foundation.dart';

class CommentModel {
  final int id;
  final String body;
  final String username;
  final String? avatarUrl;
  final String createdAt;
  final bool canEdit;
  final bool canDelete;

  const CommentModel({
    required this.id,
    required this.body,
    required this.username,
    this.avatarUrl,
    required this.createdAt,
    required this.canEdit,
    required this.canDelete,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final userData = _asMap(json['user']) ?? _asMap(json['author']);
    final permissions = _asMap(json['permissions']);

    final rawUsername = userData?['username'];
    final rawAvatar = userData?['avatar_url'] ?? userData?['avatarUrl'];

    // TEMPORARY DEBUG: inspect author fields returned by the API.
    debugPrint('========== COMMENT MODEL DEBUG ==========');
    debugPrint('Comment id: ${json['id']}');
    debugPrint('Comment user_id: ${json['user_id']}');
    debugPrint('COMMENT USER: ${json['user']}');
    debugPrint('COMMENT AUTHOR: ${json['author']}');
    debugPrint('Resolved username: $rawUsername');
    debugPrint('Resolved avatar URL: $rawAvatar');
    debugPrint('=========================================');

    final username = rawUsername?.toString().trim();
    final avatar = rawAvatar?.toString().trim();

    return CommentModel(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      body: json['body']?.toString() ?? '',
      username: username != null && username.isNotEmpty
          ? username
          : 'User #${json['user_id'] ?? '?'}',
      avatarUrl: avatar != null && avatar.isNotEmpty ? avatar : null,
      createdAt: (json['created_at_formatted'] ??
              json['created_at'] ??
              json['createdAt'] ??
              '')
          .toString(),
      canEdit:
          permissions?['can_edit'] == true || permissions?['canEdit'] == true,
      canDelete: permissions?['can_delete'] == true ||
          permissions?['canDelete'] == true,
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
