import '../../data/models/filter_model.dart';

abstract class SearchRepository {
  Future<Map<String, dynamic>> getFiltersData({
    required String category, 
    required String locale,
  });
  
  Future<List<dynamic>> search({
    required String category, 
    required Map<String, dynamic> filters, 
    required String locale,
  });
  
  Future<Map<String, dynamic>> getPostDetails({
    required int id, 
    required String category, 
    required String locale,
  });

  // =================================================================
  // ✅ ВОССТАНОВЛЕННЫЙ МЕТОД (Чтобы не падал BLoC при создании)
  // =================================================================
  Future<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    required String locale,
    required List<String> imagePaths,
  });

  // =================================================================
  // ✅ НОВЫЙ МЕТОД (Для обновления)
  // =================================================================
  Future<void> updatePost({
    required int postId,
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    required String locale,
    required List<String> existingImages,
    required List<String> newImagePaths,
  });

  // Метод для удаления поста
  Future<void> deletePost(int postId, String category); 
}