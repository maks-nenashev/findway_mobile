import '../../data/models/filter_model.dart';

abstract class SearchState {
  const SearchState();
}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}

class FiltersLoaded extends SearchState {
  final List<FilterModel> filters;
  final Map<String, dynamic> selectedValues;
  final String currentCategory; 

  const FiltersLoaded({
    required this.filters,
    required this.currentCategory,
    this.selectedValues = const {},
  });
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
}

// Состояние загрузки результатов (можно переиспользовать SearchLoading или создать новое)
class ResultsLoading extends SearchState {}

class SearchSuccess extends SearchState {
  final List<dynamic> results; // Здесь будут твои модели сущностей
  const SearchSuccess(this.results);
}