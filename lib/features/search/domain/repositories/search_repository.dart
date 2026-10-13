
// =============================================================================
// ABSTRACT SEARCH REPOSITORY CONTRACT
// =============================================================================
abstract class SearchRepository {
  // ===========================================================================
  // 1. GET FILTERS DATA
  // ===========================================================================
  Future<Map<String, dynamic>> getFiltersData({
    required String category, 
    required String locale,
  });
  
  // ===========================================================================
  // 2. SEARCH RECORDS
  // ===========================================================================
  Future<List<dynamic>> search({
    required String category, 
    required Map<String, dynamic> filters, 
    required String locale,
  });
  
  // ===========================================================================
  // 3. GET POST DETAILS
  // ===========================================================================
  Future<Map<String, dynamic>> getPostDetails({
    required int id, 
    required String category, 
    required String locale,
  });

  // ===========================================================================
  // 4. CREATE POST (With Geolocation & JSONB Metadata)
  // ===========================================================================
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
  });

  // ===========================================================================
  // 5. UPDATE POST (With Geolocation & JSONB Metadata)
  // ===========================================================================
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
  });

  // ===========================================================================
  // 6. DELETE POST
  // ===========================================================================
  Future<void> deletePost(int postId, String category); 
}