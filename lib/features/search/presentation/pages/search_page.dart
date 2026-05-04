import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/filter_builder.dart';
import '../widgets/articles_card.dart';
import '../widgets/locale_selector.dart';

// ✅ ИМПОРТЫ ДЛЯ МАРШРУТИЗАЦИИ СТРАНИЦ
import 'post_create_page.dart'; 
import 'post_card_page.dart'; 

// === 1. МОДЕЛЬ ДАННЫХ КАТЕГОРИЙ ===
class FindWayCategory {
  final String title;
  final String description;
  final String imagePath;
  final String modelsInfo;
  final Color accentColor;

  const FindWayCategory({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.modelsInfo,
    required this.accentColor,
  });
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // ✅ ЛОКАЛЬНАЯ ПАМЯТЬ: UI сам хранит категорию, чтобы не зависеть от BLoC
  String _localActiveCategory = '';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<SearchBloc>();
        bloc.add(const LoadFilters(category: '', locale: 'uk')); 
        return bloc;
      },
      child: BlocConsumer<SearchBloc, SearchState>(
        buildWhen: (previous, current) {
          // ✅ ЖЕЛЕЗОБЕТОННАЯ БРОНЯ
          return current is FiltersLoaded || 
                 current is SearchSuccess || 
                 current is ResultsLoading ||
                 current is SearchLoading ||
                 current is SearchInitial ||
                 current is SearchError;
        },
        listener: (context, state) {
          if (state is FiltersLoaded) {
            setState(() {
              _localActiveCategory = state.currentCategory;
            });
          }
        },
        builder: (context, state) {
          final translations = _extractTranslations(state);
          final currentLocale = _extractLocale(context, state, translations);
          final searchResults = _extractResults(state);
          final filters = _extractFilters(state);
          final selectedFilterValues = _extractSelectedValues(state);
          final currentTabIndex = _extractTabIndex(state);

          final bool isTitlePage = _localActiveCategory.isEmpty;

          return Scaffold( 
            extendBody: true,
            backgroundColor: const Color(0xFFF0F4F8),
            appBar: _buildAppBar(translations, currentLocale, context),
            
            // =========================================================
            // 👉 CUSTOM BUTTON (Кнопка Плюс)
            // =========================================================
            floatingActionButton: Transform.translate(
              offset: const Offset(0, 32),
              child: GestureDetector(
                onTap: () async { 
                  final String targetCategory = _localActiveCategory.isEmpty ? 'people' : _localActiveCategory;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SearchBloc>(),
                        child: PostCreatePage(initialCategory: targetCategory),
                      ),
                    ),
                  );

                  if (mounted) {
                    final bloc = context.read<SearchBloc>();
                    
                    if (result is int) {
                      // 1. Пост создан, загружаем его детали
                      bloc.add(LoadPostDetails(
                        id: result,
                        category: targetCategory,
                        locale: bloc.currentLocale,
                      ));

                      // 2. Открываем карточку (без const!)
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: bloc,
                            child: PostCardPage(),
                          ),
                        ),
                      );

                      // 3. После выхода обновляем ленту
                      if (mounted) {
                        bloc.add(LoadFilters(category: targetCategory, locale: bloc.currentLocale));
                      }
                    } else if (result == true) {
                      bloc.add(LoadFilters(category: targetCategory, locale: bloc.currentLocale));
                    }
                  }
                },
                child: _buildMultiColorPostButton(),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

            // =========================================================
            // 👉 НИЖНЕЕ МЕНЮ
            // =========================================================
            bottomNavigationBar: CustomBottomNavBar( 
              currentIndex: currentTabIndex,
              currentLocale: currentLocale,
              translations: translations,
              onTap: (index) { 
                if (index == 1) {
                  setState(() => _localActiveCategory = '');
                  context.read<SearchBloc>().add(const LoadFilters(category: '', locale: ''));
                } else {
                  context.read<SearchBloc>().add(ChangeTab(index));
                }
              },
            ),

            // =========================================================
            // 👉 BODY
            // =========================================================
            body: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isTitlePage 
                ? _buildTitleLayout(context, translations) 
                : Stack( 
                    key: const ValueKey('ModelLayout'),
                    children: [
                      CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildFilterPanel(
                              context, state, translations, currentLocale,
                              filters, selectedFilterValues, _localActiveCategory,
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
                        const Positioned.fill(child: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF)))),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }

  // --- ЛЕЙАУТ: ТИТУЛЬНЫЙ ЛИСТ ---
  Widget _buildTitleLayout(BuildContext context, Map<String, dynamic> trans) {
    final categories = _getLocalizedCategories(trans);
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return CategoryCard(
                  category: categories[index],
                  onTap: () {
                    context.read<SearchBloc>().add(
                      LoadFilters(category: _getRawCategoryName(index), locale: '')
                    );
                  },
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
      ],
    );
  }
  
  List<FindWayCategory> _getLocalizedCategories(Map<String, dynamic> trans) {
    return [
      FindWayCategory(
        title: trans['title_one'] ?? 'People',
        accentColor: const Color(0xFF00F2FF),
        modelsInfo: 'Models EfficientNet-B0, ArcFace & NLP | ACTIVE',
        description: trans['description_one'] ?? '',
        imagePath: 'assets/images/peop.png',
      ),
      FindWayCategory(
        title: trans['title_two'] ?? 'Animals',
        accentColor: const Color(0xFFFF8A00),
        modelsInfo: 'Models EfficientNet-B0, NLP | ACTIVE',
        description: trans['description_two'] ?? '',
        imagePath: 'assets/images/cat.png',
      ),
      FindWayCategory(
        title: trans['title_three'] ?? 'Things',
        accentColor: const Color(0xFF2ECC71),
        modelsInfo: 'Models EfficientNet-B0, NLP | ACTIVE',
        description: trans['description_three'] ?? '',
        imagePath: 'assets/images/things.png',
      ),
    ];
  }

  String _getRawCategoryName(int index) {
    switch (index) {
      case 0: return 'people';
      case 1: return 'animals';
      case 2: return 'things';
      default: return 'people';
    }
  }

  // --- Button Customization ---
  Widget _buildMultiColorPostButton() {
    return Transform.translate(
      offset: const Offset(0, -04),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFF23E5DB),
                Color(0xFF002F34),
                Color(0xFF6A11CB),
                Color(0xFFFF5F6D),
                Color(0xFFFFCE32),
                Color(0xFF23E5DB),
              ],
              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              size: 38,
              color: Color(0xFF002F34),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> translations, String currentLocale, BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 5.0), 
        child: Image.asset(
          'assets/images/logo1.png',
          height: 65, 
          fit: BoxFit.contain,
          semanticLabel: 'FindWay Logo', 
        ),
      ),
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
          color: darkSlate, borderRadius: BorderRadius.circular(24),
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
                    filled: true, fillColor: Colors.white,
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
            if (state is SearchSuccess) _buildResetFiltersButton(context, currentLocale, activeCategory, translations),
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
        onTap: () {
          setState(() => _localActiveCategory = cat);
          context.read<SearchBloc>().add(LoadFilters(category: cat, locale: locale));
        },
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
        label: Text(translations['filter_button'] ?? "Застосувати фильтри"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A00).withOpacity(0.1),
          foregroundColor: const Color(0xFFFF8A00),
          side: const BorderSide(color: Color(0xFFFF8A00)),
        ),
      ),
    );
  }

  Widget _buildResetFiltersButton(BuildContext context, String currentLocale, String activeCategory, Map<String, dynamic> translations) {
    return TextButton.icon(
      onPressed: () => context.read<SearchBloc>().add(LoadFilters(category: activeCategory, locale: currentLocale)),
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(translations['last'] ?? "Скинути фильтри"),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00F2FF)),
    );
  }

  // --- Экстракторы состояния ---
  Map<String, dynamic> _extractTranslations(SearchState state) {
    if (state is FiltersLoaded) return state.uiTranslations;
    if (state is SearchSuccess) return state.uiTranslations;
    if (state is ResultsLoading) return state.uiTranslations;
    return {};
  }

  String _extractLocale(BuildContext context, SearchState state, Map<String, dynamic> translations) {
    if (state.currentLocale.isNotEmpty) return state.currentLocale;
    return translations['locale_code']?.toString() ?? 'uk';
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
    if (state is FiltersLoaded) return state.selectedValues.cast<String, dynamic>();
    if (state is SearchSuccess) return state.selectedValues.cast<String, dynamic>();
    if (state is ResultsLoading) return state.selectedValues.cast<String, dynamic>();
    return {};
  }

  int _extractTabIndex(SearchState state) {
    if (state is FiltersLoaded) return state.tabIndex;
    if (state is SearchSuccess) return state.tabIndex;
    if (state is ResultsLoading) return state.tabIndex;
    return 1;
  }
}

// === ВИДЖЕТ КАРТОЧКИ КАТЕГОРИИ ===
class CategoryCard extends StatelessWidget {
  final FindWayCategory category;
  final VoidCallback onTap;

  const CategoryCard({required this.category, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final String path = category.imagePath;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: path.startsWith('http')
              ? NetworkImage(path) as ImageProvider
              : AssetImage(path) as ImageProvider,
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.55),
            BlendMode.darken,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(color: category.accentColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.modelsInfo.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 9, fontFamily: 'Orbitron'),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    category.title.toUpperCase(),
                    style: TextStyle(color: category.accentColor, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Orbitron'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.description,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === НИЖНЯЯ НАВИГАЦИЯ ===
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String currentLocale; 
  final Function(int) onTap;
  final Map<String, dynamic> translations;

  const CustomBottomNavBar({required this.currentIndex, required this.currentLocale, required this.onTap, required this.translations, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 20), 
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF1E293B), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          LocaleSelector(currentLocale: currentLocale, isInNavBar: true),
          _navItem(1, Icons.search, translations['nav_search'] ?? 'Search'),
          const SizedBox(width: 40), 
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