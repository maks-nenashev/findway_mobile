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

  // Глобальный кэш переводов (НЕ затирается)
  Map<String, dynamic> _translationsCache = {};

  String get currentLocale => _currentLocale;

  SearchBloc({
    required this.repository,
    required String initialLocale,
  })  : _currentLocale = initialLocale,
        super(SearchInitial(currentLocale: initialLocale)) {

    // ================= LOAD FILTERS =================
    on<LoadFilters>((event, emit) async {
      final targetLocale =
          event.locale.isNotEmpty ? event.locale : _currentLocale;

      _activeCategory = event.category;
      _selectedValues = {};

      emit(SearchLoading(uiTranslations: _translationsCache));

      try {
        final data = await repository.getFiltersData(
          category: _activeCategory,
          locale: targetLocale,
        );

        final incoming =
            (data['translations'] ?? {}) as Map<String, dynamic>;

        _currentLocale =
            incoming['locale_code']?.toString() ?? targetLocale;

        // merge переводов
        _translationsCache = {
          ..._translationsCache,
          ...incoming,
        };

        final results = await repository.search(
          category: _activeCategory,
          filters: const {},
          locale: _currentLocale,
        );

        emit(FiltersLoaded(
          filters: data['filters'],
          uiTranslations: _translationsCache,
          currentCategory: _activeCategory,
          results: results,
          selectedValues: _selectedValues,
          currentLocale: _currentLocale,
        ));
      } catch (e) {
        emit(SearchError(
          e.toString(),
          currentLocale: targetLocale,
          uiTranslations: _translationsCache,
        ));
      }
    });

    // ================= CHANGE LOCALE =================
    on<ChangeLocale>((event, emit) {
      _currentLocale = event.locale;

      add(LoadFilters(
        category: _activeCategory.isNotEmpty ? _activeCategory : 'people',
        locale: _currentLocale,
      ));
    });

    // ================= UPDATE FILTER =================
    on<UpdateFilterValue>((event, emit) {
      _selectedValues = Map<String, dynamic>.from(_selectedValues);
      _selectedValues[event.filterId] = event.value;

      if (state is FiltersLoaded) {
        emit((state as FiltersLoaded)
            .copyWith(selectedValues: _selectedValues));
      } else if (state is SearchSuccess) {
        emit((state as SearchSuccess)
            .copyWith(selectedValues: _selectedValues));
      }
    });

    // ================= SEARCH =================
    on<PerformSearch>((event, emit) async {
      final s = state;

      if (s is FiltersLoaded || s is SearchSuccess) {
        final List<FilterModel> filt = (s is FiltersLoaded)
            ? s.filters
            : (s as SearchSuccess).filters;

        emit(ResultsLoading(
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
          filters: filt,
          selectedValues: _selectedValues,
          results: (s is FiltersLoaded)
              ? s.results
              : (s as SearchSuccess).results,
        ));

        try {
          final results = await repository.search(
            category:
                _activeCategory.isNotEmpty ? _activeCategory : 'people',
            filters: _selectedValues,
            locale: _currentLocale,
          );

          emit(SearchSuccess(
            results,
            currentLocale: _currentLocale,
            uiTranslations: _translationsCache,
            filters: filt,
            selectedValues: _selectedValues,
          ));
        } catch (e) {
          emit(SearchError(
            e.toString(),
            currentLocale: _currentLocale,
            uiTranslations: _translationsCache,
          ));
        }
      }
    });

    // ================= TAB =================
    on<ChangeTab>((event, emit) {
      if (state is FiltersLoaded) {
        emit((state as FiltersLoaded).copyWith(tabIndex: event.index));
      } else if (state is SearchSuccess) {
        emit((state as SearchSuccess).copyWith(tabIndex: event.index));
      }
    });

    // ================= LOAD POST DETAILS =================
    on<LoadPostDetails>((event, emit) async {
      final s = state;

      final List<dynamic> res = (s is FiltersLoaded)
          ? s.results
          : (s is SearchSuccess ? s.results : []);

      final List<FilterModel> filt = (s is FiltersLoaded)
          ? s.filters
          : (s is SearchSuccess ? s.filters : <FilterModel>[]);

      emit(PostDetailsLoading(
        currentLocale: event.locale,
        uiTranslations: _translationsCache,
      ));

      try {
        final data = await repository.getPostDetails(
          id: event.id,
          category: event.category,
          locale: event.locale,
        );

        final incoming =
            (data['translations'] ?? {}) as Map<String, dynamic>;

        // merge переводов
        _translationsCache = {
          ..._translationsCache,
          ...incoming,
        };

        emit(PostDetailsLoaded(
          currentLocale: event.locale,
          post: data['record'],
          uiTranslations: _translationsCache,
          searchResults: res,
          filters: filt,
        ));
      } catch (e) {
        emit(SearchError(
          e.toString(),
          currentLocale: event.locale,
          uiTranslations: _translationsCache,
        ));
      }
    });

    // ================= RESTORE =================
    on<RestoreSearch>((event, emit) {
      if (state is PostDetailsLoaded) {
        final s = state as PostDetailsLoaded;

        emit(SearchSuccess(
          s.searchResults,
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
          filters: s.filters,
          selectedValues: _selectedValues,
        ));
      }
    });

    // ================= CREATE POST =================
    on<CreatePost>((event, emit) async {
      try {
        final result = await repository.createPost(
          category: event.category,
          title: event.title,
          text: event.text,
          localId: event.localId,
          choiceId: event.choiceId,
          catId: event.catId,
          locale: event.locale,
          imagePaths: event.imagePaths,
        );

        if (result['success'] == true) {
          emit(PostCreateSuccess(
            postId: result['id'],
            currentLocale: _currentLocale,
          ));
        } else {
          emit(PostCreateError(
            error: (result['errors'] as List).join(', '),
            currentLocale: _currentLocale,
          ));
        }
      } catch (e) {
        emit(PostCreateError(
          error: e.toString(),
          currentLocale: _currentLocale,
        ));
      }
    });

    // ================= DELETE =================
    on<DeletePost>((event, emit) async {
      try {
        await repository.deletePost(event.postId, event.category);

        emit(PostDeleteSuccess(
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
        ));
      } catch (e) {
        emit(SearchError(
          e.toString(),
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
        ));
      }
    });
  }
}