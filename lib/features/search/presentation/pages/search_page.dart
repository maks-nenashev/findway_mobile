import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/filter_builder.dart';
import 'search_details_page.dart';
import '../widgets/article_card.dart';
import '../widgets/locale_selector.dart';
// Модули комментариев
import '../../../../features/comments/presentation/bloc/comments_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_event.dart';
import '../../../../features/comments/presentation/bloc/comments_state.dart';
import '../../../../features/comments/data/models/comment_model.dart';

/// Главная страница поиска — отвечает за фильтрацию, поиск, локализацию и рендеринг результата.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Инициализация SearchBloc через DI-контейнер.
      create: (context) {
        final bloc = sl<SearchBloc>();
        // При первом создании всегда грузим стартовые фильтры (если только создан).
        if (bloc.state is SearchInitial) {
          bloc.add(const LoadFilters(category: 'people', locale: ''));
        }
        return bloc;
      },
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          // Экстракция переводов, локали и состояния результата из текущего state.
          final translations = _extractTranslations(state);
          final currentLocale = _extractLocale(context, state, translations);
          final searchResults = _extractResults(state);
          final filters = _extractFilters(state);
          final selectedFilterValues = _extractSelectedValues(state);
          final activeCategory = _extractCategory(state);
          final currentTabIndex = _extractTabIndex(state);

          return Scaffold(
            extendBody: true,
            backgroundColor: const Color(0xFFF0F4F8),
            appBar: _buildAppBar(translations, currentLocale, context),
            bottomNavigationBar: CustomBottomNavBar( 
              currentIndex: currentTabIndex,
              currentLocale: currentLocale,
              translations: translations,
              onTap: (index) => context.read<SearchBloc>().add(ChangeTab(index)),
            ),
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildFilterPanel(
                        context, state, translations, currentLocale,
                        filters, selectedFilterValues, activeCategory,
                      ),
                    ),
                    if (searchResults.isNotEmpty)
                      _buildResultsGrid(searchResults, currentLocale)
                    else if (state is! SearchLoading && state is! ResultsLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            translations['no_results'] ?? 'No results found',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
                // Индикаторы загрузки (общий и линейный для результатов)
                if (state is SearchLoading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF))),
                  ),
                if (state is ResultsLoading)
                  Positioned(
                    top: 0, left: 0, right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF00F2FF).withOpacity(0.5)),
                    ),
                  ),
              ],
            ),
          );     
        },       
      ),         
    );
  }

  /// Построение кастомного AppBar
  PreferredSizeWidget _buildAppBar(Map<String, dynamic> translations, String currentLocale, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        translations['page_title'] ?? 'FindWay',
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Orbitron', letterSpacing: 2),
      ),
      actions: const [], // селектор локали в NavBar, а не тут
    );
  }

  /// Фильтрационный блок (категории, поиск, фильтры)
  Widget _buildFilterPanel(BuildContext context, SearchState state, Map<String, dynamic> translations, String currentLocale, dynamic filters, Map<String, dynamic> selectedFilterValues, String activeCategory) {
    const Color darkSlate = Color(0xFF1E293B);
    const Color neonBlue = Color(0xFF00F2FF);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: darkSlate,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: darkSlate, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryButtons(context, activeCategory, translations, currentLocale),
            const SizedBox(height: 24),
            _buildSearchField(context, translations),
            const SizedBox(height: 16),
            if (filters != null) ...[
              Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 10),
                    floatingLabelStyle: const TextStyle(color: neonBlue, fontWeight: FontWeight.bold, fontSize: 16, height: 0.2),
                    labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkSlate)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: neonBlue, width: 2)),
                  ),
                ),
                child: FilterBuilder(
                  filters: filters,
                  selectedValues: selectedFilterValues,
                  currentCategory: activeCategory,
                  onFilterChanged: (id, val) => context.read<SearchBloc>().add(UpdateFilterValue(filterId: id, value: val)),
                ),
              ),
              const SizedBox(height: 16),
              _buildApplyFiltersButton(context, translations),
            ],
            if (state is SearchSuccess) _buildResetFiltersButton(context, currentLocale, translations),
          ],
        ),
      ),
    );
  }

  /// Поле поиска с кнопкой
  Widget _buildSearchField(BuildContext context, Map<String, dynamic> translations) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextField(
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: translations['plac_title'] ?? 'Пошук...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: ElevatedButton(
              onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
              child: Text(translations['find'] ?? 'FIND', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }

  /// Решётка с результатами поиска
  Widget _buildResultsGrid(List<dynamic> results, String currentLocale) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => ArticleCard(post: results[index], currentLocale: currentLocale),
          childCount: results.length,
        ),
      ),
    );
  }

  /// Кнопки категорий
  Widget _buildCategoryButtons(BuildContext context, String activeCategory, Map<String, dynamic> translations, String currentLocale) {
    return Row(
      children: [
        _categoryTab(context, 'people', translations['button_article'] ?? 'Люди', const Color(0xFF00F2FF), activeCategory == 'people', currentLocale),
        const SizedBox(width: 8),
        _categoryTab(context, 'animals', translations['button_sense'] ?? 'Тварини', const Color(0xFFFF8A00), activeCategory == 'animals', currentLocale),
        const SizedBox(width: 8),
        _categoryTab(context, 'things', translations['button_thing'] ?? 'Речі', const Color(0xFF2ECC71), activeCategory == 'things', currentLocale),
      ],
    );
  }

  Widget _categoryTab(BuildContext context, String cat, String label, Color color, bool isActive, String locale) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<SearchBloc>().add(LoadFilters(category: cat, locale: locale)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B), width: 2),
          ),
          child: Center(child: Text(label, style: TextStyle(color: isActive ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Orbitron'))),
        ),
      ),
    );
  }

  /// Кнопка применения фильтров (отправка поиска)
  Widget _buildApplyFiltersButton(BuildContext context, Map<String, dynamic> translations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
        icon: const Icon(Icons.filter_list),
        label: Text(translations['filter_button'] ?? "Застосувати фільтри"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A00).withOpacity(0.1),
          foregroundColor: const Color(0xFFFF8A00),
          side: const BorderSide(color: Color(0xFFFF8A00)),
        ),
      ),
    );
  }

  /// Кнопка сброса фильтров (отображается только для SearchSuccess)
  Widget _buildResetFiltersButton(BuildContext context, String currentLocale, Map<String, dynamic> translations) {
    return TextButton.icon(
      onPressed: () => context.read<SearchBloc>().add(LoadFilters(category: 'people', locale: currentLocale)),
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(translations['last'] ?? "Скинути фільтри"),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00F2FF)),
    );
  }

  // ==== МЕТОДЫ-ЭКСТРАКТОРЫ состояния SearchBloc ====

  Map<String, dynamic> _extractTranslations(SearchState state) {
    if (state is FiltersLoaded) return state.uiTranslations;
    if (state is SearchSuccess) return state.uiTranslations;
    if (state is ResultsLoading) return state.uiTranslations;
    return {};
  }

  String _extractLocale(BuildContext context, SearchState state, Map<String, dynamic> translations) {
    if (state is FiltersLoaded && state.currentLocale.isNotEmpty) return state.currentLocale;
    return translations['locale_code']?.toString() ?? '';
  }

  List<dynamic> _extractResults(SearchState state) {
    if (state is FiltersLoaded) return state.results;
    if (state is SearchSuccess) return state.results;
    if (state is ResultsLoading) return state.results;
    return [];
  }

  dynamic _extractFilters(SearchState state) {
    if (state is FiltersLoaded) return state.filters;
    if (state is ResultsLoading) return state.filters;
    if (state is SearchSuccess) return state.filters;
    return null;
  }

  Map<String, dynamic> _extractSelectedValues(SearchState state) {
    if (state is FiltersLoaded) return state.selectedValues;
    if (state is SearchSuccess) return state.selectedValues;
    if (state is ResultsLoading) return state.selectedValues;
    return {};
  }

  String _extractCategory(SearchState state) {
    if (state is FiltersLoaded) return state.currentCategory;
    return 'people';
  }

  int _extractTabIndex(SearchState state) {
    if (state is FiltersLoaded) return state.tabIndex;
    if (state is SearchSuccess) return state.tabIndex;
    if (state is ResultsLoading) return state.tabIndex;
    return 1; // По умолчанию выбирается Search
  }
}

/// Кастомная нижняя панель навигации с селектором локали
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String currentLocale; 
  final Function(int) onTap;
  final Map<String, dynamic> translations;

  const CustomBottomNavBar({
    required this.currentIndex,
    required this.currentLocale,
    required this.onTap,
    required this.translations,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Селектор локали
          LocaleSelector(currentLocale: currentLocale, isInNavBar: true), 
          // Навигационные кнопки
          _navItem(1, Icons.search, translations['nav_search'] ?? 'Search'),
          _navItem(2, Icons.favorite_border, translations['nav_likes'] ?? 'Likes'),
          _navItem(3, Icons.notifications_none, translations['nav_notif'] ?? 'Notif'),
          _navItem(4, Icons.person_outline, translations['nav_profile'] ?? 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFD81B60) : const Color(0xFF1E293B),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFD81B60) : const Color(0xFF1E293B),
              fontSize: 10,
              fontFamily: 'Orbitron'
            ),
          ),
        ],
      ),
    );
  }
}