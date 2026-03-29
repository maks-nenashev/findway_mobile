import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';
import '../models/filter_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<FilterModel>> getFilters({
    required String category,
    required String locale,
  }) async {
    // ИСПРАВЛЕНО: Добавлены имена параметров category: и locale:
    return await remoteDataSource.getFilters(
      category: category, 
      locale: locale,
    );
  }

  @override
  Future<List<dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  }) async {
    // Проброс вызова в DataSource
    return await remoteDataSource.search(
      category: category,
      filters: filters,
      locale: locale,
    );
  }
}