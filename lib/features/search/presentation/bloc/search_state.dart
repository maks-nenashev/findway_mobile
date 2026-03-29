import 'package:equatable/equatable.dart';
import '../../data/models/filter_model.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class ResultsLoading extends SearchState {}

class FiltersLoaded extends SearchState {
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final Map<String, dynamic> uiTranslations; // Данные из твоего Rails YAML
  final String currentCategory;
  final String currentLocale;

  const FiltersLoaded({
    required this.filters,
    required this.selectedValues,
    required this.uiTranslations, // Инициализация обязательна
    required this.currentCategory,
    this.currentLocale = 'uk',
  });

  @override
  List<Object?> get props => [
        filters, 
        selectedValues, 
        uiTranslations, 
        currentCategory, 
        currentLocale
      ];

  FiltersLoaded copyWith({
    List<FilterModel>? filters,
    Map<String, dynamic>? selectedValues,
    Map<String, dynamic>? uiTranslations,
    String? currentCategory,
    String? currentLocale,
  }) {
    return FiltersLoaded(
      filters: filters ?? this.filters,
      selectedValues: selectedValues ?? this.selectedValues,
      uiTranslations: uiTranslations ?? this.uiTranslations,
      currentCategory: currentCategory ?? this.currentCategory,
      currentLocale: currentLocale ?? this.currentLocale,
    );
  }
}

class SearchSuccess extends SearchState {
  final List<dynamic> results;
  final Map<String, dynamic> uiTranslations; // Добавили и сюда для консистентности UI

  const SearchSuccess(this.results, {required this.uiTranslations});

  @override
  List<Object?> get props => [results, uiTranslations];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}