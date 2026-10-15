// =============================================================================
// FILE: lib/features/search/presentation/widgets/post_button_panel.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Renders neon action control panel (Back, Chat, Comments, Edit, Delete)
//                 with glow effects, haptic feedback, and responsive layout.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostButtonPanel extends StatelessWidget {
  final Map<String, dynamic> tr;
  final VoidCallback onMessageTap;
  final VoidCallback onCommentTap;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final bool showEdit;
  final bool showDelete;

  const PostButtonPanel({
    super.key,
    required this.tr,
    required this.onMessageTap,
    required this.onCommentTap,
    required this.onEditTap,
    required this.onDeleteTap,
    this.showEdit = false,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. НАЗАД
              _actionButton(
                icon: Icons.arrow_back_rounded,
                color: const Color(0xFF94A3B8),
                accentColor: const Color(0xFF00F2FF),
                onTap: () => Navigator.pop(context),
                tooltip: tr['back'] ?? 'Назад',
              ),
              const SizedBox(width: 12),

              // 1. ЧАТ / ЛС (Самолётик под углом 45°)
              _actionButton(
                icon: Icons.near_me_rounded,
                color: const Color(0xFF00F2FF),
                accentColor: const Color(0xFF00F2FF),
                onTap: onMessageTap,
                tooltip: tr['message'] ?? 'Написати автору',
              ),
              const SizedBox(width: 12),
             
              // 2. КОММЕНТАРИИ (Форум / Публичный тред)
              _actionButton(
                icon: Icons.forum_rounded,
                color: const Color(0xFFFF8A00),
                accentColor: const Color(0xFFFF8A00),
                onTap: onCommentTap,
                tooltip: tr['comment'] ?? 'Коментарі',
              ),

              // 3. РЕДАКТИРОВАНИЕ (Блокнот с карандашом)
              if (showEdit) ...[
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF3B82F6),
                  accentColor: const Color(0xFF3B82F6),
                  onTap: onEditTap,
                  tooltip: tr['edit'] ?? 'Редагувати',
                ),
              ],

              // 4. УДАЛЕНИЕ (опционально)
              if (showDelete) ...[
                const SizedBox(width: 12),
                _actionButton(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFEF4444),
                  accentColor: const Color(0xFFEF4444),
                  onTap: onDeleteTap,
                  tooltip: tr['delete'] ?? 'Видалити',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required Color accentColor,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(14),
          splashColor: accentColor.withValues(alpha: 0.2),
          highlightColor: accentColor.withValues(alpha: 0.1),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}