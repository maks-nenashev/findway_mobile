// =============================================================================
// FILE: lib/features/search/data/datasources/search_remote_data_source.dart
// LAYER: Data Layer (Remote Data Source)
// RESPONSIBILITY: Выполнение HTTP-запросов (Dio) к API Rails с поддержкой
//                 геолокации, animal_metadata, thing_metadata и сохранением Pagy-пагинации.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../models/filter_model.dart';
import '../models/post_detail_model.dart';

// =============================================================================
// 👉 КОНТРАКТ (ИНТЕРФЕЙС)
// =============================================================================
abstract class SearchRemoteDataSource {
  Future<Map<String, dynamic>> getFiltersData({
    required String category,
    required String locale,
  });

  Future<dynamic> search({
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
    
    // 👉 Геолокация и идентификаторы (JSONB)
    double? latitude,
    double? longitude,
    String? address,
    Map<String, dynamic>? animalMetadata,
    Map<String, dynamic>? thingMetadata,
    
    required String locale,
    required List<String> imagePaths,
  });

  Future<void> updatePost({
    required int postId,
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    
    // 👉 Геолокация и идентификаторы (JSONB)
    double? latitude,
    double? longitude,
    String? address,
    Map<String, dynamic>? animalMetadata,
    Map<String, dynamic>? thingMetadata,
    
    required String locale,
    required List<String> existingImages,
    required List<String> newImagePaths,
  });

  Future<void> deletePost(int postId, String category);
}

