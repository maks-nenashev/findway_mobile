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
  // 1. Извлекаем переводы
  final Map<String, dynamic> tr = (state is FiltersLoaded) 
      ? state.uiTranslations 
      : (state is SearchSuccess) ? state.uiTranslations 
      : (state is PostDetailsLoaded) ? state.uiTranslations : {};

  // 2. УМНАЯ ЛОКАЛЬ (Fix): Ищем локаль везде, где она может быть
  String currentLocale = 'en'; 

  if (state is FiltersLoaded) {
    currentLocale = state.currentLocale;
  } else if (tr.containsKey('locale_code') && tr['locale_code'] != null) {
    // Если мы в SearchSuccess или PostDetailsLoaded — берем из пришедших данных
    currentLocale = tr['locale_code'].toString();
  } else if (state is SearchLoading || state is ResultsLoading) {
    // Если мы в процессе загрузки, пытаемся сохранить текущую локаль из предыдущего состояния
    final previousState = context.read<SearchBloc>().state;
    if (previousState is FiltersLoaded) {
      currentLocale = previousState.currentLocale;
    }
  }
          return Scaffold(
            backgroundColor: const Color(0xFFF0F4F8),// Цвет фона для всего экрана
            // --- ВОЗВРАЩЕННАЯ ШАПКА ---
            appBar: AppBar(
              backgroundColor: Colors.transparent,// Прозрачный фон для эффекта "плавающей" шапки
              elevation: 0,
              title: Text(
                tr['page_title'] ?? 'FindWay',// Локализованный заголовок страницы
                style: const TextStyle(
                  color: Colors.black, // Цвет текста
                  fontWeight: FontWeight.bold, // Жирный шрифт
                  fontSize: 24, // Размер шрифта
                  fontFamily: 'Orbitron', // Твой стиль
                  letterSpacing: 2
                ),
              ),
              actions: [
                _LocaleSelector(currentLocale: currentLocale),
              ],
            ),
            body: CustomScrollView(
              slivers: [
                // 1. DASHBOARD
                SliverToBoxAdapter(// Весь контентный блок с отступами и карточкой
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),// Отступы для всего блока
                    child: Container(
                      padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                     color: const Color(0xFF0A0E14), // Глубокий "космический" черный
                     borderRadius: BorderRadius.circular(24),
                     border: Border.all(
                     color: const Color(0xFF00F2FF).withOpacity(0.2), // Тонкая неоновая рамка
                     width: 1,
                   ),
                     boxShadow: [
                 BoxShadow(
                     color: const Color(0xFF00F2FF).withOpacity(0.05), // Неоновое свечение вместо тени
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
                          
                          if (state is FiltersLoaded) ...[
                            FilterBuilder(
                              filters: state.filters,
                              selectedValues: state.selectedValues,
                              currentCategory: state.currentCategory,
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

                // 2. GRID РЕЗУЛЬТАТОВ
                if (state is SearchSuccess)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Две карточки в ряд
                        mainAxisSpacing: 16, // Вертикальный отступ между карточками
                        crossAxisSpacing: 16, // Горизонтальный отступ между карточками
                        childAspectRatio: 0.75, // Соотношение сторон карточки (можешь подстроить под свой дизайн)
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ArticleCard(
                          post: state.results[index],
                          currentLocale: currentLocale,
                        ),
                        childCount: state.results.length,
                      ),
                    ),
                  ),
                
                if (state is SearchLoading || state is ResultsLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- PRIVATE HELPERS ---

  Widget _buildCategoryNavigation(BuildContext context, SearchState state, Map tr, String locale) {
    final currentCat = (state is FiltersLoaded) ? state.currentCategory : 'people';
    return Row(
      children: [
        _pillButton(context, 'people', tr['button_article'] ?? 'Люди', const Color(0xFF00F2FF), currentCat == 'people', locale),
        const SizedBox(width: 8),//
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
            color: isActive ? color.withOpacity(0.1) : const Color(0xFFF8FAFC),
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
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        decoration: InputDecoration(
          hintText: tr['plac_title'] ?? 'Пошук...',
          prefixIcon: const Icon(Icons.search, size: 20),
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
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
          backgroundColor: const Color(0xFFFF8A00).withOpacity(0.1),//
          foregroundColor: const Color(0xFFFF8A00),//
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
      icon: const Icon(Icons.arrow_back, size: 16),
      label: Text(tr['last'] ?? "Фільтри"),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8A00)),
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

// --- КАРТОЧКА (Article Card с динамическим статусом) ---
class _ArticleCard extends StatelessWidget {
  final dynamic post;
  final String currentLocale;
  const _ArticleCard({required this.post, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    // Извлекаем статус (Нашли/Ищем) из Rails JSON
   final String statusLabel = (post['choice_label'] ?? "").toString().toUpperCase();
    // Вставь это ПЕРЕД return GestureDetector
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
        // ЗДЕСЬ ОБЯЗАТЕЛЬНО ИСПОЛЬЗУЕМ КЛЮЧИ (decoration:)
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
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
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
                    // --- ТВОЙ ДИНАМИЧЕСКИЙ БЕЙДЖ (С ФИКСОМ СИНТАКСИСА) ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Добавлена метка padding:
                      decoration: BoxDecoration( // Добавлена метка decoration:
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