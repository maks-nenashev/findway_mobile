import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/repositories/search_repository.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    
    // 1. Загрузка фильтров и переводов из YAML
    on<LoadFilters>((event, emit) async {
      final currentLocale = (state is FiltersLoaded) 
          ? (state as FiltersLoaded).currentLocale 
          : 'uk';

      emit(SearchLoading());
      try {
        // Репозиторий возвращает Map: {'filters': List<FilterModel>, 'translations': Map}
        final data = await repository.getFiltersData(
          category: event.category,
          locale: currentLocale,
        );

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: event.category,
          selectedValues: const {},
          currentLocale: currentLocale,
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });

    // 2. Смена локали (Полный сброс контекста)
    on<ChangeLocale>((event, emit) async {
      final category = (state is FiltersLoaded) 
          ? (state as FiltersLoaded).currentCategory 
          : 'people';

      emit(SearchLoading());
      try {
        final data = await repository.getFiltersData(
          category: category,
          locale: event.locale,
        );

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: category,
          selectedValues: const {}, // Risk Control: сброс обязателен
          currentLocale: event.locale,
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });

    // 3. Обновление значений фильтров (через copyWith)
    on<UpdateFilterValue>((event, emit) {
      if (state is FiltersLoaded) {
        final currentState = state as FiltersLoaded;
        final newValues = Map<String, dynamic>.from(currentState.selectedValues);
        newValues[event.filterId] = event.value;

        emit(currentState.copyWith(selectedValues: newValues));
      }
    });
  
    // 4. Поиск (Передача переводов в SearchSuccess)
    on<PerformSearch>((event, emit) async {
      if (state is FiltersLoaded) {
        final currentState = state as FiltersLoaded;
        
        emit(ResultsLoading());

        try {
          final results = await repository.search(
            category: currentState.currentCategory,
            filters: currentState.selectedValues,
            locale: currentState.currentLocale,
          );
          
          // Прокидываем uiTranslations дальше, чтобы экран результатов был локализован
          emit(SearchSuccess(
            results, 
            uiTranslations: currentState.uiTranslations
          ));
        } catch (e) {
          emit(SearchError(e.toString()));
        }
      }
    });
  }
}