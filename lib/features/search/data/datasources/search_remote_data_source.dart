import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; 
import '../models/filter_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<FilterModel>> getFilters({
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
  Future<List<FilterModel>> getFilters({
    required String category,
    required String locale,
  }) async {
    final response = await client.get(
      '/api/v1/filters',
      queryParameters: {'category': category, 'locale': locale},
    );
    
    final data = response.data;

    // ЛОГ ДЛЯ ДИАГНОСТИКИ: Позволит увидеть, что шлет Rails на самом деле
    debugPrint('DEBUG [GET FILTERS]: Ответ от сервера для $category: $data');

    // 1. Если пришел чистый массив
    if (data is List) {
      return data.map((json) => FilterModel.fromJson(json)).toList();
    }

    // 2. Если пришел объект (Map), ищем список внутри по ключам
    if (data is Map<String, dynamic>) {
      final List? list = data['filters'] ?? data['data'] ?? data['items'];
      if (list != null) {
        return list.map((json) => FilterModel.fromJson(json)).toList();
      }
    }

    debugPrint('ОШИБКА: Не удалось найти массив фильтров в ответе API');
    return [];
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
      ...filters, 
    };

    final response = await client.get(
      '/api/v1/search',
      queryParameters: queryParameters,
    );

    final rawData = response.data;

    // ЛОГ ДЛЯ ДИАГНОСТИКИ
    debugPrint('DEBUG [SEARCH]: Результаты поиска: $rawData');

    if (rawData is List) {
      return rawData;
    }

    if (rawData is Map<String, dynamic>) {
      if (rawData.containsKey('results')) return rawData['results'] as List;
      if (rawData.containsKey('data')) return rawData['data'] as List;
      if (rawData.containsKey('items')) return rawData['items'] as List;

      debugPrint('ВНИМАНИЕ: Список результатов не найден в Map. Структура: $rawData');
      return []; 
    }

    return [];
  }
}