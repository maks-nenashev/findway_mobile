import '../../data/datasources/comment_remote_data_source.dart';
import '../../data/models/comment_model.dart';

class CommentRepository {
  final CommentRemoteDataSource remoteDataSource;
  CommentRepository({required this.remoteDataSource});

  Future<List<CommentModel>> getComments(int id, String type) => remoteDataSource.getComments(id, type);
  Future<CommentModel> addComment(int id, String type, String body) => remoteDataSource.createComment(id, type, body);
  Future<void> deleteComment(int id) => remoteDataSource.deleteComment(id);
}