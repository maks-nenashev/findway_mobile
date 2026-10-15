// =============================================================================
// FILE: lib/features/search/presentation/widgets/navigation/custom_bottom_nav_bar.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Floating bottom navigation bar with unread badge and locale switcher.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:findway_mobile/features/search/presentation/widgets/locale_selector.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String currentLocale;
  final Function(int) onTap;
  final Map<String, dynamic> translations;
  final int unreadCount;

  const CustomBottomNavBar({
    required this.currentIndex,
    required this.currentLocale,
    required this.onTap,
    required this.translations,
    this.unreadCount = 0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset + 12),
      child: Container(
        margin: const EdgeInsets.fromLTRB(40, 0, 40, 0),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF1E293B), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            LocaleSelector(
              currentLocale: currentLocale,
              isInNavBar: true,
            ),
            _navItem(1, Icons.search, translations['nav_search'] ?? 'Search'),
            const SizedBox(width: 40),
            _navItem(
              3,
              Icons.mail_outline,
              translations['nav_messages'] ?? 'Chat',
              badgeCount: unreadCount,
            ),
            _navItem(4, Icons.person_outline, translations['nav_profile'] ?? 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    int index,
    IconData icon,
    String label, {
    int badgeCount = 0,
  }) {
    final bool isActive = currentIndex == index;
    const Color activeColor = Color(0xFFD81B60);
    const Color inactiveColor = Color(0xFF1E293B);

    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            label: Text(
              '$badgeCount',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            isLabelVisible: badgeCount > 0,
            backgroundColor: Colors.red,
            child: Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : inactiveColor,
              fontSize: 10,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }
}