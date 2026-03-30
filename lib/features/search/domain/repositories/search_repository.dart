// Убираем несуществующий импорт filter_entity.dart
import '../../data/models/filter_model.dart';

abstract class SearchRepository {
  // Контракт на получение фильтров и переводов из YAML
  Future<Map<String, dynamic>> getFiltersData({
    required String category,
    required String locale,
  });

  // Контракт на поиск
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
}