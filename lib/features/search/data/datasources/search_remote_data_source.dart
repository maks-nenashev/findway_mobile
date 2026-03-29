import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; 
import '../models/filter_model.dart';

abstract class SearchRemoteDataSource {
  // Теперь возвращает Map, чтобы включить и фильтры, и переводы
  Future<Map<String, dynamic>> getFiltersData({
    required String category, 
    required String locale,
  });

  Future<List<dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
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
    debugPrint('DEBUG [GET FILTERS DATA]: Ответ от сервера: $data');

    if (data is Map<String, dynamic>) {
      // Извлекаем список фильтров
      final List rawFilters = data['filters'] ?? [];
      final List<FilterModel> filters = rawFilters
          .map((json) => FilterModel.fromJson(json))
          .toList();

      // Извлекаем блок переводов из твоего YAML
      final Map<String, dynamic> translations = 
          data['translations'] as Map<String, dynamic>? ?? {};

      return {
        'filters': filters,
        'translations': translations,
      };
    }

    throw Exception("Unexpected API response format for filters");
  }

  @override
  Future<List<dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  }) async {
    // 1. Базовые параметры
    final Map<String, dynamic> queryParameters = {
      'category': category,
      'locale': locale,
    };

    // 2. Оборачиваем фильтры в q[] для совместимости с Ransack (Risk Control)
    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryParameters['q[$key]'] = value;
      }
    });

    final response = await client.get(
      '/api/v1/search',
      queryParameters: queryParameters,
    );

    final rawData = response.data;
    debugPrint('DEBUG [SEARCH]: Результаты: $rawData');

    // Извлекаем результаты из ключа 'results', который мы настроили в Rails
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) {
      return rawData['results'] as List<dynamic>;
    }

    // Fallback на случай, если Rails отдал чистый массив
    if (rawData is List) return rawData;

    return [];
  }
}