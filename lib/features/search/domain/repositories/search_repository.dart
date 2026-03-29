import '../../data/models/filter_model.dart';

abstract class SearchRepository {
  // Исправляем на именованные параметры для консистентности
  Future<List<FilterModel>> getFilters({
    required String category,
    required String locale,
  });

  // Добавляем метод поиска в контракт
  Future<List<dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  });
}