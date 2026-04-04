import 'package:equatable/equatable.dart';
import '../../data/models/filter_model.dart';
import '../../data/models/post_detail_model.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

// --- БАЗОВЫЕ СОСТОЯНИЯ ---
class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

// Состояние загрузки конкретного объявления (результата)
class ResultsLoading extends SearchState {
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final Map<String, dynamic> uiTranslations;
  final List<dynamic> results;

  const ResultsLoading({
    required this.filters,
    required this.selectedValues,
    required this.uiTranslations,
    required this.results,
  });

  @override
  List<Object?> get props => [filters, selectedValues, uiTranslations, results];
}

// Состояние загрузки конкретного поста (Risk Control)
class PostDetailsLoading extends SearchState {}

// --- СОСТОЯНИЯ С ДАННЫМИ ---

class FiltersLoaded extends SearchState {
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final Map<String, dynamic> uiTranslations; 
  final String currentCategory;
  final String currentLocale;
  // Добавлено: чтобы объявления были видны в этом стейте
  final List<dynamic> results;

  const FiltersLoaded({
    required this.filters,
    required this.selectedValues,
    required this.uiTranslations,
    required this.currentCategory,
    required this.results,
    this.currentLocale = 'uk',
  });

  @override
  List<Object?> get props => [
        filters, 
        selectedValues, 
        uiTranslations, 
        currentCategory, 
        currentLocale,
        results,
      ];

  FiltersLoaded copyWith({
    List<FilterModel>? filters,
    Map<String, dynamic>? selectedValues,
    Map<String, dynamic>? uiTranslations,
    String? currentCategory,
    String? currentLocale,
    List<dynamic>? results,
  }) {
    return FiltersLoaded(
      filters: filters ?? this.filters,
      selectedValues: selectedValues ?? this.selectedValues,
      uiTranslations: uiTranslations ?? this.uiTranslations,
      currentCategory: currentCategory ?? this.currentCategory,
      currentLocale: currentLocale ?? this.currentLocale,
      results: results ?? this.results,
    );
  }
}

class SearchSuccess extends SearchState {
  final List<dynamic> results;
  final Map<String, dynamic> uiTranslations;
  // Добавлено: чтобы фильтры не исчезали в этом стейте
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;

  const SearchSuccess(
    this.results, {
    required this.uiTranslations,
    required this.filters,
    required this.selectedValues,
  });

  @override
  List<Object?> get props => [results, uiTranslations, filters, selectedValues];
}

// Новое состояние для деталей поста
class PostDetailsLoaded extends SearchState {
  final PostDetailModel post;
  final Map<String, dynamic> uiTranslations; // Блок .show из твоего YAML

  const PostDetailsLoaded({
    required this.post, 
    required this.uiTranslations,
  });

  @override
  List<Object?> get props => [post, uiTranslations];
}

// --- ОШИБКИ ---
class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}