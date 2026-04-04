import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/repositories/search_repository.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;
  
  // Single Source of Truth для локали внутри этого Блока
  String _currentLocale = 'uk'; 

  SearchBloc({required this.repository}) : super(SearchInitial()) {
    
    // 1. Загрузка фильтров
    on<LoadFilters>((event, emit) async {
      _currentLocale = event.locale;
      emit(SearchLoading());
      
      try {
        final data = await repository.getFiltersData(
          category: event.category,
          locale: _currentLocale,
        );

        // Сразу загружаем объявления, чтобы они были видны всегда
        final initialResults = await repository.search(
          category: event.category,
          filters: const {},
          locale: _currentLocale,
        );

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: event.category,
          selectedValues: const {},
          currentLocale: _currentLocale,
          results: initialResults, 
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });

    // 2. Смена локали
    on<ChangeLocale>((event, emit) async {
      _currentLocale = event.locale; 

      final String currentCategory = (state is FiltersLoaded) 
          ? (state as FiltersLoaded).currentCategory 
          : 'people';

      emit(SearchLoading());
      
      try {
        final data = await repository.getFiltersData(
          category: currentCategory,
          locale: _currentLocale,
        );

        final results = await repository.search(
          category: currentCategory,
          filters: const {},
          locale: _currentLocale,
        );

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: currentCategory,
          selectedValues: const {}, 
          currentLocale: _currentLocale,
          results: results,
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });

    // 3. Обновление значений фильтров
    on<UpdateFilterValue>((event, emit) {
      if (state is FiltersLoaded) {
        final currentState = state as FiltersLoaded;
        final newValues = Map<String, dynamic>.from(currentState.selectedValues);
        newValues[event.filterId] = event.value;

        emit(currentState.copyWith(selectedValues: newValues));
      } else if (state is SearchSuccess) {
        final currentState = state as SearchSuccess;
        final newValues = Map<String, dynamic>.from(currentState.selectedValues);
        newValues[event.filterId] = event.value;

        // При изменении фильтра возвращаемся в FiltersLoaded для отображения изменений
        emit(FiltersLoaded(
          filters: currentState.filters,
          selectedValues: newValues,
          uiTranslations: currentState.uiTranslations,
          currentCategory: 'people', // В идеале хранить категорию в SearchSuccess
          results: currentState.results,
          currentLocale: _currentLocale,
        ));
      }
    });
  
    // 4. Поиск
    on<PerformSearch>((event, emit) async {
      List<dynamic> currentResults = [];
      Map<String, dynamic> currentFilters = {};
      dynamic currentMeta;
      Map<String, dynamic> currentTranslations = {};

      if (state is FiltersLoaded) {
        final s = state as FiltersLoaded;
        currentResults = s.results;
        currentFilters = s.selectedValues;
        currentMeta = s.filters;
        currentTranslations = s.uiTranslations;
        
        emit(ResultsLoading(
          filters: s.filters,
          selectedValues: s.selectedValues,
          uiTranslations: s.uiTranslations,
          results: s.results,
        ));

        try {
          final results = await repository.search(
            category: s.currentCategory,
            filters: s.selectedValues,
            locale: _currentLocale,
          );
          
          emit(SearchSuccess(
            results, 
            uiTranslations: s.uiTranslations,
            filters: s.filters,
            selectedValues: s.selectedValues,
          ));
        } catch (e) {
          emit(SearchError(e.toString()));
        }
      }
    });

    // 5. Загрузка деталей поста
    on<LoadPostDetails>((event, emit) async {
      _currentLocale = event.locale;
      emit(PostDetailsLoading());

      try {
        final data = await repository.getPostDetails(
          id: event.id,
          category: event.category,
          locale: _currentLocale,
        );

        emit(PostDetailsLoaded(
          post: data['record'],
          uiTranslations: data['translations'],
        ));
      } catch (e) {
        debugPrint('ERROR [LOAD POST DETAILS]: $e');
        emit(SearchError(e.toString()));
      }
    });
  }
}