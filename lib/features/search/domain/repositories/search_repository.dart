// =============================================================================
// FILE: lib/features/search/domain/repositories/search_repository.dart
// LAYER: Domain Layer (Contract / Interface)
// RESPONSIBILITY: Чистый контракт интерфейса репозитория поиска и CUD-операций.
// =============================================================================

abstract class SearchRepository {
  /// Получение метаданных фильтров и переводов для заданной категории
  Future<Map<String, dynamic>> getFiltersData({
    required String category, 
    required String locale,
  });
  
  /// Выполнение поиска с фильтрацией
  Future<List<dynamic>> search({
    required String category, 
    required Map<String, dynamic> filters, 
    required String locale,
  });
  
  /// Загрузка детальной карточки объявления
  Future<Map<String, dynamic>> getPostDetails({
    required int id, 
    required String category, 
    required String locale,
  });

  // =========================================================================
  // СОЗДАНИЕ ПОСТА
  // =========================================================================
  Future<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    double? latitude,
    double? longitude,
    String? address,
    Map<String, dynamic>? animalMetadata,
    required String locale,
    required List<String> imagePaths,
  });

  // =========================================================================
  // ОБНОВЛЕНИЕ ПОСТА
  // =========================================================================
  Future<void> updatePost({
    required int postId,
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    double? latitude,
    double? longitude,
    String? address,
    Map<String, dynamic>? animalMetadata,
    required String locale,
    required List<String> existingImages,
    required List<String> newImagePaths,
  });

  // =========================================================================
  // УДАЛЕНИЕ ПОСТА
  // =========================================================================
  Future<void> deletePost(int postId, String category); 
}