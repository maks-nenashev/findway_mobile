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
// Импорты модуля комментариев
import '../../../../features/comments/presentation/bloc/comments_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_event.dart';
import '../../../../features/comments/presentation/bloc/comments_state.dart';
import '../../../../features/comments/data/models/comment_model.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<SearchBloc>();
        // Если блок только создан и стейт начальный — инициируем загрузку.
        // Локаль пустая, чтобы сервер определил её сам (GeoIP).
        if (bloc.state is SearchInitial) {
          bloc.add(const LoadFilters(category: 'people', locale: ''));
        }
        return bloc;
      },
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
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


  // ========== БІЛДЕРИ КОМПОНЕНТІВ (ВНУТРИ КЛАССА) ==========

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> translations, String currentLocale, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        translations['page_title'] ?? 'FindWay',
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24, fontFamily: 'Orbitron', letterSpacing: 2),
      ),
      // Убираем селектор отсюда, так как он теперь в NavBar
      actions: const [], 
    );
  }

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

  Widget _buildApplyFiltersButton(BuildContext context, Map<String, dynamic> translations) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
        icon: const Icon(Icons.filter_list),
        label: Text(translations['filter_button'] ?? "Застосувати фільтри"),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00).withOpacity(0.1), foregroundColor: const Color(0xFFFF8A00), side: const BorderSide(color: Color(0xFFFF8A00))),
      ),
    );
  }

  Widget _buildResetFiltersButton(BuildContext context, String currentLocale, Map<String, dynamic> translations) {
    return TextButton.icon(
      onPressed: () => context.read<SearchBloc>().add(LoadFilters(category: 'people', locale: currentLocale)),
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(translations['last'] ?? "Скинути фільтри"),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00F2FF)),
    );
  }

  // ========== ЕКСТРАКТОРИ ДАНИХ (БЕЗОПАСНЫЕ) ==========

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
    return 1; // Дефолт на вкладку Search
  }
}

// ==========================================
// ОКРЕМІ КЛАСИ ВІДЖЕТІВ (ВНЕ КЛАССА SearchPage)
// ==========================================

class _LocaleSelector extends StatelessWidget {
  final String currentLocale;
  final bool isInNavBar; 

  const _LocaleSelector({required this.currentLocale, this.isInNavBar = false, super.key});

  static const Map<String, List<String>> _groupedLocales = {
    "Europe": ["en", "uk", "pl", "nl", "be", "de", "fr", "it", "es", "pt", "cs", "sk", "ro"],
    "North America": ["ca", "us", "mx"],
  };

  static const Map<String, String> _fullNames = {
    "uk": "Ukraine (UA)", "en": "United Kingdom (EN)", "pl": "Poland (PL)",
    "nl": "Netherlands (NL)", "be": "Belgium", "de": "Germany (DE)",
    "fr": "France (FR)", "it": "Italy (IT)", "es": "Spain (ES)",
    "pt": "Portugal (PT)", "cs": "Czech Republic (CZ)", "sk": "Slovakia (SK)",
    "ro": "Romania (RO)", "ca": "Canada (CA)", "us": "USA (US)",
    "mx": "Mexico (MX)", "be_nl": "Flanders – NL", "be_fr": "Wallonia – FR",
    "be_de": "Eupen – DE"
  };

  String _getFlag(String code) {
    if (code.isEmpty) return "🌐";
    String countryCode = code.split('_')[0].toLowerCase();
    if (countryCode == 'en') countryCode = 'gb';
    if (countryCode == 'uk') countryCode = 'ua';
    return countryCode.toUpperCase().characters.map((char) => String.fromCharCode(char.codeUnitAt(0) + 127397)).join();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(context),
      child: Column( 
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getFlag(currentLocale), style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            currentLocale.toUpperCase(),
            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'Orbitron'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final searchBloc = context.read<SearchBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0E14),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) {
        return BlocProvider.value(
          value: searchBloc,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ListView(
              shrinkWrap: true,
              children: _groupedLocales.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key, style: const TextStyle(color: Color(0xFF00F2FF), fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                  children: entry.value.map((locale) {
                    // ✅ ЛОГИКА ВЕТВЛЕНИЯ ДЛЯ БЕЛЬГИИ
                    if (locale == 'be') {
                      return _buildBelgiumSubTile(context, searchBloc);
                    }
                    
                    return ListTile(
                      leading: Text(_getFlag(locale), style: const TextStyle(fontSize: 22)),
                      title: Text(_fullNames[locale] ?? locale.toUpperCase(), style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        searchBloc.add(ChangeLocale(locale));
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ========== БЕЛЬГИЙСКИЙ ПОДМОДУЛЬ ==========

  Widget _buildBelgiumSubTile(BuildContext context, SearchBloc bloc) {
    return ExpansionTile(
      leading: Text(_getFlag('be'), style: const TextStyle(fontSize: 20)),
      title: const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: Text("Belgium", style: TextStyle(color: Colors.white70, fontSize: 18)),
      ),
      children: [
        _buildSubItem(context, bloc, 'be_nl'),
        _buildSubItem(context, bloc, 'be_fr'),
        _buildSubItem(context, bloc, 'be_de'),
      ],
    );
  }

  Widget _buildSubItem(BuildContext context, SearchBloc bloc, String code) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 48),
      leading: Text(_getFlag(code), style: const TextStyle(fontSize: 18)),
      title: Text(
        _fullNames[code] ?? code.toUpperCase(),
        style: const TextStyle(color: Colors.white60, fontSize: 18),
      ),
      onTap: () {
        bloc.add(ChangeLocale(code));
        Navigator.pop(context);
      },
    );
  }
}

// ==========================================

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String currentLocale; 
  final Function(int) onTap;
  final Map<String, dynamic> translations;

  const CustomBottomNavBar({required this.currentIndex, required this.currentLocale, required this.onTap, required this.translations, super.key});

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
          _LocaleSelector(currentLocale: currentLocale, isInNavBar: true), 
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
          Icon(icon, color: isActive ? const Color(0xFFD81B60) : const Color(0xFF1E293B), size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isActive ? const Color(0xFFD81B60) : const Color(0xFF1E293B), fontSize: 10, fontFamily: 'Orbitron')),
        ],
      ),
    );
  }
}


