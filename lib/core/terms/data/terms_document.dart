// =============================================================================
// FILE: lib/core/terms/data/terms_document.dart
// PURPOSE: Common data models for localized legal documents.
// =============================================================================

class TermsDocument {
  final String country;
  final String locale;
  final String documentType;
  final String version;

  final String title;
  final String subtitle;
  final String closeButton;

  final TermsFullVersion fullVersion;
  final TermsAcceptance acceptance;
  final List<TermsSection> sections;

  const TermsDocument({
    required this.country,
    required this.locale,
    required this.documentType,
    required this.version,
    required this.title,
    required this.subtitle,
    required this.closeButton,
    required this.fullVersion,
    required this.acceptance,
    required this.sections,
  });

  factory TermsDocument.fromJson(Map<String, dynamic> json) {
    return TermsDocument(
      country: json['country'] as String,
      locale: json['locale'] as String,
      documentType: json['document_type'] as String,
      version: json['version'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      closeButton: json['close_button'] as String,
      fullVersion: TermsFullVersion.fromJson(
        json['full_version'] as Map<String, dynamic>,
      ),
      acceptance: TermsAcceptance.fromJson(
        json['acceptance'] as Map<String, dynamic>,
      ),
      sections: (json['sections'] as List<dynamic>)
          .map(
            (section) => TermsSection.fromJson(
              section as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'locale': locale,
      'document_type': documentType,
      'version': version,
      'title': title,
      'subtitle': subtitle,
      'close_button': closeButton,
      'full_version': fullVersion.toJson(),
      'acceptance': acceptance.toJson(),
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }
}

class TermsFullVersion {
  final String label;
  final String url;

  const TermsFullVersion({
    required this.label,
    required this.url,
  });

  factory TermsFullVersion.fromJson(Map<String, dynamic> json) {
    return TermsFullVersion(
      label: json['label'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'url': url,
    };
  }
}

class TermsAcceptance {
  final String checkboxLabel;
  final String validationError;

  const TermsAcceptance({
    required this.checkboxLabel,
    required this.validationError,
  });

  factory TermsAcceptance.fromJson(Map<String, dynamic> json) {
    return TermsAcceptance(
      checkboxLabel: json['checkbox_label'] as String,
      validationError: json['validation_error'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkbox_label': checkboxLabel,
      'validation_error': validationError,
    };
  }
}

class TermsSection {
  final String id;
  final String title;
  final String content;
  final bool required;

  const TermsSection({
    required this.id,
    required this.title,
    required this.content,
    this.required = false,
  });

  factory TermsSection.fromJson(Map<String, dynamic> json) {
    return TermsSection(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      required: json['required'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'required': required,
    };
  }
}