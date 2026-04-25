import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/models/filter_model.dart'; 

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;
  
  // Внутренняя память BLoC для синхронизации запросов
  String _currentLocale; 
  String _activeCategory = '';
  Map<String, dynamic> _selectedValues = {}; 

  String get currentLocale => _currentLocale;

  SearchBloc({required this.repository, required String initialLocale}) 
      : _currentLocale = initialLocale, 
        super(SearchInitial(currentLocale: initialLocale)) {
    
    // 1. ЗАГРУЗКА ФИЛЬТРОВ И ИНИЦИАЛИЗАЦИЯ
    on<LoadFilters>((event, emit) async {
      final String targetLocale = event.locale.isNotEmpty ? event.locale : _currentLocale;
      _activeCategory = event.category;
      _selectedValues = {}; // Очищаем память фильтров при смене категории

      emit(SearchLoading(uiTranslations: _extractTranslations(state)));

      try {
        final data = await repository.getFiltersData(category: _activeCategory, locale: targetLocale);
        
        _currentLocale = data['translations']['locale_code']?.toString() ?? targetLocale;

        // При первичной загрузке фильтров нет
        final results = await repository.search(category: _activeCategory, filters: const {}, locale: _currentLocale);

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: _activeCategory,
          results: results,
          selectedValues: _selectedValues,
          currentLocale: _currentLocale,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: targetLocale, uiTranslations: _extractTranslations(state)));
      }
    });

    // 2. СМЕНА ЛОКАЛИ
    on<ChangeLocale>((event, emit) {
      _currentLocale = event.locale;
      add(LoadFilters(category: _activeCategory.isNotEmpty ? _activeCategory : 'people', locale: _currentLocale));
    });

    // 3. ОБНОВЛЕНИЕ ЗНАЧЕНИЙ ФИЛЬТРОВ
    on<UpdateFilterValue>((event, emit) {
      _selectedValues = Map<String, dynamic>.from(_selectedValues);
      _selectedValues[event.filterId] = event.value;

      if (state is FiltersLoaded) {
        final s = state as FiltersLoaded;
        emit(s.copyWith(selectedValues: _selectedValues));
      } 
      else if (state is SearchSuccess) {
        final s = state as SearchSuccess;
        emit(s.copyWith(selectedValues: _selectedValues));
      }
      else if (state is ResultsLoading) {
        final s = state as ResultsLoading;
        emit(s.copyWith(selectedValues: _selectedValues));
      }
    });
  
    // 4. ВЫПОЛНЕНИЕ ПОИСКА
    on<PerformSearch>((event, emit) async {
      final s = state;
      if (s is FiltersLoaded || s is SearchSuccess) {
        final translations = _extractTranslations(s);
        final filters = (s is FiltersLoaded) ? s.filters : (s as SearchSuccess).filters;
        final category = _activeCategory.isNotEmpty ? _activeCategory : 'people';

        emit(ResultsLoading(
          currentLocale: _currentLocale, 
          uiTranslations: translations,
          filters: filters,
          selectedValues: _selectedValues, 
          results: (s is FiltersLoaded) ? s.results : (s as SearchSuccess).results,
        ));

        try {
          final results = await repository.search(
            category: category, 
            filters: _selectedValues, 
            locale: _currentLocale
          );

          emit(SearchSuccess(
            results, 
            currentLocale: _currentLocale, 
            uiTranslations: translations,
            filters: filters,
            selectedValues: _selectedValues,
          ));
        } catch (e) {
          emit(SearchError(e.toString(), currentLocale: _currentLocale, uiTranslations: translations));
        }
      }
    });
    
    // 5. СМЕНА ТАБОВ
    on<ChangeTab>((event, emit) {
      final s = state;
      if (s is FiltersLoaded) emit(s.copyWith(tabIndex: event.index));
      if (s is SearchSuccess) emit(s.copyWith(tabIndex: event.index));
    });

    // 6. ЗАГРУЗКА ДЕТАЛЕЙ ПОСТА
    on<LoadPostDetails>((event, emit) async {
      List<dynamic> currentResults = [];
      List<FilterModel> currentFilters = [];
      
      if (state is FiltersLoaded) {
        currentResults = (state as FiltersLoaded).results;
        currentFilters = (state as FiltersLoaded).filters;
      } else if (state is SearchSuccess) {
        currentResults = (state as SearchSuccess).results;
        currentFilters = (state as SearchSuccess).filters;
      }

      emit(PostDetailsLoading(currentLocale: event.locale, uiTranslations: _extractTranslations(state)));

      try {
        final data = await repository.getPostDetails(
          id: event.id, 
          category: event.category, 
          locale: event.locale
        );
        
        emit(PostDetailsLoaded(
          currentLocale: event.locale, 
          post: data['record'],
          uiTranslations: data['translations'],
          searchResults: currentResults,
          filters: currentFilters,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: event.locale, uiTranslations: _extractTranslations(state)));
      }
    });

    // 7. ВОССТАНОВЛЕНИЕ ПОИСКА (Теперь находится ПРАВИЛЬНО, внутри конструктора)
    on<RestoreSearch>((event, emit) {
      if (state is PostDetailsLoaded) {
        final s = state as PostDetailsLoaded;
        emit(SearchSuccess(
          s.searchResults,
          currentLocale: _currentLocale,
          uiTranslations: s.uiTranslations,
          filters: s.filters,
          selectedValues: _selectedValues, // Восстанавливаем из внутренней памяти BLoC
        ));
      }
    });

  } // <--- ВОТ ЗДЕСЬ ЗАКРЫВАЕТСЯ КОНСТРУКТОР

  // Хелпер для переводов
  Map<String, dynamic> _extractTranslations(SearchState state) {
    if (state is FiltersLoaded) return state.uiTranslations;
    if (state is SearchSuccess) return state.uiTranslations;
    if (state is ResultsLoading) return state.uiTranslations;
    if (state is SearchLoading) return state.uiTranslations;
    if (state is PostDetailsLoaded) return state.uiTranslations;
    if (state is PostDetailsLoading) return state.uiTranslations;
    if (state is SearchError) return state.uiTranslations;
    return {};
  }
}