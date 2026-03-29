import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';
import '../models/filter_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getFiltersData({
    required String category,
    required String locale,
  }) async {
    // 1. Получаем композитные данные из источника
    final Map<String, dynamic> data = await remoteDataSource.getFiltersData(
      category: category, 
      locale: locale,
    );

    // 2. Возвращаем Map, который ожидает Блок
    // (Маппинг JSON -> FilterModel уже произошел в DataSource для чистоты)
    return {
      'filters': data['filters'] as List<FilterModel>,
      'translations': data['translations'] as Map<String, dynamic>,
    };
  }

  @override
  Future<List<dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  }) async {
    // Проброс вызова в DataSource. 
    // Напоминаю: DataSource сам обернет фильтры в q[...] для Ransack.
    return await remoteDataSource.search(
      category: category,
      filters: filters,
      locale: locale,
    );
  }
}