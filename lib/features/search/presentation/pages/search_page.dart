import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/filter_builder.dart';
import 'search_details_page.dart';

/// Головна сторінка пошуку
/// 
/// Відповідає за:
/// - Відображення фільтрів для різних категорій (люди, тварини, речі)
/// - Вибір мови інтерфейсу
/// - Виконання пошуку та відображення результатів
/// - Навігацію до деталей результату
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Ініціалізуємо SearchBloc і завантажуємо фільтри при створенні
      create: (_) => sl<SearchBloc>()
        ..add(const LoadFilters(category: 'people', locale: '')),
      
      // Білдер слідкує за змінами стану і перебудовує UI
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          // ============ РОЗПАКУВАННЯ ДАНИХ ============
          // Витягуємо всі необхідні дані зі стану одноразово
          final Map<String, dynamic> translations = _extractTranslations(state);
          final String currentLocale = _extractLocale(context, state, translations);
          final List<dynamic> searchResults = _extractResults(state);
          final dynamic filters = _extractFilters(state);
          final Map<String, dynamic> selectedFilterValues = _extractSelectedValues(state);
          final String activeCategory = _extractCategory(state);

          return Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),
            
            // ============ ВЕРХНЯ ПАНЕЛЬ ============
            appBar: _buildAppBar(translations, currentLocale, context),
            
            // ============ ОСНОВНИЙ ВМІСТ ============
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // 1️⃣ ПАНЕЛЬ ФІЛЬТРІВ
                    SliverToBoxAdapter(
                      child: _buildFilterPanel(
                        context,
                        state,
                        translations,
                        currentLocale,
                        filters,
                        selectedFilterValues,
                        activeCategory,
                      ),
                    ),

                    // 2️⃣ СІТКА РЕЗУЛЬТАТІВ
                    if (searchResults.isNotEmpty)
                      _buildResultsGrid(searchResults, currentLocale)
                    else if (state is! SearchLoading && state is! ResultsLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            translations['no_results'] ?? 'Немає результатів',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),

                    // 3️⃣ РЕЗЕРВНИЙ ОТСТУП ВНИЗУ
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),

                // ============ ЗАВАНТАЖУВАЧІ ============
                // Показуємо повноекранний завантажувач на першому завантаженні
                if (state is SearchLoading)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00F2FF),
                      ),
                    ),
                  ),

                // Показуємо лінійний індикатор під час завантаження результатів
                if (state is ResultsLoading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF00F2FF).withOpacity(0.5),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========== БІЛДЕРИ КОМПОНЕНТІВ ==========

  /// Будує верхню панель з заголовком та селектором мови
  PreferredSizeWidget _buildAppBar(
    Map<String, dynamic> translations,
    String currentLocale,
    BuildContext context,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        translations['page_title'] ?? 'FindWay',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 24,
          fontFamily: 'Orbitron',
          letterSpacing: 2,
        ),
      ),
      actions: [
        _LocaleSelector(currentLocale: currentLocale),
      ],
    );
  }

  /// Будує панель з фільтрами, пошуком та кнопками навігації
  Widget _buildFilterPanel(
    BuildContext context,
    SearchState state,
    Map<String, dynamic> translations,
    String currentLocale,
    dynamic filters,
    Map<String, dynamic> selectedFilterValues,
    String activeCategory,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00F2FF).withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F2FF).withOpacity(0.05),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Кнопки категорій (Люди, Тварини, Речі)
            _buildCategoryButtons(
              context,
              activeCategory,
              translations,
              currentLocale,
            ),
            const SizedBox(height: 24),

            // Поле пошуку з кнопкою пошуку
            _buildSearchField(context, translations),
            const SizedBox(height: 16),

            // Блок фільтрів (показується, якщо вони завантажені)
            if (filters != null) ...[
              FilterBuilder(
                filters: filters,
                selectedValues: selectedFilterValues,
                currentCategory: activeCategory,
                onFilterChanged: (id, val) =>
                    context.read<SearchBloc>().add(
                      UpdateFilterValue(filterId: id, value: val),
                    ),
              ),
              const SizedBox(height: 16),
              _buildApplyFiltersButton(context, translations),
            ],

            // Кнопка повернення до фільтрів (видима при успішному пошуку)
            if (state is SearchSuccess)
              _buildResetFiltersButton(context, currentLocale, translations),
          ],
        ),
      ),
    );
  }

  /// Будує сітку результатів пошуку
  Widget _buildResultsGrid(List<dynamic> results, String currentLocale) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _ArticleCard(
            post: results[index],
            currentLocale: currentLocale,
          ),
          childCount: results.length,
        ),
      ),
    );
  }

  /// Будує навігаційні кнопки категорій
  Widget _buildCategoryButtons(
    BuildContext context,
    String activeCategory,
    Map<String, dynamic> translations,
    String currentLocale,
  ) {
    return Row(
      children: [
        _buildCategoryButton(
          context,
          'people',
          translations['button_article'] ?? 'Люди',
          const Color(0xFF00F2FF),
          activeCategory == 'people',
          currentLocale,
        ),
        const SizedBox(width: 8),
        _buildCategoryButton(
          context,
          'animals',
          translations['button_sense'] ?? 'Тварини',
          const Color(0xFFFF8A00),
          activeCategory == 'animals',
          currentLocale,
        ),
        const SizedBox(width: 8),
        _buildCategoryButton(
          context,
          'things',
          translations['button_thing'] ?? 'Речі',
          const Color(0xFF2ECC71),
          activeCategory == 'things',
          currentLocale,
        ),
      ],
    );
  }

  /// Будує одну кнопку категорії (таблетка)
  Widget _buildCategoryButton(
    BuildContext context,
    String categoryId,
    String label,
    Color accentColor,
    bool isActive,
    String currentLocale,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            context.read<SearchBloc>().add(
              LoadFilters(category: categoryId, locale: currentLocale),
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withOpacity(0.1)
                : const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? accentColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? accentColor : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  /// Будує поле пошуку з вбудованою кнопкою
  Widget _buildSearchField(
    BuildContext context,
    Map<String, dynamic> translations,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: translations['plac_title'] ?? 'Пошук...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: ElevatedButton(
              onPressed: () =>
                  context.read<SearchBloc>().add(const PerformSearch()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                translations['find'] ?? 'FIND',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }

  /// Будує кнопку застосування фільтрів
  Widget _buildApplyFiltersButton(
    BuildContext context,
    Map<String, dynamic> translations,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () =>
            context.read<SearchBloc>().add(const PerformSearch()),
        icon: const Icon(Icons.filter_list),
        label: Text(translations['filter'] ?? 'ФІЛЬТРУВАТИ'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF8A00).withOpacity(0.1),
          foregroundColor: const Color(0xFFFF8A00),
          elevation: 0,
          side: const BorderSide(color: Color(0xFFFF8A00)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  /// Будує кнопку скидання фільтрів
  Widget _buildResetFiltersButton(
    BuildContext context,
    String currentLocale,
    Map<String, dynamic> translations,
  ) {
    return TextButton.icon(
      onPressed: () =>
          context.read<SearchBloc>().add(
            LoadFilters(category: 'people', locale: currentLocale),
          ),
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(translations['last'] ?? "Скинути фільтри"),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF00F2FF),
      ),
    );
  }

  // ========== ЕКСТРАКТОРИ ДАНИХ ==========
  // Ці методи витягують дані зі різних станів BLoC
  // Вони гарантують, що дані завжди доступні, незалежно від типу стану

  /// Витягує переводи з поточного стану
  Map<String, dynamic> _extractTranslations(SearchState state) {
    if (state is FiltersLoaded) return state.uiTranslations;
    if (state is SearchSuccess) return state.uiTranslations;
    if (state is ResultsLoading) return state.uiTranslations;
    if (state is PostDetailsLoaded) return state.uiTranslations;
    return {};
  }

  /// Витягує код поточної мови
  String _extractLocale(
    BuildContext context,
    SearchState state,
    Map<String, dynamic> translations,
  ) {
    if (state is FiltersLoaded) return state.currentLocale;
    if (translations.containsKey('locale_code')) {
      return translations['locale_code'].toString();
    }
    return 'en';
  }

  /// Витягує результати пошуку
  List<dynamic> _extractResults(SearchState state) {
    if (state is FiltersLoaded) return state.results;
    if (state is SearchSuccess) return state.results;
    if (state is ResultsLoading) return state.results;
    return [];
  }

  /// Витягує доступні фільтри
  dynamic _extractFilters(SearchState state) {
    if (state is FiltersLoaded) return state.filters;
    if (state is SearchSuccess) return state.filters;
    if (state is ResultsLoading) return state.filters;
    return null;
  }

  /// Витягує вибрані значення фільтрів
  Map<String, dynamic> _extractSelectedValues(SearchState state) {
    if (state is FiltersLoaded) return state.selectedValues;
    if (state is SearchSuccess) return state.selectedValues;
    if (state is ResultsLoading) return state.selectedValues;
    return {};
  }

  /// Витягує активну категорію
  String _extractCategory(SearchState state) {
    if (state is FiltersLoaded) return state.currentCategory;
    return 'people';
  }
}

// ========== ДОПОМІЖНІ КОМПОНЕНТИ ==========

/// Селектор мови у верхній панелі
/// 
/// Дозволяє користувачеві вибрати мову інтерфейсу з выпадаючого меню
class _LocaleSelector extends StatelessWidget {
  final String currentLocale;

  const _LocaleSelector({required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (locale) =>
          context.read<SearchBloc>().add(ChangeLocale(locale)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'uk',
          child: Text('Українська (UA)'),
        ),
        const PopupMenuItem(
          value: 'en',
          child: Text('English (EN)'),
        ),
        const PopupMenuItem(
          value: 'pl',
          child: Text('Polski (PL)'),
        ),
        const PopupMenuItem(
          value: 'nl',
          child: Text('Nederlands (NL)'),
        ),
      ],
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00F2FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00F2FF).withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Color(0xFF00F2FF), size: 16),
            const SizedBox(width: 8),
            Text(
              currentLocale.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF00F2FF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка результату пошуку зі зображенням та статусом
/// 
/// Показує:
/// - Зображення результату
/// - Статус (choice_label)
/// - Заголовок
/// - Градієнтний оверлей внизу
/// 
/// При натисканні навігує на сторінку деталей
class _ArticleCard extends StatelessWidget {
  final dynamic post;
  final String currentLocale;

  const _ArticleCard({
    required this.post,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    // Витягуємо та форматуємо статус
    final String statusLabel = (post['choice_label'] ?? "").toString().toUpperCase();

    return GestureDetector(
      onTap: () {
        // Отримуємо BLoC для передачі на наступну сторінку
        final bloc = context.read<SearchBloc>();
        
        // Запускаємо завантаження деталей результату
        bloc.add(LoadPostDetails(
          id: post['id'],
          category: 'people',
          locale: currentLocale,
        ));

        // Навігуємо на сторінку деталей
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: const SearchDetailsPage(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1️⃣ ФОНЕ ЗОБРАЖЕННЯ
              Image.network(
                post['image_url'] ?? "",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[800]),
              ),

              // 2️⃣ ГРАДІЄНТНИЙ ОВЕРЛЕЙ (від прозорого до чорного внизу)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // 3️⃣ ІНФОРМАЦІЯ (статус + заголовок)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Статус-бейдж
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F2FF).withOpacity(0.2),
                        border: Border.all(
                          color: const Color(0xFF00F2FF),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Color(0xFF00F2FF),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Заголовок рез��льтату
                    Text(
                      post['title'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Orbitron',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}