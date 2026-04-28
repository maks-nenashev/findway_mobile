import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../models/filter_model.dart';
import '../models/post_detail_model.dart';

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

  Future<Map<String, dynamic>> getPostDetails({
    required int id,
    required String category,
    required String locale,
  });

  Future<Map<String, dynamic>> createPost({
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId, // НЕ МЕНЯЕМ (важно)
    required String locale,
    required List<String> imagePaths,
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
      queryParameters: {
        'category': category,
        'locale': locale,
      },
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      final List rawFilters = data['filters'] ?? [];

      final filters = rawFilters
          .map((json) => FilterModel.fromJson(json))
          .toList();

      final translations =
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
    final queryParameters = {
      'category': category,
      'locale': locale,
      ...filters,
    };

    final response = await client.get(
      '/api/v1/search',
      queryParameters: queryParameters,
    );

    final rawData = response.data;

    if (rawData is Map<String, dynamic> &&
        rawData.containsKey('results')) {
      return rawData['results'] as List<dynamic>;
    }

    if (rawData is List) return rawData;

    return [];
  }

  @override
  Future<Map<String, dynamic>> getPostDetails({
    required int id,
    required String category,
    required String locale,
  }) async {
    final response = await client.get(
      '/api/v1/search/$id',
      queryParameters: {
        'category': category,
        'locale': locale,
      },
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      final record =
          PostDetailModel.fromJson(data['record'] ?? {});

      final translations =
          data['translations'] as Map<String, dynamic>? ?? {};

      return {
        'record': record,
        'translations': translations,
      };
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
    int? catId, // используем как универсальный subCategoryId
    required String locale,
    required List<String> imagePaths,
  }) async {
    final normalizedCategory = category.toLowerCase();

    // ✅ ЖЁСТКИЙ МАППИНГ (исправление бага)
    String? subCategoryKey;

    switch (normalizedCategory) {
      case 'people':
        subCategoryKey = 'live_id';
        break;
      case 'animals':
        subCategoryKey = 'cat_id';
        break;
      case 'things':
        subCategoryKey = 'phone_id';
        break;
    }

    final Map<String, dynamic> data = {
      'category': normalizedCategory,
      'title': title,
      'text': text,
      'local_id': localId,
      'choice_id': choiceId,
      'locale': locale,
    };

    // ✅ КЛЮЧЕВОЙ ФИКС
    if (catId != null && subCategoryKey != null) {
      data[subCategoryKey] = catId;
    }

    final formData = FormData.fromMap(data);

    for (final path in imagePaths) {
      formData.files.add(
        MapEntry(
          'images[]',
          await MultipartFile.fromFile(
            path,
            filename: p.basename(path),
          ),
        ),
      );
    }

    final response = await client.post(
      '/api/v1/posts',
      data: formData,
      options: Options(
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    final resData = response.data;

    if (resData is Map<String, dynamic>) return resData;

    throw Exception("Invalid response format on createPost");
  }
}