// =============================================================================
// FILE: lib/features/search/data/repositories/search_repository_impl.dart
// LAYER: Data Layer (Repository Implementation)
// RESPONSIBILITY: Реализация интерфейса SearchRepository с пробросом 
//                 геолокации (PostGIS) и метаданных животных в RemoteDataSource.
// =============================================================================

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
    final Map<String, dynamic> data = await remoteDataSource.getPostDetails(
      id: id,
      category: category,
      locale: locale,
    );

    return {
      'record': data['record'] as PostDetailModel,
      'translations': data['translations'] as Map<String, dynamic>,
    };
  }
  
  // =========================================================================
  // CREATE POST (Добавлены latitude, longitude, address, animalMetadata)
  // =========================================================================
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
    required String locale,
    required List<String> imagePaths,
  }) {
    return remoteDataSource.createPost(
      category: category,
      title: title,
      text: text,
      localId: localId,
      choiceId: choiceId,
      catId: catId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      animalMetadata: animalMetadata,
      locale: locale,
      imagePaths: imagePaths,
    );
  }

  // =========================================================================
  // UPDATE POST (Добавлены latitude, longitude, address, animalMetadata)
  // =========================================================================
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
    required String locale,
    required List<String> existingImages,
    required List<String> newImagePaths,
  }) async {
    return await remoteDataSource.updatePost(
      postId: postId,
      category: category,
      title: title,
      text: text,
      localId: localId,
      choiceId: choiceId,
      catId: catId,
      latitude: latitude,
      longitude: longitude,
      address: address,
      animalMetadata: animalMetadata,
      locale: locale,
      existingImages: existingImages,
      newImagePaths: newImagePaths,
    );
  }

  @override
  Future<void> deletePost(int postId, String category) async {
    return await remoteDataSource.deletePost(postId, category);
  }
}