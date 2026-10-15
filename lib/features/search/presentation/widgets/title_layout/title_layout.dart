// =============================================================================
// FILE: lib/features/search/presentation/widgets/title_layout/title_layout.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Renders title layout view with category selection feed.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/features/search/domain/models/findway_category.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';
import 'package:findway_mobile/features/search/presentation/widgets/locale_selector.dart';
import 'package:findway_mobile/features/search/presentation/widgets/title_layout/category_card.dart';

class TitleLayout extends StatelessWidget {
  final ScrollController scrollController;
  final Map<String, dynamic> translations;
  final String currentLocale;
  final Function(String categoryKey) onCategorySelected;

  const TitleLayout({
    required this.scrollController,
    required this.translations,
    required this.currentLocale,
    required this.onCategorySelected,
    super.key,
  });

  List<FindWayCategory> _getLocalizedCategories(Map<String, dynamic> trans) {
    return [
      FindWayCategory(
        title: trans['things'] ?? trans['title_three'] ?? 'Things',
        accentColor: const Color(0xFFFF8A00),
        modelsInfo: 'Models EfficientNet-B0, NLP | ACTIVE',
        description: trans['things_desc'] ?? trans['description_three'] ?? '',
        imagePath: 'assets/images/things.png',
      ),
      FindWayCategory(
        title: trans['animals'] ?? trans['title_two'] ?? 'Animals',
        accentColor: const Color(0xFF00F2FF),
        modelsInfo: 'Models EfficientNet-B0, NLP & YOLO8/DINOv2 | ACTIVE',
        description: trans['animals_desc'] ?? trans['description_two'] ?? '',
        imagePath: 'assets/images/cat.png',
      ),
      FindWayCategory(
        title: trans['people'] ?? trans['title_one'] ?? 'People',
        accentColor: const Color(0xFF3B82F6),
        modelsInfo: 'Models EfficientNet-B0, NLP | ACTIVE & ArcFace INACTIVE',
        description: trans['people_desc'] ?? trans['description_one'] ?? '',
        imagePath: 'assets/images/peop.png',
      ),
    ];
  }

  String _getRawCategoryName(int index) {
    switch (index) {
      case 0:
        return 'things';
      case 1:
        return 'animals';
      case 2:
        return 'people';
      default:
        return 'things';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = _getLocalizedCategories(translations);

    return CustomScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: const Color(0xFFF0F4F8),
          elevation: 0,
          floating: true,
          title: Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onCategorySelected('');
                final bloc = context.read<SearchBloc>();
                bloc.add(LoadFilters(category: '', locale: bloc.currentLocale));
              },
              child: Image.asset(
                'assets/images/logo1.png',
                height: 65,
                fit: BoxFit.contain,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: LocaleSelector(currentLocale: currentLocale),
            ),
          ],
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final String categoryKey = _getRawCategoryName(index);
                return CategoryCard(
                  category: categories[index],
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onCategorySelected(categoryKey);
                    context.read<SearchBloc>().add(
                          LoadFilters(category: categoryKey, locale: currentLocale),
                        );
                  },
                );
              },
              childCount: categories.length,
            ),
          ),
        ),
        SliverToBoxAdapter( //
          child: SizedBox(
            height: 10.0 + MediaQuery.of(context).padding.bottom,
          ),
        ),
      ],
    );
  }
}