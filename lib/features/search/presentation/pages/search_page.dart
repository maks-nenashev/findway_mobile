import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/filter_builder.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>()..add(const LoadFilters(category: 'people')),
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          // Извлекаем переводы из стейта (FiltersLoaded или SearchSuccess)
          final Map<String, dynamic> tr = (state is FiltersLoaded) 
              ? state.uiTranslations 
              : (state is SearchSuccess) ? state.uiTranslations : {};

          return DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: Text(tr['page_title'] ?? 'FindWay: Пошук'),
                actions: [
                  _LocaleSelector(currentLocale: (state is FiltersLoaded) ? state.currentLocale : 'uk'),
                ],
                bottom: TabBar(
                  onTap: (index) {
                    final categories = ['people', 'animals', 'things'];
                    context.read<SearchBloc>().add(LoadFilters(category: categories[index]));
                  },
                  tabs: [
                    Tab(text: tr['button_article'] ?? 'Люди'),
                    Tab(text: tr['button_sense'] ?? 'Тварини'),
                    Tab(text: tr['button_thing'] ?? 'Речі'),
                  ],
                ),
              ),
              body: _SearchBody(tr: tr),
            ),
          );
        },
      ),
    );
  }
}

class _LocaleSelector extends StatelessWidget {
  final String currentLocale;
  const _LocaleSelector({required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Змінити мову',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, color: Colors.blueAccent),
          const SizedBox(width: 4),
          Text(currentLocale.toUpperCase(), 
            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)
          ),
        ],
      ),
      onSelected: (locale) => context.read<SearchBloc>().add(ChangeLocale(locale)),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'uk', child: Text('Українська (UA)')),
        const PopupMenuItem(value: 'en', child: Text('English (EN)')),
      ],
    );
  }
}

class _SearchBody extends StatelessWidget {
  final Map<String, dynamic> tr;
  const _SearchBody({required this.tr});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoading || state is ResultsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SearchSuccess) {
          return _ResultsList(results: state.results, tr: tr);
        }

        if (state is FiltersLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FilterBuilder(
                  filters: state.filters,
                  selectedValues: state.selectedValues,
                  currentCategory: state.currentCategory,
                  onFilterChanged: (id, val) => context.read<SearchBloc>().add(
                        UpdateFilterValue(filterId: id, value: val),
                      ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => context.read<SearchBloc>().add(const PerformSearch()),
                    child: Text(
                      (tr['find'] ?? "ЗНАЙТИ").toString().toUpperCase(), 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SearchError) {
          return Center(child: Text("Помилка: ${state.message}", style: const TextStyle(color: Colors.red)));
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<dynamic> results;
  final Map<String, dynamic> tr;
  const _ResultsList({required this.results, required this.tr});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(tr['empty_state'] ?? "Нічого не знайдено", style: const TextStyle(fontSize: 18)),
            TextButton(
              onPressed: () {
                final categories = ['people', 'animals', 'things'];
                final index = DefaultTabController.of(context).index;
                context.read<SearchBloc>().add(LoadFilters(category: categories[index]));
              },
              child: Text(tr['change_filters'] ?? "Змінити фільтри"),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: Colors.grey[200],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${tr['results_count'] ?? 'Результати'}: ${results.length}", 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  final categories = ['people', 'animals', 'things'];
                  final index = DefaultTabController.of(context).index;
                  context.read<SearchBloc>().add(LoadFilters(category: categories[index]));
                },
                icon: const Icon(Icons.tune, size: 18),
                label: Text(tr['filter'] ?? "Фільтри"),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final post = results[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.location_on, color: Colors.white),
                  ),
                  title: Text(
                    post['title'] ?? post['text'] ?? "ID #${post['id']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      post['description'] ?? post['text'] ?? "...",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () => debugPrint("Post ID: ${post['id']}"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}