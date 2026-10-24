// =============================================================================
// FILE: lib/features/search/domain/models/findway_category.dart
// LAYER: Domain Layer (Model)
// RESPONSIBILITY: Represents category metadata for title layout cards.
// =============================================================================

import 'package:flutter/material.dart';

class FindWayCategory {
  final String title;
  final String description;
  final String imagePath;
  final String modelsInfo;
  final Color accentColor;

  const FindWayCategory({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.modelsInfo,
    required this.accentColor,
  });
}