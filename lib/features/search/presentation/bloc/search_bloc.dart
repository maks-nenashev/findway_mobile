import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/models/filter_model.dart'; 

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;
  String _currentLocale = ''; 

  String get currentLocale => _currentLocale;

  SearchBloc({required this.repository, required String initialLocale}) 
      : _currentLocale = initialLocale, 
        super(SearchInitial(currentLocale: initialLocale)) { // 👈 Теперь Initial уже с языком!
    
    on<LoadFilters>((event, emit) async {
      // Используем переданную локаль сразу, не дожидаясь ответа сервера
      final String targetLocale = event.locale.isNotEmpty ? event.locale : _currentLocale;

      emit(SearchLoading(uiTranslations: _extractTranslations(state)));

      try {
        final data = await repository.getFiltersData(category: event.category, locale: targetLocale);
        
        // СИНХРОНИЗАЦИЯ: Берем то, что реально прислал сервер (GeoIP)
        _currentLocale = data['translations']['locale_code']?.toString() ?? targetLocale;

        final results = await repository.search(category: event.category, filters: const {}, locale: _currentLocale);

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: data['translations'],
          currentCategory: event.category,
          results: results,
          selectedValues: const {},
          currentLocale: _currentLocale,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: targetLocale, uiTranslations: _extractTranslations(state)));
      }
    });

    // 2. Смена локали пользователем
    on<ChangeLocale>((event, emit) {
      _currentLocale = event.locale;
      add(LoadFilters(category: 'people', locale: _currentLocale));
    });

    // 3. Обновление значений фильтров в UI
    on<UpdateFilterValue>((event, emit) {
      if (state is FiltersLoaded) {
        final s = state as FiltersLoaded;
        final newValues = Map<String, dynamic>.from(s.selectedValues);
        newValues[event.filterId] = event.value;
        emit(s.copyWith(selectedValues: newValues));
      }
    });
  
    // 4. Выполнение поиска (только один обработчик)
    on<PerformSearch>((event, emit) async {
      final s = state;
      if (s is FiltersLoaded || s is SearchSuccess) {
        // Извлекаем текущие данные для сохранения UI при загрузке
        final translations = _extractTranslations(s);
        final filters = (s is FiltersLoaded) ? s.filters : (s as SearchSuccess).filters;
        final selected = (s is FiltersLoaded) ? s.selectedValues : (s as SearchSuccess).selectedValues;
        final category = (s is FiltersLoaded) ? s.currentCategory : 'people';

        emit(ResultsLoading(
          currentLocale: _currentLocale, 
          uiTranslations: translations,
          filters: filters,
          selectedValues: selected,
          results: (s is FiltersLoaded) ? s.results : (s as SearchSuccess).results,
        ));

        try {
          final results = await repository.search(
            category: category, 
            filters: selected, 
            locale: _currentLocale
          );

          emit(SearchSuccess(
            results, 
            currentLocale: _currentLocale, 
            uiTranslations: translations,
            filters: filters,
            selectedValues: selected,
          ));
        } catch (e) {
          emit(SearchError(e.toString(), currentLocale: _currentLocale, uiTranslations: translations));
        }
      }
    });
    
    // 5. Переключение табов в NavBar
    on<ChangeTab>((event, emit) {
      final s = state;
      if (s is FiltersLoaded) emit(s.copyWith(tabIndex: event.index));
      if (s is SearchSuccess) emit(s.copyWith(tabIndex: event.index));
    });

    // 6. Загрузка деталей поста с сохранением контекста поиска
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

      emit(PostDetailsLoading(currentLocale: _currentLocale, uiTranslations: _extractTranslations(state)));

      try {
        final data = await repository.getPostDetails(id: event.id, category: event.category, locale: _currentLocale);
        
        emit(PostDetailsLoaded(
          currentLocale: _currentLocale,
          post: data['record'],
          uiTranslations: data['translations'],
          searchResults: currentResults,
          filters: currentFilters,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: _currentLocale, uiTranslations: _extractTranslations(state)));
      }
    });
  } // Конец конструктора

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