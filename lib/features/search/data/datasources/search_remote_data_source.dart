import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; 
import '../models/filter_model.dart';
import '../models/post_detail_model.dart'; // Импортируем новую модель

abstract class SearchRemoteDataSource {
  Future<Map<String, dynamic>> getFiltersData({
    required String category, 
    required String locale,
  });

  Future<List<dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  });

  // Новый контракт для деталей поста
  Future<Map<String, dynamic>> getPostDetails({
    required int id,
    required String category,
    required String locale,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio client;

  SearchRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getFiltersData({
    required String category,
    required String locale,
  }) async {
    final response = await client.get(
      '/api/v1/filters',
      queryParameters: {'category': category, 'locale': locale},
    );
    
    final data = response.data;
    debugPrint('DEBUG [GET FILTERS DATA]: $data');

    if (data is Map<String, dynamic>) {
      final List rawFilters = data['filters'] ?? [];
      final List<FilterModel> filters = rawFilters
          .map((json) => FilterModel.fromJson(json))
          .toList();

      final Map<String, dynamic> translations = 
          data['translations'] as Map<String, dynamic>? ?? {};

      return {
        'filters': filters,
        'translations': translations,
      };
    }
    throw Exception("Unexpected API response format");
  }

  @override
  Future<List<dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'category': category,
      'locale': locale,
    };

    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryParameters[key] = value; 
      }
    });

    final response = await client.get(
      '/api/v1/search',
      queryParameters: queryParameters,
    );

    final rawData = response.data;
    debugPrint('DEBUG [SEARCH REQUEST]: ${response.realUri}');

    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      return rawData['results'] as List<dynamic>;
    }
    if (rawData is List) return rawData;
    return [];
  }

  // РЕАЛИЗАЦИЯ: Получение деталей поста
  @override
  Future<Map<String, dynamic>> getPostDetails({
    required int id,
    required String category,
    required String locale,
  }) async {
    final response = await client.get(
      '/api/v1/search/$id', // Маршрут search/:id из твоего routes.rb
      queryParameters: {
        'category': category,
        'locale': locale,
      },
    );

    final data = response.data;
    debugPrint('DEBUG [GET POST DETAILS]: $data');

    if (data is Map<String, dynamic>) {
      // Мапим данные в PostDetailModel
      final record = PostDetailModel.fromJson(data['record'] ?? {});
      
      // Извлекаем переводы (блок .show в твоем YAML)
      final Map<String, dynamic> translations = 
          data['translations'] as Map<String, dynamic>? ?? {};

      return {
        'record': record,
        'translations': translations,
      };
    }

    throw Exception("Unexpected API response format for details");
  }
}