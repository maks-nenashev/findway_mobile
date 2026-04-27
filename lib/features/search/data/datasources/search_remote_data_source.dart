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
    int? catId,
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
    int? catId,
    required String locale,
    required List<String> imagePaths,
  }) async {
    final normalizedCategory = category.toLowerCase();

    String subCategoryKey = 'phone_id';
    if (normalizedCategory == 'people') subCategoryKey = 'live_id';
    if (normalizedCategory == 'animals') subCategoryKey = 'cat_id';

    final formData = FormData.fromMap({
      'category': normalizedCategory,
      'title': title,
      'text': text,
      'local_id': localId,
      'choice_id': choiceId,
      if (catId != null) subCategoryKey: catId,
      'locale': locale,
    });

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

    final data = response.data;

    if (data is Map<String, dynamic>) return data;

    throw Exception("Invalid response format on createPost");
  }
}