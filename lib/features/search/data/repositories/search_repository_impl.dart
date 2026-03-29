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
    // Просто передаем запрос в сетевой источник данных
    return await remoteDataSource.getFilters(category, locale);
  }
}