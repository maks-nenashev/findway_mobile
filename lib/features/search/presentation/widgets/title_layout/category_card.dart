// =============================================================================
// FILE: lib/features/search/presentation/widgets/title_layout/category_card.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Renders single title category banner card with background images.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:findway_mobile/features/search/domain/models/findway_category.dart';

class CategoryCard extends StatelessWidget {
  final FindWayCategory category;
  final VoidCallback onTap;

  const CategoryCard({
    required this.category,
    required this.onTap,
    super.key,
  });

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
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.55), BlendMode.darken),
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
                  Row(
                    children: [
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
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.title.toUpperCase(),
                    style: TextStyle(
                      color: category.accentColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Orbitron',
                    ),
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