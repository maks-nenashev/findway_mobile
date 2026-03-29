import '../../data/models/filter_model.dart';

abstract class SearchRepository {
  // Используем именованные параметры для прозрачности
  Future<List<FilterModel>> getFilters({
    required String category,
    required String locale,
  });
}