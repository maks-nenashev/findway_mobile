import 'package:equatable/equatable.dart';
import '../../data/models/filter_model.dart';
import '../../data/models/post_detail_model.dart';

abstract class SearchState extends Equatable {
  final String currentLocale;
  const SearchState({this.currentLocale = ''});

  @override
  List<Object?> get props => [currentLocale];
}

class SearchInitial extends SearchState {
  const SearchInitial({super.currentLocale});
}

// ================= LOADING =================
class SearchLoading extends SearchState {
  final Map<String, dynamic> uiTranslations;
  const SearchLoading({super.currentLocale, this.uiTranslations = const {}});

  @override
  List<Object?> get props => [...super.props, uiTranslations];
}

// ================= POST DETAILS LOADING =================
class PostDetailsLoading extends SearchState {
  final Map<String, dynamic> uiTranslations;
  const PostDetailsLoading({super.currentLocale, this.uiTranslations = const {}});

  @override
  List<Object?> get props => [...super.props, uiTranslations];
}

// ================= POST DETAILS LOADED =================
class PostDetailsLoaded extends SearchState {
  final PostDetailModel post;
  final Map<String, dynamic> uiTranslations;
  final List<dynamic> searchResults;
  final List<FilterModel> filters;

  const PostDetailsLoaded({
    super.currentLocale,
    required this.post,
    required this.uiTranslations,
    this.searchResults = const [],
    this.filters = const [],
  });

  @override
  List<Object?> get props =>
      [...super.props, post, uiTranslations, searchResults, filters];
}

// ================= RESULTS LOADING =================
class ResultsLoading extends SearchState {
  final int tabIndex;
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final Map<String, dynamic> uiTranslations;
  final List<dynamic> results;

  const ResultsLoading({
    super.currentLocale,
    this.tabIndex = 1,
    required this.filters,
    required this.selectedValues,
    required this.uiTranslations,
    required this.results,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        tabIndex,
        filters,
        selectedValues,
        uiTranslations,
        results
      ];

  ResultsLoading copyWith({
    int? tabIndex,
    String? currentLocale,
    Map<String, dynamic>? selectedValues,
  }) =>
      ResultsLoading(
        currentLocale: currentLocale ?? this.currentLocale,
        tabIndex: tabIndex ?? this.tabIndex,
        filters: filters,
        selectedValues: selectedValues ?? this.selectedValues,
        uiTranslations: uiTranslations,
        results: results,
      );
}

// ================= FILTERS LOADED =================
class FiltersLoaded extends SearchState {
  final int tabIndex;
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final Map<String, dynamic> uiTranslations;
  final String currentCategory;
  final List<dynamic> results;

  const FiltersLoaded({
    super.currentLocale,
    this.tabIndex = 1,
    required this.filters,
    required this.selectedValues,
    required this.uiTranslations,
    required this.currentCategory,
    required this.results,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        tabIndex,
        filters,
        selectedValues,
        uiTranslations,
        currentCategory,
        results
      ];

  FiltersLoaded copyWith({
    int? tabIndex,
    List<FilterModel>? filters,
    Map<String, dynamic>? selectedValues,
    Map<String, dynamic>? uiTranslations,
    String? currentCategory,
    String? currentLocale,
    List<dynamic>? results,
  }) =>
      FiltersLoaded(
        currentLocale: currentLocale ?? this.currentLocale,
        tabIndex: tabIndex ?? this.tabIndex,
        filters: filters ?? this.filters,
        selectedValues: selectedValues ?? this.selectedValues,
        uiTranslations: uiTranslations ?? this.uiTranslations,
        currentCategory: currentCategory ?? this.currentCategory,
        results: results ?? this.results,
      );
}

// ================= SEARCH SUCCESS =================
class SearchSuccess extends SearchState {
  final int tabIndex;
  final List<dynamic> results;
  final Map<String, dynamic> uiTranslations;
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;

  const SearchSuccess(
    this.results, {
    super.currentLocale,
    this.tabIndex = 1,
    required this.uiTranslations,
    required this.filters,
    required this.selectedValues,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        tabIndex,
        results,
        uiTranslations,
        filters,
        selectedValues
      ];

  SearchSuccess copyWith({
    int? tabIndex,
    String? currentLocale,
    Map<String, dynamic>? selectedValues,
  }) =>
      SearchSuccess(
        results,
        currentLocale: currentLocale ?? this.currentLocale,
        tabIndex: tabIndex ?? this.tabIndex,
        uiTranslations: uiTranslations,
        filters: filters,
        selectedValues: selectedValues ?? this.selectedValues,
      );
}

// ================= ERROR =================
class SearchError extends SearchState {
  final String message;
  final Map<String, dynamic> uiTranslations;

  const SearchError(this.message,
      {super.currentLocale, this.uiTranslations = const {}});

  @override
  List<Object?> get props =>
      [...super.props, message, uiTranslations];
}

// ================= CREATE =================
class PostCreateSuccess extends SearchState {
  final int postId;

  const PostCreateSuccess({
    required this.postId,
    required super.currentLocale,
  });

  @override
  List<Object?> get props => [...super.props, postId];
}

class PostCreateError extends SearchState {
  final String error;

  const PostCreateError({
    required this.error,
    required super.currentLocale,
  });

  @override
  List<Object?> get props => [...super.props, error];
}

// ================= DELETE =================
class PostDeleteSuccess extends SearchState {
  final Map<String, dynamic> uiTranslations;

  const PostDeleteSuccess({
    required super.currentLocale,
    this.uiTranslations = const {},
  });

  @override
  List<Object?> get props => [...super.props, uiTranslations];
}