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
                tabs: const [Tab(text: 'Люди'), Tab(text: 'Тварини'), Tab(text: 'Речі')],
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
        if (state is SearchLoading) return const Center(child: CircularProgressIndicator());
        if (state is FiltersLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16, bottom: 32),
            child: Column(
              children: [
                FilterBuilder(
                  filters: state.filters,
                  selectedValues: state.selectedValues,
                  currentCategory: state.currentCategory,
                  onFilterChanged: (id, val) => context.read<SearchBloc>().add(UpdateFilterValue(filterId: id, value: val)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => debugPrint("Final params: ${state.selectedValues}"),
                  child: const Text("Знайти"),
                ),
              ],
            ),
          );
        }
        if (state is SearchError) return Center(child: Text("Помилка: ${state.message}"));
        return const SizedBox.shrink();
      },
    );
  }
}