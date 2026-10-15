// =============================================================================
// FILE: lib/features/search/presentation/widgets/search_results_grid.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Responsive 2-column SliverGrid rendering ArticleCard items
//                 and PaginationBar footer inside a SliverMainAxisGroup.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:findway_mobile/features/search/presentation/widgets/articles_card.dart';
import 'package:findway_mobile/features/search/presentation/widgets/pagination_bar.dart';

class SearchResultsGrid extends StatelessWidget {
  final List<dynamic> results;
  final String currentLocale;
  final int currentPage;
  final int lastPage;
  final int totalCount;

  const SearchResultsGrid({
    required this.results,
    required this.currentLocale,
    this.currentPage = 1,
    this.lastPage = 1,
    this.totalCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ArticleCard(
                  post: results[index],
                  currentLocale: currentLocale,
                );
              },
              childCount: results.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: PaginationBar(
            currentPage: currentPage,
            lastPage: lastPage,
            totalCount: totalCount,
          ),
        ),
      ],
    );
  }
}