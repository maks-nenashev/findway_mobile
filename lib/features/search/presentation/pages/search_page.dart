import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injection_container.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/filter_builder.dart';

class SearchPage extends StatelessWidget {
  // const конструктор исправляет ошибку в main.dart
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>()..add(const LoadFilters(category: 'people')),
      child: Builder(builder: (context) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('FindWay: Пошук'),
              bottom: TabBar(
                onTap: (index) {
                  final categories = ['people', 'animals', 'things'];
                  context.read<SearchBloc>().add(LoadFilters(category: categories[index]));
                },
                tabs: const [
                  Tab(text: 'Люди'),
                  Tab(text: 'Тварини'),
                  Tab(text: 'Речі'),
                ],
              ),
            ),
            body: const _SearchBody(),
          ),
        );
      }),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        // 1. Загрузка
        if (state is SearchLoading || state is ResultsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Вывод результатов (Посты)
        if (state is SearchSuccess) {
          return _ResultsList(results: state.results);
        }

        // 3. Форма фильтров
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
                    child: const Text("ЗНАЙТИ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
  const _ResultsList({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text("Нічого не знайдено", style: TextStyle(fontSize: 18)),
            TextButton(
              onPressed: () => context.read<SearchBloc>().add(const LoadFilters(category: 'people')),
              child: const Text("Змінити фільтри"),
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
              Text("Результати: ${results.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => context.read<SearchBloc>().add(const LoadFilters(category: 'people')),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text("Фільтри"),
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
                  // Адаптация под ключи твоего Rails API
                  title: Text(
                    post['title'] ?? post['text'] ?? "Об'єкт #${post['id']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      post['description'] ?? "Опис не вказано",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  onTap: () => debugPrint("Перехід до поста: ${post['id']}"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}