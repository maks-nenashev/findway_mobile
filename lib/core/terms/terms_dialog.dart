// =============================================================================
// FILE: lib/core/terms/terms_dialog.dart
// PURPOSE: Display a localized legal document loaded from JSON.
// =============================================================================

import 'package:flutter/material.dart';

import 'data/terms_document.dart';

class TermsDialog extends StatelessWidget {
  final TermsDocument document;
  final VoidCallback? onOpenFullDocument;

  const TermsDialog({
    super.key,
    required this.document,
    this.onOpenFullDocument,
  });

  static const Color _surface = Color(0xFF1E293B);
  static const Color _accent = Color(0xFF00F2FF);
  static const Color _secondary = Color(0xFFFF8A00);

  static Future<void> show(
    BuildContext context, {
    required TermsDocument document,
    VoidCallback? onOpenFullDocument,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => TermsDialog(
        document: document,
        onOpenFullDocument: onOpenFullDocument,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _surface,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _accent.withValues(alpha: 0.25),
        ),
      ),
      title: Text(
        document.title,
        style: const TextStyle(
          color: _accent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (document.subtitle.isNotEmpty) ...[
                Text(
                  document.subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              for (final section in document.sections) ...[
                Text(
                  section.title,
                  style: const TextStyle(
                    color: _secondary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              if (onOpenFullDocument != null) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onOpenFullDocument,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: BorderSide(
                        color: _accent.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(document.fullVersion.label),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            document.closeButton,
            style: const TextStyle(color: _accent),
          ),
        ),
      ],
    );
  }
}