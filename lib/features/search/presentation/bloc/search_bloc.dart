import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/models/filter_model.dart'; 

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;
  
  String _currentLocale; 
  String _activeCategory = '';
  Map<String, dynamic> _selectedValues = {}; 

  String get currentLocale => _currentLocale;

  SearchBloc({required this.repository, required String initialLocale}) 
      : _currentLocale = initialLocale, 
        super(SearchInitial(currentLocale: initialLocale)) {
    
    on<LoadFilters>((event, emit) async {
      final String targetLocale = event.locale.isNotEmpty ? event.locale : _currentLocale;
      _activeCategory = event.category;
      _selectedValues = {};

      emit(SearchLoading(uiTranslations: _extractTranslations(state)));

      try {
        final data = await repository.getFiltersData(category: _activeCategory, locale: targetLocale);
        _currentLocale = data['translations']['locale_code']?.toString() ?? targetLocale;
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

    on<ChangeLocale>((event, emit) {
      _currentLocale = event.locale;
      add(LoadFilters(category: _activeCategory.isNotEmpty ? _activeCategory : 'people', locale: _currentLocale));
    });

    on<UpdateFilterValue>((event, emit) {
      _selectedValues = Map<String, dynamic>.from(_selectedValues);
      _selectedValues[event.filterId] = event.value;

      if (state is FiltersLoaded) {
        emit((state as FiltersLoaded).copyWith(selectedValues: _selectedValues));
      } else if (state is SearchSuccess) {
        emit((state as SearchSuccess).copyWith(selectedValues: _selectedValues));
      }
    });
  
    on<PerformSearch>((event, emit) async {
      final s = state;
      if (s is FiltersLoaded || s is SearchSuccess) {
        final translations = _extractTranslations(s);
        final filters = (s is FiltersLoaded) ? s.filters : (s as SearchSuccess).filters;
        
        emit(ResultsLoading(
          currentLocale: _currentLocale, 
          uiTranslations: translations,
          filters: filters,
          selectedValues: _selectedValues, 
          results: (s is FiltersLoaded) ? s.results : (s as SearchSuccess).results,
        ));

        try {
          final results = await repository.search(
            category: _activeCategory.isNotEmpty ? _activeCategory : 'people', 
            filters: _selectedValues, 
            locale: _currentLocale
          );

          emit(SearchSuccess(
            results, currentLocale: _currentLocale, 
            uiTranslations: translations, filters: filters, selectedValues: _selectedValues,
          ));
        } catch (e) {
          emit(SearchError(e.toString(), currentLocale: _currentLocale, uiTranslations: translations));
        }
      }
    });

    on<ChangeTab>((event, emit) {
      if (state is FiltersLoaded) emit((state as FiltersLoaded).copyWith(tabIndex: event.index));
      if (state is SearchSuccess) emit((state as SearchSuccess).copyWith(tabIndex: event.index));
    });

    on<LoadPostDetails>((event, emit) async {
      final s = state;
      List<dynamic> res = (s is FiltersLoaded) ? s.results : (s is SearchSuccess ? s.results : []);
      List<FilterModel> filt = (s is FiltersLoaded) ? s.filters : (s is SearchSuccess ? s.filters : []);

      emit(PostDetailsLoading(currentLocale: event.locale, uiTranslations: _extractTranslations(state)));

      try {
        final data = await repository.getPostDetails(id: event.id, category: event.category, locale: event.locale);
        emit(PostDetailsLoaded(
          currentLocale: event.locale, post: data['record'], uiTranslations: data['translations'],
          searchResults: res, filters: filt,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: event.locale, uiTranslations: _extractTranslations(state)));
      }
    });

    on<RestoreSearch>((event, emit) {
      if (state is PostDetailsLoaded) {
        final s = state as PostDetailsLoaded;
        emit(SearchSuccess(s.searchResults, currentLocale: _currentLocale, uiTranslations: s.uiTranslations, filters: s.filters, selectedValues: _selectedValues));
      }
    });

    // 👇 НОВАЯ ЛОГИКА СОЗДАНИЯ ПОСТА 👇
    on<CreatePost>((event, emit) async {
      final prevState = state; // Запоминаем текущее состояние (фильтры и т.д.)
      
      try {
        final result = await repository.createPost(
          category: event.category, title: event.title, text: event.text,
          localId: event.localId, choiceId: event.choiceId, catId: event.catId,
          locale: event.locale, imagePaths: event.imagePaths,
        );

        if (result['success'] == true) {
          emit(PostCreateSuccess(postId: result['id'], currentLocale: _currentLocale));
          // После успеха можно вернуть стейт фильтров, чтобы UI не ломался
          emit(prevState); 
        } else {
          emit(PostCreateError(error: (result['errors'] as List).join(', '), currentLocale: _currentLocale));
          emit(prevState);
        }
      } catch (e) {
        emit(PostCreateError(error: e.toString(), currentLocale: _currentLocale));
        emit(prevState);
      }
    });

  }

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