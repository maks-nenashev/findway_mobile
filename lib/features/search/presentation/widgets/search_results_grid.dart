// =============================================================================
// FILE: lib/features/search/presentation/widgets/search_results_grid.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Renders responsive 2-column grid view of search post cards.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:findway_mobile/features/search/presentation/widgets/articles_card.dart';

class SearchResultsGrid extends StatelessWidget {
  final List<dynamic> results;
  final String currentLocale;

  const SearchResultsGrid({
    required this.results,
    required this.currentLocale,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
          (context, index) {
            final dynamic post = results[index];

            final String rawId = (post is Map)
                ? (post['id']?.toString() ?? index.toString())
                : index.toString();

            final String imageUrl = (post is Map)
                ? (post['image_url'] ?? post['images_urls']?[0] ?? '')
                : '';

            return ArticleCard(
              key: ValueKey('article_${rawId}_$imageUrl'),
              post: post,
              currentLocale: currentLocale,
            );
          },
          childCount: results.length,
        ),
      ),
    );
  }
}