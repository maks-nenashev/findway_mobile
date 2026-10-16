// =============================================================================
// FILE: lib/core/terms/terms_checkbox.dart
// PURPOSE: Localized terms acceptance checkbox and document dialog.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/terms_document.dart';
import 'terms_dialog.dart';
import 'terms_repository.dart';

class TermsCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  final String country;
  final String locale;

  /// When false, displays the legal notice and document link without a checkbox.
  final bool showCheckbox;

  /// Optional Rails I18n template, e.g. 'By continuing with Google, you agree to %{terms}.'.
  /// The %{terms} placeholder is replaced with the existing legal-document link.
  final String? disclaimerTemplate;

  const TermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.country = 'UA',
    this.locale = 'uk',
    this.showCheckbox = true,
    this.disclaimerTemplate,
  });

  static const Color _accent = Color(0xFF00F2FF);

  @override
  State<TermsCheckbox> createState() => _TermsCheckboxState();
}

class _TermsCheckboxState extends State<TermsCheckbox> {
  TermsDocument? _document;
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void didUpdateWidget(covariant TermsCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.country != widget.country ||
        oldWidget.locale != widget.locale) {
      _loadDocument();
    }
  }

  Future<void> _loadDocument() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final document = await TermsRepository.instance.load(
        country: widget.country,
        locale: widget.locale,
      );

      if (!mounted) return;

      setState(() {
        _document = document;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error;
        _isLoading = false;
      });

      debugPrint('Failed to load legal document: $error');
    }
  }

  Future<void> _openFullDocument(TermsDocument document) async {
    final uri = Uri.tryParse(document.fullVersion.url);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      _showError('Некоректне посилання на повний текст документа.');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showError('Не вдалося відкрити повний текст документа.');
      }
    } catch (error) {
      debugPrint('Failed to open legal document: $error');
      if (mounted) {
        _showError('Не вдалося відкрити повний текст документа.');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showTerms() async {
    final document = _document;
    if (document == null || !widget.enabled) return;

    await TermsDialog.show(
      context,
      document: document,
      onOpenFullDocument: () => _openFullDocument(document),
    );
  }

  Widget _buildTermsLabel(TermsDocument document) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          document.acceptance.checkboxLabel,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: widget.enabled ? _showTerms : null,
          child: Text(
            document.fullVersion.label,
            style: const TextStyle(
              color: TermsCheckbox._accent,
              fontSize: 12,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsNotice(TermsDocument document) {
    const marker = '%{terms}';
    final template = widget.disclaimerTemplate;

    // Use Devise's OAuth disclaimer from Rails when available. The linked label
    // and the document dialog still come from the existing legal repository.
    if (template == null || !template.contains(marker)) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Center(child: _buildTermsLabel(document)),
        ),
      );
    }

    final markerIndex = template.indexOf(marker);
    final beforeLink = template.substring(0, markerIndex);
    final afterLink = template.substring(markerIndex + marker.length);
    const noticeStyle = TextStyle(
      color: Colors.white54,
      fontSize: 12,
      height: 1.4,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(beforeLink, textAlign: TextAlign.center, style: noticeStyle),
            GestureDetector(
              onTap: widget.enabled ? _showTerms : null,
              child: Text(
                document.fullVersion.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: TermsCheckbox._accent,
                  fontSize: 12,
                  height: 1.4,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(afterLink, textAlign: TextAlign.center, style: noticeStyle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Завантаження умов використання...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadError != null || _document == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Не вдалося завантажити умови використання.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: widget.enabled ? _loadDocument : null,
              child: const Text('Повторити'),
            ),
          ],
        ),
      );
    }

    final document = _document!;

    // Google sign-in: reuse the same localized document and dialog, but no
    // checkbox. Email registration keeps the original checkbox behavior.
    if (!widget.showCheckbox) {
      return _buildTermsNotice(document);
    }

    return CheckboxListTile(
      value: widget.value,
      onChanged: widget.enabled
          ? (checked) => widget.onChanged(checked ?? false)
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: TermsCheckbox._accent,
      checkColor: const Color(0xFF0F172A),
      title: _buildTermsLabel(document),
    );
  }
}