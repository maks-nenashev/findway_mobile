import '../../data/datasources/comment_remote_data_source.dart';
import '../../data/models/comment_model.dart';

class CommentRepository {
  final CommentRemoteDataSource remoteDataSource;
  
  CommentRepository({required this.remoteDataSource});

  // Получение списка
  Future<List<CommentModel>> getComments(int id, String type) => 
    remoteDataSource.getComments(id, type);

  // Создание
  Future<CommentModel> addComment(int id, String type, String body) => 
    remoteDataSource.createComment(id, type, body);

  // Удаление (Оставили одну версию без дублей)
  Future<void> deleteComment(int id) async {
    await remoteDataSource.deleteComment(id);
  }

  // Обновление (Возвращаем Map для анализа статуса модерации в Блоке)
  Future<Map<String, dynamic>> updateComment(int id, String body) async {
    return await remoteDataSource.updateComment(id, body);
  }
}