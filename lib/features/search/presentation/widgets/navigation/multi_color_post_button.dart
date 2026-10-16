// =============================================================================
// FILE: lib/features/search/presentation/widgets/navigation/multi_color_post_button.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Renders central gradient action button for creating new posts.
// =============================================================================

import 'package:flutter/material.dart';

class MultiColorPostButton extends StatelessWidget {
  const MultiColorPostButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -4),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Color(0xFF23E5DB),
                Color(0xFF002F34),
                Color(0xFF6A11CB),
                Color(0xFFFF5F6D),
                Color(0xFFFFCE32),
                Color(0xFF23E5DB),
              ],
              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.add, size: 38, color: Color(0xFF002F34)),
          ),
        ),
      ),
    );
  }
}