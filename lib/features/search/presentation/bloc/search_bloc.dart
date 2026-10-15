// =============================================================================
// FILE: lib/features/search/presentation/bloc/search_bloc.dart
// RESPONSIBILITY: BLoC поиска и управление CUD-операциями объявлений
//                 с пробросом animalMetadata, thingMetadata и GPS-геолокации.
// =============================================================================

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
  Map<String, dynamic> _translationsCache = {};

  // ===========================================================================
  // 🛡 КЭШ (БРОНЯ): Сохраняем результаты и фильтры между переходами по экранам
  // ===========================================================================
  List<dynamic> _cachedResults = [];
  List<FilterModel> _cachedFilters = [];

  String get currentLocale => _currentLocale;
  String get activeCategory => _activeCategory;
  Map<String, dynamic> get selectedValues => _selectedValues;

  SearchBloc({
    required this.repository,
    required String initialLocale,
  })  : _currentLocale = initialLocale,
        super(SearchInitial(currentLocale: initialLocale)) {

    // =========================================================================
    // LOAD FILTERS (Загрузка фильтров и переводов категории)
    // =========================================================================
    on<LoadFilters>((event, emit) async {
      final targetLocale = event.locale.isNotEmpty ? event.locale : _currentLocale;
      _activeCategory = event.category;
      _selectedValues = {};

      emit(SearchLoading(uiTranslations: _translationsCache));

      try {
        final data = await repository.getFiltersData(category: _activeCategory, locale: targetLocale);
        final incoming = (data['translations'] ?? {}) as Map<String, dynamic>;
        _currentLocale = incoming['locale_code']?.toString() ?? targetLocale;

        _translationsCache = { ..._translationsCache, ...incoming };

        final results = await repository.search(category: _activeCategory, filters: const {}, locale: _currentLocale);

        // Обновление кэша
        _cachedFilters = data['filters'];
        _cachedResults = results;

        emit(FiltersLoaded(
          filters: _cachedFilters,
          uiTranslations: _translationsCache,
          currentCategory: _activeCategory,
          results: _cachedResults,
          selectedValues: _selectedValues,
          currentLocale: _currentLocale,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: targetLocale, uiTranslations: _translationsCache));
      }
    });

    // =========================================================================
    // CHANGE LOCALE (Смена языка)
    // =========================================================================
    on<ChangeLocale>((event, emit) {
      _currentLocale = event.locale;
      add(LoadFilters(
        category: _activeCategory.isNotEmpty ? _activeCategory : 'people',
        locale: _currentLocale,
      ));
    });

    // =========================================================================
    // UPDATE FILTER VALUE (Изменение отдельных значений фильтра)
    // =========================================================================
    on<UpdateFilterValue>((event, emit) {
      _selectedValues = Map<String, dynamic>.from(_selectedValues);
      _selectedValues[event.filterId] = event.value;

      if (state is FiltersLoaded) {
        emit((state as FiltersLoaded).copyWith(selectedValues: _selectedValues));
      } else if (state is SearchSuccess) {
        emit((state as SearchSuccess).copyWith(selectedValues: _selectedValues));
      }

      // Если изменён параметр сортировки, сразу перезапускаем поиск на бэкенде
      if (event.filterId == 'sort' || event.filterId == 'sort_by' || event.filterId == 'order') {
        add(const PerformSearch());
      }
    });

    // =========================================================================
    // SEARCH FILTER CHANGED (Обновление GPS-координат lat/lng и радиуса поиска)
    // =========================================================================
    on<SearchFilterChanged>((event, emit) {
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
        emit((state as FiltersLoaded).copyWith(selectedValues: _selectedValues));
      } else if (state is SearchSuccess) {
        emit((state as SearchSuccess).copyWith(selectedValues: _selectedValues));
      }

      // Перезапускаем поиск для получения объектов вокруг полученной точки GPS
      add(const PerformSearch());
    });

    // =========================================================================
    // UPDATE POST (Редактирование с учетом геолокации, animalMetadata и thingMetadata)
    // =========================================================================
    on<UpdatePost>((event, emit) async {
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
          thingMetadata: event.thingMetadata, // 👉 Проброс метаданных вещей
          locale: event.locale,
          existingImages: event.existingImages,
          newImagePaths: event.newImagePaths,
        );
        emit(const PostUpdateSuccess());
      } catch (e) {
        emit(PostUpdateError(e.toString()));
      }
    });

    // =========================================================================
    // PERFORM SEARCH (Запуск поиска)
    // =========================================================================
    on<PerformSearch>((event, emit) async {
      emit(ResultsLoading(
        currentLocale: _currentLocale,
        uiTranslations: _translationsCache,
        filters: _cachedFilters,
        selectedValues: _selectedValues,
        results: _cachedResults,
      ));

      try {
        final results = await repository.search(
          category: _activeCategory.isNotEmpty ? _activeCategory : 'people',
          filters: _selectedValues,
          locale: _currentLocale,
        );
        
        _cachedResults = results;

        emit(SearchSuccess(
          _cachedResults,
          currentLocale: _currentLocale,
          uiTranslations: _translationsCache,
          filters: _cachedFilters,
          selectedValues: _selectedValues,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: _currentLocale, uiTranslations: _translationsCache));
      }
    });

    // =========================================================================
    // CHANGE TAB (Переключение вкладок "Пошук" / "Знайдено")
    // =========================================================================
    on<ChangeTab>((event, emit) {
      final choiceId = event.index == 0 ? 1 : 2; 
      _selectedValues['q[choice_id_eq]'] = choiceId;

      if (state is FiltersLoaded) {
        emit((state as FiltersLoaded).copyWith(
          tabIndex: event.index,
          selectedValues: _selectedValues,
        ));
      } else if (state is SearchSuccess) {
        emit((state as SearchSuccess).copyWith(
          tabIndex: event.index,
          selectedValues: _selectedValues,
        ));
      }

      add(const PerformSearch());
    });

    // =========================================================================
    // LOAD POST DETAILS (Детальный просмотр)
    // =========================================================================
    on<LoadPostDetails>((event, emit) async {
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

        final incoming = (data['translations'] ?? {}) as Map<String, dynamic>;
        _translationsCache = { ..._translationsCache, ...incoming };

        emit(PostDetailsLoaded(
          currentLocale: event.locale,
          post: data['record'],
          uiTranslations: _translationsCache,
          searchResults: _cachedResults, 
          filters: _cachedFilters,
        ));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: event.locale, uiTranslations: _translationsCache));
      }
    });

    // =========================================================================
    // RESTORE SEARCH (Восстановление состояния поиска из кэша)
    // =========================================================================
    on<RestoreSearch>((event, emit) {
      emit(SearchSuccess(
        _cachedResults,
        currentLocale: _currentLocale,
        uiTranslations: _translationsCache,
        filters: _cachedFilters,
        selectedValues: _selectedValues,
      ));
    });

    // =========================================================================
    // CREATE POST (Создание поста с координатами, animalMetadata и thingMetadata)
    // =========================================================================
    on<CreatePost>((event, emit) async {
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
          thingMetadata: event.thingMetadata, // 👉 Проброс метаданных вещей
          locale: event.locale,
          imagePaths: event.imagePaths,
        );

        if (result['success'] == true) {
          emit(PostCreateSuccess(postId: result['id'], currentLocale: _currentLocale));
        } else {
          emit(PostCreateError(
            error: (result['errors'] as List?)?.join(', ') ?? 'Creation failed', 
            currentLocale: _currentLocale,
          ));
        }
      } catch (e) {
        emit(PostCreateError(error: e.toString(), currentLocale: _currentLocale));
      }
    });

    // =========================================================================
    // DELETE POST (Удаление поста)
    // =========================================================================
    on<DeletePost>((event, emit) async {
      try {
        await repository.deletePost(event.postId, event.category);
        emit(PostDeleteSuccess(currentLocale: _currentLocale, uiTranslations: _translationsCache));
      } catch (e) {
        emit(SearchError(e.toString(), currentLocale: _currentLocale, uiTranslations: _translationsCache));
      }
    });
  }
}