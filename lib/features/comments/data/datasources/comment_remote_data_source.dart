import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments(int parentId, String type);
  Future<CommentModel> createComment(int parentId, String type, String body);
  Future<void> deleteComment(int commentId);
  // ✅ ДОБАВЛЕНО: Интерфейс для обновления
  Future<Map<String, dynamic>> updateComment(int commentId, String body);
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final Dio client;
  CommentRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CommentModel>> getComments(int parentId, String type) async {
    final url = _buildUrl(parentId, type);
    debugPrint("📡 [GET] Requesting comments: $url");
    final response = await client.get(url);
    
    if (response.data is List) {
      return (response.data as List).map((j) => CommentModel.fromJson(j)).toList();
    }
    return [];
  }

  @override
  Future<CommentModel> createComment(int parentId, String type, String body) async {
    final url = _buildUrl(parentId, type);
    debugPrint("📡 [POST] Creating comment: $url");
    final response = await client.post(url, data: {'comment': {'body': body}});
    return CommentModel.fromJson(response.data);
  }

  // ✅ ИСПРАВЛЕНО: Обновление комментария (PATCH)
  @override
  Future<Map<String, dynamic>> updateComment(int commentId, String body) async {
    final url = '/api/v1/comments/$commentId';
    debugPrint("📡 [PATCH] Updating comment: $url");
    final response = await client.patch(
      url,
      data: {'comment': {'body': body}},
    );
    return response.data; // Возвращаем Map для обработки статуса модерации
  }

  @override
  Future<void> deleteComment(int commentId) async {
    final url = '/api/v1/comments/$commentId';
    debugPrint("📡 [DELETE] Removing comment: $url");
    await client.delete(url);
  }

  String _buildUrl(int id, String type) {
    final normalizedType = type.toLowerCase().trim();
    if (normalizedType == 'people' || normalizedType == 'article') return '/api/v1/articles/$id/comments';
    if (normalizedType == 'animals' || normalizedType == 'sense') return '/api/v1/senses/$id/comments';
    if (normalizedType == 'things' || normalizedType == 'thing') return '/api/v1/things/$id/comments';
    return '/api/v1/articles/$id/comments';
  }
}