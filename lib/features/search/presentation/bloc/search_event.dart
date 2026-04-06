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