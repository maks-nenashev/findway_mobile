// =============================================================================
// FILE: lib/features/search/data/repositories/search_repository_impl.dart
// LAYER: Data Layer (Repository Implementation)
// RESPONSIBILITY: Concrete implementation routing data sources and preserving
//                 Pagy pagination metadata payload.
// =============================================================================

import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';
import '../models/filter_model.dart';
import '../models/post_detail_model.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  // ===========================================================================
  // 1. GET FILTERS DATA
  // ===========================================================================
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

  // ===========================================================================
  // 2. SEARCH RECORDS (Returns dynamic payload preserving Pagy metadata)
  // ===========================================================================
  @override
  Future<Map<String, dynamic>> search({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  }) async {
    return await remoteDataSource.search(
      category: category,
      filters: filters,
      locale: locale,
    ) as Map<String, dynamic>;
  }

  // ===========================================================================
  // 3. GET POST DETAILS
  // ===========================================================================
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

  // ===========================================================================
  // 4. CREATE POST (With Geolocation & JSONB Metadata)
  // ===========================================================================
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
      thingMetadata: thingMetadata,
      locale: locale,
      imagePaths: imagePaths,
    );
  }

  // ===========================================================================
  // 5. UPDATE POST (With Geolocation & JSONB Metadata)
  // ===========================================================================
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
      thingMetadata: thingMetadata,
      locale: locale,
      existingImages: existingImages,
      newImagePaths: newImagePaths,
    );
  }

  // ===========================================================================
  // 6. DELETE POST
  // ===========================================================================
  @override
  Future<void> deletePost(int postId, String category) async {
    return await remoteDataSource.deletePost(postId, category);
  }
}