// =============================================================================
// 👉 РЕАЛИЗАЦИЯ (ИМПЛЕМЕНТАЦИЯ)
// =============================================================================
class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio client;

  SearchRemoteDataSourceImpl({required this.client});

  @override
  Future<Map<String, dynamic>> getFiltersData({
    required String category,
    required String locale,
  }) async {
    final filtersFuture = client.get(
      '/api/v1/filters',
      queryParameters: {
        'category': category,
        'locale': locale,
      },
    );

    final metaFuture = client.get(
      '/api/v1/search/new_meta',
      queryParameters: {
        'category': category,
        'locale': locale,
      },
    ).catchError((e) {
      return Response(
        requestOptions: RequestOptions(path: ''),
        data: {'translations': {}},
      );
    });

    final results = await Future.wait([filtersFuture, metaFuture]);
    final filtersResponse = results[0];
    final metaResponse = results[1];

    final filtersData = filtersResponse.data;
    final metaData = metaResponse.data;

    if (filtersData is Map<String, dynamic>) {
      final List rawFilters = filtersData['filters'] ?? [];
      final filters = rawFilters.map((json) => FilterModel.fromJson(json)).toList();
      final baseTranslations = filtersData['translations'] is Map 
          ? Map<String, dynamic>.from(filtersData['translations']) 
          : <String, dynamic>{};
      final metaTranslations = (metaData is Map<String, dynamic> && metaData['translations'] is Map)
          ? Map<String, dynamic>.from(metaData['translations'])
          : <String, dynamic>{};

      final combinedTranslations = {
        ...baseTranslations,
        ...metaTranslations,
      };

      return {
        'filters': filters,
        'translations': combinedTranslations,
      };
    }
    throw Exception("Unexpected API response format");
  }

  @override
  Future<dynamic> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'category': category,
      'locale': locale,
      ...filters,
    };

    if (queryParameters.containsKey('sort') && queryParameters['sort'] is String) {
      final sortVal = queryParameters['sort'] as String;
      if (sortVal.contains('_')) {
        final parts = sortVal.split('_');
        queryParameters['sort_by'] = parts.sublist(0, parts.length - 1).join('_');
        queryParameters['order'] = parts.last;
      }
    }

    final response = await client.get('/api/v1/search', queryParameters: queryParameters);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> getPostDetails({
    required int id,
    required String category,
    required String locale,
  }) async {
    final response = await client.get(
      '/api/v1/search/$id',
      queryParameters: {'category': category, 'locale': locale},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final record = PostDetailModel.fromJson(data['record'] ?? {});
      final translations = data['translations'] as Map<String, dynamic>? ?? {};
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
    double? latitude,
    double? longitude,
    String? address,
    Map<String, dynamic>? animalMetadata,
    Map<String, dynamic>? thingMetadata,
    required String locale,
    required List<String> imagePaths,
  }) async {
    final normalizedCategory = category.toLowerCase();
    String? subCategoryKey;
    switch (normalizedCategory) {
      case 'people': subCategoryKey = 'live_id'; break;
      case 'animals': subCategoryKey = 'cat_id'; break;
      case 'things': subCategoryKey = 'phone_id'; break;
    }

    final Map<String, dynamic> data = {
      'category': normalizedCategory,
      'title': title,
      'text': text,
      'local_id': localId,
      'choice_id': choiceId,
      'locale': locale,
    };

    if (catId != null && subCategoryKey != null) {
      data[subCategoryKey] = catId;
    }

    // Добавление координат и метаданных в payload
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (address != null && address.isNotEmpty) data['address'] = address;
    if (animalMetadata != null && animalMetadata.isNotEmpty) {
      data['animal_metadata'] = animalMetadata;
    }
    if (thingMetadata != null && thingMetadata.isNotEmpty) {
      data['thing_metadata'] = thingMetadata;
    }

    final formData = FormData.fromMap(data);
    for (final path in imagePaths) {
      formData.files.add(MapEntry('images[]', await MultipartFile.fromFile(path, filename: p.basename(path))));
    }

    final response = await client.post('/api/v1/posts', data: formData, options: Options(headers: {'Accept': 'application/json'}));
    final resData = response.data;
    if (resData is Map<String, dynamic>) return resData;
    throw Exception("Invalid response format on createPost");
  }

  @override
  Future<void> updatePost({
    required int postId,
    required String category,
    required String title,
    required String text,
    required int localId,
    required int choiceId,
    int? catId,
    double? latitude,
    double? longitude,
    String? address,
    Map<String, dynamic>? animalMetadata,
    Map<String, dynamic>? thingMetadata,
    required String locale,
    required List<String> existingImages,
    required List<String> newImagePaths,
  }) async {
    final normalizedCategory = category.toLowerCase();
    String? subCategoryKey;
    switch (normalizedCategory) {
      case 'people': subCategoryKey = 'live_id'; break;
      case 'animals': subCategoryKey = 'cat_id'; break;
      case 'things': subCategoryKey = 'phone_id'; break;
    }

    final Map<String, dynamic> data = {
      'category': normalizedCategory,
      'title': title,
      'text': text,
      'local_id': localId,
      'choice_id': choiceId,
      'locale': locale,
    };

    if (catId != null && subCategoryKey != null) {
      data[subCategoryKey] = catId;
    }

    // Добавление координат и метаданных в payload
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (address != null && address.isNotEmpty) data['address'] = address;
    if (animalMetadata != null && animalMetadata.isNotEmpty) {
      data['animal_metadata'] = animalMetadata;
    }
    if (thingMetadata != null && thingMetadata.isNotEmpty) {
      data['thing_metadata'] = thingMetadata;
    }

    if (existingImages.isNotEmpty) {
      data['existing_images[]'] = existingImages;
    }

    final formData = FormData.fromMap(data);

    for (final path in newImagePaths) {
      formData.files.add(
        MapEntry(
          'new_images[]',
          await MultipartFile.fromFile(path, filename: p.basename(path))
        )
      );
    }

    final response = await client.patch(
      '/api/v1/posts/$postId',
      data: formData,
      options: Options(headers: {'Accept': 'application/json'}),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update post');
    }
  }

  @override
  Future<void> deletePost(int postId, String category) async {
    final response = await client.delete(
      '/api/v1/posts/$postId', 
      queryParameters: {
        'category': category, 
      },
      options: Options(
        headers: {'Accept': 'application/json'},
      ),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete post');
    }
  }
}