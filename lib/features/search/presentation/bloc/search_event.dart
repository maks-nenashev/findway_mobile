abstract class SearchEvent {
  const SearchEvent();
}

class LoadFilters extends SearchEvent {
  final String category;
  const LoadFilters({required this.category}); 
}

class UpdateFilterValue extends SearchEvent {
  final String filterId; 
  final dynamic value;   

  const UpdateFilterValue({required this.filterId, required this.value});
}

class PerformSearch extends SearchEvent {
  const PerformSearch();
}