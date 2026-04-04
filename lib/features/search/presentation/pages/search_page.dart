import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/filter_builder.dart';
import 'search_details_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>()..add(const LoadFilters(category: 'people', locale: '')),
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          // 1. Извлекаем переводы (Contextual Mapping)
          final Map<String, dynamic> tr = _getTranslations(state);

          // 2. УМНАЯ ЛОКАЛЬ
          String currentLocale = _getLocale(context, state, tr);

          // 3. Извлекаем данные для рендеринга (чтобы были доступны в любом стейте)
          final results = _getResults(state);
          final filters = _getFilters(state);
          final selectedValues = _getSelectedValues(state);
          final currentCategory = _getCategory(state);

          return Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                tr['page_title'] ?? 'FindWay',
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
            ),
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    // 1. DASHBOARD (Фильтры)
                    SliverToBoxAdapter(
                      child: Padding(
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
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCategoryNavigation(context, state, tr, currentLocale),
                              const SizedBox(height: 24),
                              _buildSearchInput(context, tr),
                              const SizedBox(height: 16),
                              
                              // Фильтры видны всегда, если они загружены в любом стейте
                              if (filters != null) ...[
                                FilterBuilder(
                                  filters: filters,
                                  selectedValues: selectedValues,
                                  currentCategory: currentCategory,
                                  onFilterChanged: (id, val) => context.read<SearchBloc>().add(
                                    UpdateFilterValue(filterId: id, value: val),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFilterButton(context, tr),
                              ],

                              if (state is SearchSuccess)
                                _buildReturnToFiltersButton(context, state, currentLocale, tr),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 2. GRID РЕЗУЛЬТАТОВ (Виден всегда, если есть данные)
                    if (results.isNotEmpty)
                      SliverPadding(
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
                      )
                    else if (state is! SearchLoading && state is! ResultsLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text(tr['no_results'] ?? 'No data')),
                      ),
                    
                    // Резервный отступ снизу
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),

                // 3. NON-BLOCKING LOADERS
                if (state is SearchLoading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF))),
                  ),
                
                if (state is ResultsLoading)
                   Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
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

  // --- Вспомогательные методы извлечения данных (Data Extraction) ---

  Map<String, dynamic> _getTranslations(SearchState state) {
    if (state is FiltersLoaded) return state.uiTranslations;
    if (state is SearchSuccess) return state.uiTranslations;
    if (state is ResultsLoading) return state.uiTranslations;
    if (state is PostDetailsLoaded) return state.uiTranslations;
    return {};
  }

  String _getLocale(BuildContext context, SearchState state, Map tr) {
    if (state is FiltersLoaded) return state.currentLocale;
    if (tr.containsKey('locale_code')) return tr['locale_code'].toString();
    return 'en';
  }

  List<dynamic> _getResults(SearchState state) {
    if (state is FiltersLoaded) return state.results;
    if (state is SearchSuccess) return state.results;
    if (state is ResultsLoading) return state.results;
    return [];
  }

  dynamic _getFilters(SearchState state) {
    if (state is FiltersLoaded) return state.filters;
    if (state is SearchSuccess) return state.filters;
    if (state is ResultsLoading) return state.filters;
    return null;
  }

  Map<String, dynamic> _getSelectedValues(SearchState state) {
    if (state is FiltersLoaded) return state.selectedValues;
    if (state is SearchSuccess) return state.selectedValues;
    if (state is ResultsLoading) return state.selectedValues;
    return {};
  }

  String _getCategory(SearchState state) {
    if (state is FiltersLoaded) return state.currentCategory;
    return 'people';
  }

  // --- PRIVATE HELPERS (UI Components) ---

  Widget _buildCategoryNavigation(BuildContext context, SearchState state, Map tr, String locale) {
    final currentCat = _getCategory(state);
    return Row(
      children: [
        _pillButton(context, 'people', tr['button_article'] ?? 'Люди', const Color(0xFF00F2FF), currentCat == 'people', locale),
        const SizedBox(width: 8),
        _pillButton(context, 'animals', tr['button_sense'] ?? 'Тварини', const Color(0xFFFF8A00), currentCat == 'animals', locale),
        const SizedBox(width: 8),
        _pillButton(context, 'things', tr['button_thing'] ?? 'Речі', const Color(0xFF2ECC71), currentCat == 'things', locale),
      ],
    );
  }

  Widget _pillButton(BuildContext context, String cat, String label, Color color, bool isActive, String locale) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<SearchBloc>().add(LoadFilters(category: cat, locale: locale)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? color : Colors.transparent, width: 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isActive ? color : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInput(BuildContext context, Map tr) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: tr['plac_title'] ?? 'Пошук...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(6.0),
            child: ElevatedButton(
              onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(tr['find'] ?? 'FIND', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, Map tr) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
        icon: const Icon(Icons.filter_list),
        label: Text(tr['filter'] ?? 'ФІЛЬТРУВАТИ'),
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

  Widget _buildReturnToFiltersButton(BuildContext context, SearchSuccess state, String locale, Map tr) {
    return TextButton.icon(
      onPressed: () => context.read<SearchBloc>().add(LoadFilters(category: 'people', locale: locale)),
      icon: const Icon(Icons.refresh, size: 16),
      label: Text(tr['last'] ?? "Скинути фільтри"),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF00F2FF)),
    );
  }
}

// --- КЛАСС СЕЛЕКТОРА ЛОКАЛИ ---
class _LocaleSelector extends StatelessWidget {
  final String currentLocale;
  const _LocaleSelector({required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (locale) => context.read<SearchBloc>().add(ChangeLocale(locale)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'uk', child: Text('Українська (UA)')),
        const PopupMenuItem(value: 'en', child: Text('English (EN)')),
        const PopupMenuItem(value: 'pl', child: Text('Polski (PL)')),
        const PopupMenuItem(value: 'nl', child: Text('Nederlands (NL)')),
      ],
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF00F2FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00F2FF).withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Color(0xFF00F2FF), size: 16),
            const SizedBox(width: 8),
            Text(
              currentLocale.toUpperCase(),
              style: const TextStyle(color: Color(0xFF00F2FF), fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// --- КАРТОЧКА (Article Card) ---
class _ArticleCard extends StatelessWidget {
  final dynamic post;
  final String currentLocale;
  const _ArticleCard({required this.post, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    final String statusLabel = (post['choice_label'] ?? "").toString().toUpperCase();
    
    return GestureDetector(
      onTap: () {
        final bloc = context.read<SearchBloc>();
        bloc.add(LoadPostDetails(id: post['id'], category: 'people', locale: currentLocale));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(value: bloc, child: const SearchDetailsPage()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post['image_url'] ?? "",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F2FF).withOpacity(0.2),
                        border: Border.all(color: const Color(0xFF00F2FF)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Color(0xFF00F2FF), 
                          fontSize: 9, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post['title'] ?? "", 
                      style: const TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
                        fontSize: 13, 
                        fontFamily: 'Orbitron'
                      ), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
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