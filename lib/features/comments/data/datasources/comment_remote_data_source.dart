import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments(int parentId, String type);

  /// 🔥 теперь возвращает Map
  Future<Map<String, dynamic>> createComment(
      int parentId,
      String type,
      String body,
  );

  Future<Map<String, dynamic>> updateComment(
      int commentId,
      String body,
  );

  /// 🔥 больше НЕ void
  Future<Map<String, dynamic>> deleteComment(int commentId);
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final Dio client;

  CommentRemoteDataSourceImpl({required this.client});

  /// ==============================
  /// GET
  /// ==============================
  @override
  Future<List<CommentModel>> getComments(int parentId, String type) async {
    final url = _buildUrl(parentId, type);
    debugPrint("📡 [GET] $url");

    final response = await client.get(url);

    return (response.data as List)
        .map((j) => CommentModel.fromJson(j))
        .toList();
  }

  /// ==============================
  /// CREATE
  /// ==============================
  @override
  Future<Map<String, dynamic>> createComment(
      int parentId,
      String type,
      String body,
  ) async {
    final url = _buildUrl(parentId, type);
    debugPrint("📡 [POST] $url");

    final response = await client.post(
      url,
      data: {'comment': {'body': body}},
    );

    return Map<String, dynamic>.from(response.data);
  }

  /// ==============================
  /// UPDATE
  /// ==============================
  @override
  Future<Map<String, dynamic>> updateComment(
      int commentId,
      String body,
  ) async {
    final url = '/api/v1/comments/$commentId';
    debugPrint("📡 [PATCH] $url");

    final response = await client.patch(
      url,
      data: {'comment': {'body': body}},
    );

    return Map<String, dynamic>.from(response.data);
  }

  /// ==============================
  /// DELETE
  /// ==============================
  @override
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    final url = '/api/v1/comments/$commentId';
    debugPrint("📡 [DELETE] $url");

    final response = await client.delete(url);

    return Map<String, dynamic>.from(response.data);
  }

  /// ==============================
  /// URL BUILDER
  /// ==============================
  String _buildUrl(int id, String type) {
    final normalized = type.toLowerCase().trim();

    if (normalized == 'people' || normalized == 'article') {
      return '/api/v1/articles/$id/comments';
    }

    if (normalized == 'animals' || normalized == 'sense') {
      return '/api/v1/senses/$id/comments';
    }

    if (normalized == 'things' || normalized == 'thing') {
      return '/api/v1/things/$id/comments';
    }

    return '/api/v1/articles/$id/comments';
  }
}