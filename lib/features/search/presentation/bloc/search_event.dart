// =============================================================================
// FILE: lib/features/search/presentation/bloc/search_event.dart
// LAYER: Presentation Layer (BLoc Events)
// RESPONSIBILITY: Strongly-typed BLoc events with geolocation and metadata
//                 support (animalMetadata & thingMetadata).
// =============================================================================

import 'package:equatable/equatable.dart';

// =============================================================================
// 0. ABSTRACT BASE EVENT
// =============================================================================
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

// =============================================================================
// 1. LOAD FILTERS EVENT
// =============================================================================
class LoadFilters extends SearchEvent {
  final String category;
  final String locale;

  const LoadFilters({required this.category, required this.locale});

  @override
  List<Object?> get props => [category, locale];
}

// =============================================================================
// 2. UPDATE FILTER VALUE EVENT
// =============================================================================
class UpdateFilterValue extends SearchEvent {
  final String filterId; 
  final dynamic value;   

  const UpdateFilterValue({required this.filterId, required this.value});

  @override
  List<Object?> get props => [filterId, value];
}

// =============================================================================
// 3. PERFORM SEARCH EVENT
// =============================================================================
class PerformSearch extends SearchEvent {
  const PerformSearch();
}

// =============================================================================
// 4. CHANGE LOCALE EVENT
// =============================================================================
class ChangeLocale extends SearchEvent {
  final String locale;
  const ChangeLocale(this.locale);

  @override
  List<Object?> get props => [locale];
}

// =============================================================================
// 5. LOAD POST DETAILS EVENT
// =============================================================================
class LoadPostDetails extends SearchEvent {
  final int id;
  final String category;
  final String locale;

  const LoadPostDetails({
    required this.id, 
    required this.category, 
    required this.locale,
  });

  @override
  List<Object?> get props => [id, category, locale];
}

// =============================================================================
// 6. CHANGE TAB EVENT ("Search" / "Found")
// =============================================================================
class ChangeTab extends SearchEvent {
  final int index;
  const ChangeTab(this.index);

  @override
  List<Object> get props => [index];
}

// =============================================================================
// 7. RESTORE SEARCH EVENT (From Cache)
// =============================================================================
class RestoreSearch extends SearchEvent {
  @override
  List<Object> get props => [];
}

// =============================================================================
// 8. CREATE POST EVENT (With Geolocation, Animal & Thing Metadata)
// =============================================================================
class CreatePost extends SearchEvent {
  final String category;
  final String title;
  final String text;
  final int localId;
  final int choiceId;
  final int? catId;

  // 👉 Geolocation fields
  final double? latitude;
  final double? longitude;
  final String? address;

  // 👉 Dynamic JSONB Metadata
  final Map<String, dynamic>? animalMetadata;
  final Map<String, dynamic>? thingMetadata;

  final String locale;
  final List<String> imagePaths;

  const CreatePost({
    required this.category,
    required this.title,
    required this.text,
    required this.localId,
    required this.choiceId,
    this.catId,
    this.latitude,
    this.longitude,
    this.address,
    this.animalMetadata,
    this.thingMetadata,
    required this.locale,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [
        category,
        title,
        text,
        localId,
        choiceId,
        catId,
        latitude,
        longitude,
        address,
        animalMetadata,
        thingMetadata,
        locale,
        imagePaths,
      ];
}

// =============================================================================
// 9. UPDATE POST EVENT (With Geolocation, Animal & Thing Metadata)
// =============================================================================
class UpdatePost extends SearchEvent {
  final int postId;
  final String category;
  final String title;
  final String text;
  final int localId;
  final int choiceId;
  final int? catId;

  // 👉 Geolocation fields
  final double? latitude;
  final double? longitude;
  final String? address;

  // 👉 Dynamic JSONB Metadata
  final Map<String, dynamic>? animalMetadata;
  final Map<String, dynamic>? thingMetadata;

  final String locale;
  final List<String> existingImages;
  final List<String> newImagePaths;

  const UpdatePost({
    required this.postId,
    required this.category,
    required this.title,
    required this.text,
    required this.localId,
    required this.choiceId,
    this.catId,
    this.latitude,
    this.longitude,
    this.address,
    this.animalMetadata,
    this.thingMetadata,
    required this.locale,
    required this.existingImages,
    required this.newImagePaths,
  });

  @override
  List<Object?> get props => [
        postId,
        category,
        title,
        text,
        localId,
        choiceId,
        catId,
        latitude,
        longitude,
        address,
        animalMetadata,
        thingMetadata,
        locale,
        existingImages,
        newImagePaths,
      ];
}

// =============================================================================
// 10. DELETE POST EVENT
// =============================================================================
class DeletePost extends SearchEvent {
  final int postId;
  final String category;

  const DeletePost({required this.postId, required this.category});

  @override
  List<Object?> get props => [postId, category];
}

// =============================================================================
// 11 GEOLOCATION UPDATE EVENT
// =============================================================================
class SearchFilterChanged extends SearchEvent {
  final double? lat;
  final double? lng;
  final double? radiusKm;

  const SearchFilterChanged({
    this.lat,
    this.lng,
    this.radiusKm,
  });

  @override
  List<Object?> get props => [lat, lng, radiusKm];
}

// =============================================================================
// 12. CHANGE PAGE EVENT
// =============================================================================
class ChangePage extends SearchEvent {
  final int page;

  const ChangePage(this.page);

  @override
  List<Object?> get props => [page];
}