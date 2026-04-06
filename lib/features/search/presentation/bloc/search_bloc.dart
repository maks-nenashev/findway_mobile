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
    
    // 1. Завантаження фільтрів
    on<LoadFilters>((event, emit) async {
      // Захист: не перезаписуємо локаль, якщо прийшов порожній рядок
      if (event.locale.isNotEmpty) _currentLocale = event.locale;
      
      emit(SearchLoading());
      
      try {
        final data = await repository.getFiltersData(
          category: event.category,
          locale: _currentLocale,
        );

        final initialResults = await repository.search(
          category: event.category,
          filters: const {},
          locale: _currentLocale,
        );

        emit(FiltersLoaded(
          tabIndex: 1, // Дефолтна вкладка пошуку
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

    // 2. Зміна локалі (Quiet Reload — щоб UI не "блимав")
    on<ChangeLocale>((event, emit) async {
      _currentLocale = event.locale; 

      int currentTab = 1;
      String currentCategory = 'people';
      Map<String, dynamic> lastFilters = {};
      List<dynamic> lastResults = [];

      // Зберігаємо поточний контекст
      if (state is FiltersLoaded) {
        final s = state as FiltersLoaded;
        currentTab = s.tabIndex;
        currentCategory = s.currentCategory;
        lastFilters = s.selectedValues;
        lastResults = s.results;
      } else if (state is SearchSuccess) {
        final s = state as SearchSuccess;
        currentTab = s.tabIndex;
        lastFilters = s.selectedValues;
        lastResults = s.results;
      }

      // Використовуємо ResultsLoading замість SearchLoading, 
      // щоб зберегти переклади та BottomNavBar на екрані під час запиту
      emit(ResultsLoading(
        tabIndex: currentTab,
        filters: (state is FiltersLoaded) ? (state as FiltersLoaded).filters : [],
        selectedValues: lastFilters,
        uiTranslations: (state is FiltersLoaded) ? (state as FiltersLoaded).uiTranslations : (state is SearchSuccess ? (state as SearchSuccess).uiTranslations : {}),
        results: lastResults,
      ));
      
      try {
        final data = await repository.getFiltersData(
          category: currentCategory,
          locale: _currentLocale,
        );

        final results = await repository.search(
          category: currentCategory,
          filters: lastFilters,
          locale: _currentLocale,
        );

        emit(FiltersLoaded(
          tabIndex: currentTab,
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: currentCategory,
          selectedValues: lastFilters, 
          currentLocale: _currentLocale,
          results: results,
        ));
      } catch (e) {
        emit(SearchError(e.toString()));
      }
    });

    // 3. Оновлення значень фільтрів
    on<UpdateFilterValue>((event, emit) {
      if (state is FiltersLoaded) {
        final s = state as FiltersLoaded;
        final newValues = Map<String, dynamic>.from(s.selectedValues);
        newValues[event.filterId] = event.value;

        emit(s.copyWith(selectedValues: newValues));
      } else if (state is SearchSuccess) {
        final s = state as SearchSuccess;
        final newValues = Map<String, dynamic>.from(s.selectedValues);
        newValues[event.filterId] = event.value;

        emit(FiltersLoaded(
          tabIndex: s.tabIndex,
          filters: s.filters,
          selectedValues: newValues,
          uiTranslations: s.uiTranslations,
          currentCategory: 'people', 
          results: s.results,
          currentLocale: _currentLocale,
        ));
      }
    });
  
    // 4. Виконання пошуку
    on<PerformSearch>((event, emit) async {
      if (state is FiltersLoaded) {
        final s = state as FiltersLoaded;
        
        emit(ResultsLoading(
          tabIndex: s.tabIndex,
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
            tabIndex: s.tabIndex,
            uiTranslations: s.uiTranslations,
            filters: s.filters,
            selectedValues: s.selectedValues,
          ));
        } catch (e) {
          emit(SearchError(e.toString()));
        }
      }
    });
    
    // 5. Зміна вкладки (Tab Navigation)
    on<ChangeTab>((event, emit) {
      final s = state;
      if (s is FiltersLoaded) {
        emit(s.copyWith(tabIndex: event.index));
      } else if (s is SearchSuccess) {
        emit(s.copyWith(tabIndex: event.index));
      } else if (s is ResultsLoading) {
        emit(s.copyWith(tabIndex: event.index));
      }
    });

    // 6. Завантаження деталей поста
    on<LoadPostDetails>((event, emit) async {
      if (event.locale.isNotEmpty) _currentLocale = event.locale;
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