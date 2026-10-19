// =============================================================================
// FILE: lib/features/search/presentation/bloc/search_bloc.dart
// RESPONSIBILITY: BLoC поиска, объявления и пагинация Pagy.
// =============================================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/repositories/search_repository.dart';
import '../../data/models/filter_model.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository repository;

  String _currentLocale;
  String _activeCategory = '';

  Map<String, dynamic> _selectedValues = {};
  Map<String, dynamic> _translationsCache = {};

  List<dynamic> _cachedResults = [];
  List<FilterModel> _cachedFilters = [];

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCount = 0;

  String get currentLocale => _currentLocale;
  String get activeCategory => _activeCategory;
  Map<String, dynamic> get selectedValues => _selectedValues;

  SearchBloc({
    required this.repository,
    required String initialLocale,
  })  : _currentLocale = initialLocale,
        super(SearchInitial(currentLocale: initialLocale)) {
    on<LoadFilters>(_onLoadFilters);
    on<ChangeLocale>(_onChangeLocale);
    on<UpdateFilterValue>(_onUpdateFilterValue);
    on<SearchFilterChanged>(_onSearchFilterChanged);
    on<UpdatePost>(_onUpdatePost);
    on<PerformSearch>(_onPerformSearch);
    on<ChangeTab>(_onChangeTab);
    on<LoadPostDetails>(_onLoadPostDetails);
    on<RestoreSearch>(_onRestoreSearch);
    on<CreatePost>(_onCreatePost);
    on<DeletePost>(_onDeletePost);
    on<ChangePage>(_onChangePage);
  }

  // ===========================================================================
  // LOAD FILTERS
  // ===========================================================================

  Future<void> _onLoadFilters(
    LoadFilters event,
    Emitter<SearchState> emit,
  ) async {
    final targetLocale =
        event.locale.isNotEmpty ? event.locale : _currentLocale;

    _activeCategory = event.category;
    _selectedValues = {};
    _currentPage = 1;

    // 🛡 СИНХРОНИЗАЦИЯ ЛОКАЛИ: Фиксируем выбранный язык в SharedPreferences
    await di.sl<di.LocaleRepository>().setLocale(targetLocale);

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

      _translationsCache = {
        ..._translationsCache,
        ...incoming,
      };

      final searchResponse = await _executeSearch(
        category: _activeCategory,
        filters: _selectedValues,
        locale: _currentLocale,
      );

      _cachedFilters =
          (data['filters'] as List?)?.cast<FilterModel>() ?? [];

      _cachedResults = searchResponse.results;
      _currentPage = searchResponse.currentPage;
      _lastPage = searchResponse.lastPage;
      _totalCount = searchResponse.totalCount;

      emit(
        FiltersLoaded(
          filters: _cachedFilters,
          uiTranslations: _translationsCache,
          currentCategory: _activeCategory,
          results: _cachedResults,
          selectedValues: _selectedValues,
          currentLocale: _currentLocale,

          // ВАЖНО: без этих полей UI показывал 1 / 1 и Total: 0.
          currentPage: _currentPage,
          lastPage: _lastPage,
          totalCount: _totalCount,
        ),
      );
    } catch (e) {
      emit(
        SearchError(
          e.toString(),
          currentLocale: targetLocale,
          uiTranslations: _translationsCache,
        ),
      );
    }
  }

  // ===========================================================================
  // CHANGE LOCALE
  // ===========================================================================

  Future<void> _onChangeLocale(
    ChangeLocale event,
    Emitter<SearchState> emit,
  ) async {
    _currentLocale = event.locale;

    // 🛡 СИНХРОНИЗАЦИЯ ЛОКАЛИ: Записываем в SharedPreferences при смене языка
    await di.sl<di.LocaleRepository>().setLocale(event.locale);

    add(
      LoadFilters(
        category:
            _activeCategory.isNotEmpty ? _activeCategory : 'people',
        locale: _currentLocale,
      ),
    );
  }

  // ===========================================================================
  // UPDATE FILTER VALUE
  // ===========================================================================

  void _onUpdateFilterValue(
    UpdateFilterValue event,
    Emitter<SearchState> emit,
  ) {
    _selectedValues = Map<String, dynamic>.from(_selectedValues);
    _selectedValues[event.filterId] = event.value;

    if (state is FiltersLoaded) {
      emit(
        (state as FiltersLoaded).copyWith(
          selectedValues: _selectedValues,
        ),
      );
    } else if (state is SearchSuccess) {
      emit(
        (state as SearchSuccess).copyWith(
          selectedValues: _selectedValues,
        ),
      );
    }

    if (event.filterId == 'sort' ||
        event.filterId == 'sort_by' ||
        event.filterId == 'order') {
      add(const PerformSearch());
    }
  }

  // ===========================================================================
  // SEARCH FILTER CHANGED
  // ===========================================================================

  void _onSearchFilterChanged(
    SearchFilterChanged event,
    Emitter<SearchState> emit,
  ) {
    _selectedValues = Map<String, dynamic>.from(_selectedValues);

    if (event.lat != null) {
      _selectedValues['search_lat'] = event.lat;
    }

    if (event.lng != null) {
      _selectedValues['search_lng'] = event.lng;
    }

    if (event.radiusKm != null) {
      _selectedValues['radius_km'] = event.radiusKm;
    }

    if (state is FiltersLoaded) {
      emit(
        (state as FiltersLoaded).copyWith(
          selectedValues: _selectedValues,
        ),
      );
    } else if (state is SearchSuccess) {
      emit(
        (state as SearchSuccess).copyWith(
          selectedValues: _selectedValues,
        ),
      );
    }

    add(const PerformSearch());
  }

  // ===========================================================================
  // UPDATE POST
  // ===========================================================================

  Future<void> _onUpdatePost(
    UpdatePost event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await repository.updatePost(
        postId: event.postId,
        category: event.category,
        title: event.title,
        text: event.text,
        localId: event.localId,
        choiceId: event.choiceId,
        catId: event.catId,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        animalMetadata: event.animalMetadata,
        thingMetadata: event.thingMetadata,
        locale: event.locale,
        existingImages: event.existingImages,
        newImagePaths: event.newImagePaths,
      );

      emit(const PostUpdateSuccess());
    } catch (e) {
      emit(PostUpdateError(e.toString()));
    }
  }

  // ===========================================================================
  // PERFORM SEARCH
  // ===========================================================================

  Future<void> _onPerformSearch(
    PerformSearch event,
    Emitter<SearchState> emit,
  ) async {
    _selectedValues['page'] = 1;
    _currentPage = 1;

    emit(
      ResultsLoading(
        currentLocale: _currentLocale,
        uiTranslations: _translationsCache,
        filters: _cachedFilters,
        selectedValues: _selectedValues,
        results: _cachedResults,
      ),
    );

    try {
      final searchResponse = await _executeSearch(
        category:
            _activeCategory.isNotEmpty ? _activeCategory : 'people',
        filters: _selectedValues,
        locale: _currentLocale,
      );

      _cachedResults = searchResponse.results;
      _currentPage = searchResponse.currentPage;
      _lastPage = searchResponse.lastPage;
      _totalCount = searchResponse.totalCount;

      emit(
        SearchSuccess(
          _cachedResults,
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
          filters: _cachedFilters,
          selectedValues: _selectedValues,
          currentPage: _currentPage,
          lastPage: _lastPage,
          totalCount: _totalCount,
        ),
      );
    } catch (e) {
      emit(
        SearchError(
          e.toString(),
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
        ),
      );
    }
  }

  // ===========================================================================
  // CHANGE TAB
  // ===========================================================================

  void _onChangeTab(
    ChangeTab event,
    Emitter<SearchState> emit,
  ) {
    final choiceId = event.index == 0 ? 1 : 2;

    _selectedValues['q[choice_id_eq]'] = choiceId;
    _selectedValues['page'] = 1;

    if (state is FiltersLoaded) {
      emit(
        (state as FiltersLoaded).copyWith(
          tabIndex: event.index,
          selectedValues: _selectedValues,
        ),
      );
    } else if (state is SearchSuccess) {
      emit(
        (state as SearchSuccess).copyWith(
          tabIndex: event.index,
          selectedValues: _selectedValues,
        ),
      );
    }

    add(const PerformSearch());
  }

  // ===========================================================================
  // LOAD POST DETAILS
  // ===========================================================================

  Future<void> _onLoadPostDetails(
    LoadPostDetails event,
    Emitter<SearchState> emit,
  ) async {
    emit(
      PostDetailsLoading(
        currentLocale: event.locale,
        uiTranslations: _translationsCache,
      ),
    );

    try {
      final data = await repository.getPostDetails(
        id: event.id,
        category: event.category,
        locale: event.locale,
      );

      final incoming =
          (data['translations'] ?? {}) as Map<String, dynamic>;

      _translationsCache = {
        ..._translationsCache,
        ...incoming,
      };

      emit(
        PostDetailsLoaded(
          currentLocale: event.locale,
          post: data['record'],
          uiTranslations: _translationsCache,
          searchResults: _cachedResults,
          filters: _cachedFilters,
        ),
      );
    } catch (e) {
      emit(
        SearchError(
          e.toString(),
          currentLocale: event.locale,
          uiTranslations: _translationsCache,
        ),
      );
    }
  }

  // ===========================================================================
  // RESTORE SEARCH
  // ===========================================================================

  void _onRestoreSearch(
    RestoreSearch event,
    Emitter<SearchState> emit,
  ) {
    emit(
      SearchSuccess(
        _cachedResults,
        currentLocale: _currentLocale,
        uiTranslations: _translationsCache,
        filters: _cachedFilters,
        selectedValues: _selectedValues,
        currentPage: _currentPage,
        lastPage: _lastPage,
        totalCount: _totalCount,
      ),
    );
  }

  // ===========================================================================
  // CREATE POST
  // ===========================================================================

  Future<void> _onCreatePost(
    CreatePost event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final result = await repository.createPost(
        category: event.category,
        title: event.title,
        text: event.text,
        localId: event.localId,
        choiceId: event.choiceId,
        catId: event.catId,
        latitude: event.latitude,
        longitude: event.longitude,
        address: event.address,
        animalMetadata: event.animalMetadata,
        thingMetadata: event.thingMetadata,
        locale: event.locale,
        imagePaths: event.imagePaths,
      );

      if (result['success'] == true) {
        emit(
          PostCreateSuccess(
            postId: result['id'],
            currentLocale: _currentLocale,
          ),
        );
      } else {
        emit(
          PostCreateError(
            error: (result['errors'] as List?)?.join(', ') ??
                'Creation failed',
            currentLocale: _currentLocale,
          ),
        );
      }
    } catch (e) {
      emit(
        PostCreateError(
          error: e.toString(),
          currentLocale: _currentLocale,
        ),
      );
    }
  }

  // ===========================================================================
  // DELETE POST
  // ===========================================================================

  Future<void> _onDeletePost(
    DeletePost event,
    Emitter<SearchState> emit,
  ) async {
    try {
      await repository.deletePost(event.postId, event.category);

      emit(
        PostDeleteSuccess(
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
        ),
      );
    } catch (e) {
      emit(
        SearchError(
          e.toString(),
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
        ),
      );
    }
  }

  // ===========================================================================
  // CHANGE PAGE
  // ===========================================================================

  Future<void> _onChangePage(
    ChangePage event,
    Emitter<SearchState> emit,
  ) async {
    _selectedValues = Map<String, dynamic>.from(_selectedValues);
    _selectedValues['page'] = event.page;

    emit(
      ResultsLoading(
        currentLocale: _currentLocale,
        uiTranslations: _translationsCache,
        filters: _cachedFilters,
        selectedValues: _selectedValues,
        results: _cachedResults,
      ),
    );

    try {
      final searchResponse = await _executeSearch(
        category:
            _activeCategory.isNotEmpty ? _activeCategory : 'people',
        filters: _selectedValues,
        locale: _currentLocale,
      );

      _cachedResults = searchResponse.results;
      _currentPage = searchResponse.currentPage;
      _lastPage = searchResponse.lastPage;
      _totalCount = searchResponse.totalCount;

      emit(
        SearchSuccess(
          _cachedResults,
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
          filters: _cachedFilters,
          selectedValues: _selectedValues,
          currentPage: _currentPage,
          lastPage: _lastPage,
          totalCount: _totalCount,
        ),
      );
    } catch (e) {
      emit(
        SearchError(
          e.toString(),
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
        ),
      );
    }
  }

  // ===========================================================================
  // SEARCH RESPONSE ADAPTER
  // ===========================================================================

  Future<_SearchResponseDTO> _executeSearch({
    required String category,
    required Map<String, dynamic> filters,
    required String locale,
  }) async {
    final dynamic rawResult = await repository.search(
      category: category,
      filters: filters,
      locale: locale,
    );

    if (rawResult is Map) {
      final resultsList =
          (rawResult['results'] ?? rawResult['records'] ?? []) as List<dynamic>;

      final pagination =
          (rawResult['pagination'] as Map?)?.cast<String, dynamic>() ?? {};

      return _SearchResponseDTO(
        results: resultsList,
        currentPage: int.tryParse(
              pagination['page']?.toString() ?? '1',
            ) ??
            1,
        lastPage: int.tryParse(
              pagination['last_page']?.toString() ??
                  pagination['pages']?.toString() ??
                  '1',
            ) ??
            1,
        totalCount: int.tryParse(
              (pagination['total'] ??
                      pagination['count'] ??
                      resultsList.length)
                  .toString(),
            ) ??
            resultsList.length,
      );
    }

    if (rawResult is List) {
      return _SearchResponseDTO(
        results: rawResult,
        currentPage:
            int.tryParse(filters['page']?.toString() ?? '1') ?? 1,
        lastPage: 1,
        totalCount: rawResult.length,
      );
    }

    return _SearchResponseDTO(
      results: [],
      currentPage: 1,
      lastPage: 1,
      totalCount: 0,
    );
  }
}

class _SearchResponseDTO {
  final List<dynamic> results;
  final int currentPage;
  final int lastPage;
  final int totalCount;

  const _SearchResponseDTO({
    required this.results,
    required this.currentPage,
    required this.lastPage,
    required this.totalCount,
  });
}