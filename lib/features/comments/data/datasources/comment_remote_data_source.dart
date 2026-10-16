import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments(int parentId, String type);
  Future<Map<String, dynamic>> createComment(
      int parentId, String type, String body);
  Future<Map<String, dynamic>> updateComment(int commentId, String body);
  Future<Map<String, dynamic>> deleteComment(int commentId);
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final Dio client;

  CommentRemoteDataSourceImpl({required this.client});

  // TEMPORARY DEBUG: GET comments
  @override
  Future<List<CommentModel>> getComments(int parentId, String type) async {
    final url = _buildUrl(parentId, type);
    debugPrint('📡 [GET COMMENTS] $url');

    final response = await client.get(url);

    debugPrint('========== COMMENTS DEBUG ==========');
    debugPrint('Response type: ${response.data.runtimeType}');
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');
    debugPrint('====================================');

    final data = response.data;
    if (data is! List) {
      throw FormatException(
        'Expected a JSON list for comments, got ${data.runtimeType}: $data',
      );
    }

    return data.map((item) {
      if (item is! Map) {
        throw FormatException(
            'Expected a comment object, got ${item.runtimeType}');
      }
      return CommentModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> createComment(
    int parentId,
    String type,
    String body,
  ) async {
    final url = _buildUrl(parentId, type);
    debugPrint('📡 [POST COMMENT] $url');

    final response = await client.post(
      url,
      data: {
        'comment': {'body': body}
      },
    );

    debugPrint('========== CREATE COMMENT DEBUG ==========');
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response data: ${response.data}');
    debugPrint('==========================================');

    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> updateComment(int commentId, String body) async {
    final url = '/api/v1/comments/$commentId';
    debugPrint('📡 [PATCH COMMENT] $url');
    final response = await client.patch(
      url,
      data: {
        'comment': {'body': body}
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    final url = '/api/v1/comments/$commentId';
    debugPrint('📡 [DELETE COMMENT] $url');
    final response = await client.delete(url);
    return Map<String, dynamic>.from(response.data as Map);
  }

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
