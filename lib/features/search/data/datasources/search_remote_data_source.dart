import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; 
import 'package:path/path.dart' as p;
import '../models/filter_model.dart';
import '../models/post_detail_model.dart';

abstract class SearchRemoteDataSource {
  Future<Map<String, dynamic>> getFiltersData({required String category, required String locale});
  Future<List<dynamic>> search({required String category, required Map<String, dynamic> filters, required String locale});
  Future<Map<String, dynamic>> getPostDetails({required int id, required String category, required String locale});
  
  // Метод для создания поста
  Future<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    required String locale,
    required List<String> imagePaths,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio client;
  SearchRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getFiltersData({required String category, required String locale}) async {
    final response = await client.get('/api/v1/filters', queryParameters: {'category': category, 'locale': locale});
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final List rawFilters = data['filters'] ?? [];
      final List<FilterModel> filters = rawFilters.map((json) => FilterModel.fromJson(json)).toList();
      final Map<String, dynamic> translations = data['translations'] as Map<String, dynamic>? ?? {};
      return {'filters': filters, 'translations': translations};
    }
    throw Exception("Unexpected API response format");
  }

  @override
  Future<List<dynamic>> search({required String category, required Map<String, dynamic> filters, required String locale}) async {
    final Map<String, dynamic> queryParameters = {'category': category, 'locale': locale};
    filters.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) queryParameters[key] = value;
    });
    final response = await client.get('/api/v1/search', queryParameters: queryParameters);
    final rawData = response.data;
    if (rawData is Map<String, dynamic> && rawData.containsKey('results')) return rawData['results'] as List<dynamic>;
    if (rawData is List) return rawData;
    return [];
  }

  @override
  Future<Map<String, dynamic>> getPostDetails({required int id, required String category, required String locale}) async {
    final response = await client.get('/api/v1/search/$id', queryParameters: {'category': category, 'locale': locale});
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final record = PostDetailModel.fromJson(data['record'] ?? {});
      final Map<String, dynamic> translations = data['translations'] as Map<String, dynamic>? ?? {};
      return {'record': record, 'translations': translations};
    }
    throw Exception("Unexpected API response format for details");
  }

 @override
  Future<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    required String locale,
    required List<String> imagePaths,
  }) async {
    // 1. Приводим категорию к нижнему регистру (People -> people)
    final normalizedCategory = category.toLowerCase();

    // 2. Формируем FormData
    final formData = FormData.fromMap({
      'category': normalizedCategory,
      'title': title,
      'text': text,
      'local_id': localId,
      'choice_id': choiceId,
      'phone_id': catId, // catId из UI мапим в phone_id контроллера
      'locale': locale,
    });

    // 3. Добавляем картинки
    for (String path in imagePaths) {
      formData.files.add(MapEntry(
        'images[]',
        await MultipartFile.fromFile(path, filename: p.basename(path)),
      ));
    }

    // 4. ОТПРАВКА: Убираем принудительный application/json
    final response = await client.post(
      '/api/v1/posts',
      data: formData,
      options: Options(
        headers: {
          'Accept': 'application/json', // Оставляем только Accept
          // Content-Type НЕ ПИШЕМ, Dio поставит multipart/form-data сам
        },
      ),
    );

    return response.data as Map<String, dynamic>;
  }
}