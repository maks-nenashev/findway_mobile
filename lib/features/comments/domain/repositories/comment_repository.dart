import '../../data/datasources/comment_remote_data_source.dart';
import '../../data/models/comment_model.dart';

class CommentRepository {
  final CommentRemoteDataSource remoteDataSource;

  CommentRepository({
    required this.remoteDataSource,
  });

  /// ==============================
  /// GET
  /// ==============================
  Future<List<CommentModel>> getComments(int parentId, String type) {
    return remoteDataSource.getComments(parentId, type);
  }

  /// ==============================
  /// CREATE
  /// ==============================
  Future<Map<String, dynamic>> addComment(
      int parentId,
      String type,
      String body,
      ) {
    return remoteDataSource.createComment(parentId, type, body);
  }

  /// ==============================
  /// DELETE
  /// ==============================
  Future<Map<String, dynamic>> deleteComment(int id) {
    return remoteDataSource.deleteComment(id);
  }

  /// ==============================
  /// UPDATE
  /// ==============================
  Future<Map<String, dynamic>> updateComment(
      int id,
      String body,
      ) {
    return remoteDataSource.updateComment(id, body);
  }
}