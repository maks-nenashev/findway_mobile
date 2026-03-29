import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/repositories/search_repository.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    
    on<LoadFilters>((event, emit) async {
      emit(SearchLoading());
      try {
        final filters = await repository.getFilters(
          category: event.category,
          locale: 'uk', 
        );
        // Сброс Map при смене категории — защита от некорректных данных
        emit(FiltersLoaded(
          filters: filters, 
          currentCategory: event.category,
          selectedValues: const {},
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });

    on<UpdateFilterValue>((event, emit) {
      if (state is FiltersLoaded) {
        final currentState = state as FiltersLoaded;
        final newValues = Map<String, dynamic>.from(currentState.selectedValues);
        newValues[event.filterId] = event.value;

        emit(FiltersLoaded(
          filters: currentState.filters,
          currentCategory: currentState.currentCategory,
          selectedValues: newValues,
        ));
      }
    });
  
  on<PerformSearch>((event, emit) async {
  if (state is FiltersLoaded) {
    final currentState = state as FiltersLoaded;
    final filters = currentState.selectedValues;
    final category = currentState.currentCategory;

    emit(ResultsLoading());

    try {
      // Вызываем репозиторий, передавая карту фильтров
      final results = await repository.search(
        category: category,
        filters: filters,
        locale: 'uk',
      );
      emit(SearchSuccess(results));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
});
}
}