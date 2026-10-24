// =============================================================================
// FILE: lib/core/terms/terms_repository.dart
// PURPOSE: Load and cache localized legal documents from JSON assets.
// =============================================================================

import 'dart:convert';

import 'package:flutter/services.dart';

import 'data/terms_document.dart';

class TermsRepository {
  TermsRepository._();

  static final TermsRepository instance = TermsRepository._();

  static const Map<String, String> _assetPaths = {
    'UA:uk': 'assets/terms/UA.json',
  };

  final Map<String, TermsDocument> _cache = {};

  /// Loads a legal document for the specified country and locale.
  ///
  /// Example:
  /// final document = await TermsRepository.instance.load(
  ///   country: 'UA',
  ///   locale: 'uk',
  /// );
  Future<TermsDocument> load({
    required String country,
    required String locale,
  }) async {
    final key = '${country.toUpperCase()}:${locale.toLowerCase()}';

    final cachedDocument = _cache[key];
    if (cachedDocument != null) {
      return cachedDocument;
    }

    final assetPath = _assetPaths[key];

    if (assetPath == null) {
      throw UnsupportedError(
        'Legal document is not configured for $key.',
      );
    }

    final jsonString = await rootBundle.loadString(assetPath);

    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Legal document JSON must contain an object.',
      );
    }

    final document = TermsDocument.fromJson(decoded);

    if (document.country.toUpperCase() != country.toUpperCase() ||
        document.locale.toLowerCase() != locale.toLowerCase()) {
      throw const FormatException(
        'Legal document country or locale does not match the requested '
        'configuration.',
      );
    }

    _cache[key] = document;

    return document;
  }

  /// Clears the cached document, useful after updating a local asset
  /// or in tests.
  void clearCache() {
    _cache.clear();
  }
}