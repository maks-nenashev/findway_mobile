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