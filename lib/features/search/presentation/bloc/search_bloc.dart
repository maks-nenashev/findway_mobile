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
      // Синхронизируем внутреннюю локаль, если она пришла в событии
      _currentLocale = event.locale;
      emit(SearchLoading());
      
      try {
        final data = await repository.getFiltersData(
          category: event.category,
          locale: _currentLocale,
        );

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: event.category,
          selectedValues: const {},
          currentLocale: _currentLocale, 
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

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: currentCategory,
          selectedValues: const {}, 
          currentLocale: _currentLocale,
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
      }
    });
  
    // 4. Поиск
    on<PerformSearch>((event, emit) async {
      if (state is FiltersLoaded) {
        final currentState = state as FiltersLoaded;
        emit(ResultsLoading());

        try {
          final results = await repository.search(
            category: currentState.currentCategory,
            filters: currentState.selectedValues,
            locale: _currentLocale,
          );
          
          emit(SearchSuccess(
            results, 
            uiTranslations: currentState.uiTranslations
          ));
        } catch (e) {
          emit(SearchError(e.toString()));
        }
      }
    });

    // 5. НОВОЕ: Загрузка деталей поста
    on<LoadPostDetails>((event, emit) async {
      // Обновляем локаль, чтобы она соответствовала контексту вызова
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