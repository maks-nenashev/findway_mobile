import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';
import '../models/filter_model.dart';
import '../models/post_detail_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> getFiltersData({
    required String category,
    required String locale,
  }) async {
    final Map<String, dynamic> data = await remoteDataSource.getFiltersData(
      category: category, 
      locale: locale,
    );

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
    return await remoteDataSource.search(
      category: category,
      filters: filters,
      locale: locale,
    );
  }

  @override
  Future<Map<String, dynamic>> getPostDetails({
    required int id,
    required String category,
    required String locale,
  }) async {
    // Получаем данные из DataSource
    final Map<String, dynamic> data = await remoteDataSource.getPostDetails(
      id: id,
      category: category,
      locale: locale,
    );

    // Возвращаем типизированную структуру для Блока
    return {
      'record': data['record'] as PostDetailModel,
      'translations': data['translations'] as Map<String, dynamic>,
    };
  }
}