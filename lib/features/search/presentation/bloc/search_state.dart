import 'package:equatable/equatable.dart';
import '../../data/models/filter_model.dart';
import '../../data/models/post_detail_model.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class PostDetailsLoading extends SearchState {}

// 1. Состояние загрузки (с поддержкой вкладок)
class ResultsLoading extends SearchState {
  final int tabIndex;
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final Map<String, dynamic> uiTranslations;
  final List<dynamic> results;

  const ResultsLoading({
    this.tabIndex = 1,
    required this.filters,
    required this.selectedValues,
    required this.uiTranslations,
    required this.results,
  });

  @override
  List<Object?> get props => [tabIndex, filters, selectedValues, uiTranslations, results];

  ResultsLoading copyWith({int? tabIndex}) => ResultsLoading(
    tabIndex: tabIndex ?? this.tabIndex,
    filters: filters,
    selectedValues: selectedValues,
    uiTranslations: uiTranslations,
    results: results,
  );
}

// 2. Основное состояние фильтров
class FiltersLoaded extends SearchState {
  final int tabIndex;
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final Map<String, dynamic> uiTranslations; 
  final String currentCategory;
  final String currentLocale;
  final List<dynamic> results;

  const FiltersLoaded({
    this.tabIndex = 1,
    required this.filters,
    required this.selectedValues,
    required this.uiTranslations,
    required this.currentCategory,
    required this.results,
    this.currentLocale = 'uk',
  });

  @override
  List<Object?> get props => [tabIndex, filters, selectedValues, uiTranslations, currentCategory, currentLocale, results];

  FiltersLoaded copyWith({
    int? tabIndex,
    List<FilterModel>? filters,
    Map<String, dynamic>? selectedValues,
    Map<String, dynamic>? uiTranslations,
    String? currentCategory,
    String? currentLocale,
    List<dynamic>? results,
  }) => FiltersLoaded(
    tabIndex: tabIndex ?? this.tabIndex,
    filters: filters ?? this.filters,
    selectedValues: selectedValues ?? this.selectedValues,
    uiTranslations: uiTranslations ?? this.uiTranslations,
    currentCategory: currentCategory ?? this.currentCategory,
    currentLocale: currentLocale ?? this.currentLocale,
    results: results ?? this.results,
  );
}

// 3. Состояние успеха (с поддержкой вкладок)
class SearchSuccess extends SearchState {
  final int tabIndex;
  final List<dynamic> results;
  final Map<String, dynamic> uiTranslations;
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;

  const SearchSuccess(
    this.results, {
    this.tabIndex = 1,
    required this.uiTranslations,
    required this.filters,
    required this.selectedValues,
  });

  @override
  List<Object?> get props => [tabIndex, results, uiTranslations, filters, selectedValues];

  SearchSuccess copyWith({int? tabIndex}) => SearchSuccess(
    results,
    tabIndex: tabIndex ?? this.tabIndex,
    uiTranslations: uiTranslations,
    filters: filters,
    selectedValues: selectedValues,
  );
}

class PostDetailsLoaded extends SearchState {
  final PostDetailModel post;
  final Map<String, dynamic> uiTranslations;
  const PostDetailsLoaded({required this.post, required this.uiTranslations});
  @override
  List<Object?> get props => [post, uiTranslations];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}