import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class LoadFilters extends SearchEvent {
  final String category;
  final String locale;

  const LoadFilters({required this.category, required this.locale});

  @override
  List<Object?> get props => [category, locale];
}

class UpdateFilterValue extends SearchEvent {
  final String filterId; 
  final dynamic value;   

  const UpdateFilterValue({required this.filterId, required this.value});

  @override
  List<Object?> get props => [filterId, value];
}

class PerformSearch extends SearchEvent {
  const PerformSearch();
}

class ChangeLocale extends SearchEvent {
  final String locale;
  const ChangeLocale(this.locale);

  @override
  List<Object?> get props => [locale];
}

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

class ChangeTab extends SearchEvent {
  final int index;
  const ChangeTab(this.index);
  
  @override
  List<Object> get props => [index];
}

class RestoreSearch extends SearchEvent {
  @override
  List<Object> get props => [];
}

// =============================================================================
// СОБЫТИЕ СОЗДАНИЯ ПОСТА (CreatePost)
// =============================================================================
class CreatePost extends SearchEvent {
  final String category;
  final String title;
  final String text;
  final int localId;
  final int choiceId;
  final int? catId;

  // 👉 Геолокационные данные и подпараметры животных
  final double? latitude;
  final double? longitude;
  final String? address;
  final Map<String, dynamic>? animalMetadata;

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
        locale,
        imagePaths,
      ];
}

// =============================================================================
// СОБЫТИЕ УДАЛЕНИЯ ПОСТА (DeletePost)
// =============================================================================
class DeletePost extends SearchEvent {
  final int postId;
  final String category;

  const DeletePost({required this.postId, required this.category});

  @override
  List<Object?> get props => [postId, category];
}

// =============================================================================
// СОБЫТИЕ ОБНОВЛЕНИЯ ПОСТА (UpdatePost)
// =============================================================================
class UpdatePost extends SearchEvent {
  final int postId;
  final String category;
  final String title;
  final String text;
  final int localId;
  final int choiceId;
  final int? catId;

  // 👉 Геолокационные данные и подпараметры животных
  final double? latitude;
  final double? longitude;
  final String? address;
  final Map<String, dynamic>? animalMetadata;

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
        locale,
        existingImages,
        newImagePaths,
      ];
}