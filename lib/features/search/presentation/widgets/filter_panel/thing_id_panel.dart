// =============================================================================
// FILE: lib/features/search/presentation/widgets/filter_panel/thing_id_panel.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Dynamic search panel for item metadata (VIN, IMEI, Serial, Documents).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';

class ThingIdPanel extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> trans;
  final String? subCategoryLabel;

  const ThingIdPanel({
    required this.controllers,
    required this.trans,
    required this.subCategoryLabel,
    super.key,
  });

  static List<String> getFieldsForCategoryLabel(String? label) {
    if (label == null || label.trim().isEmpty) return [];

    final lower = label.toLowerCase();
    if (lower.contains('doc') || lower.contains('документ') || lower.contains('dokumen')) {
      return ['document_type', 'document_number', 'full_name'];
    } else if (lower.contains('phone') || lower.contains('телефон') || lower.contains('telefon') || lower.contains('gadget')) {
      return ['imei', 'serial_number', 'brand_model', 'color'];
    } else if (lower.contains('car') || lower.contains('авто') || lower.contains('машин') || lower.contains('samochód')) {
      return ['vin', 'license_plate', 'brand_model', 'color'];
    } else if (lower.contains('moto') || lower.contains('мото')) {
      return ['vin', 'license_plate', 'brand_model', 'color'];
    } else if (lower.contains('bike') || lower.contains('вело') || lower.contains('rower')) {
      return ['frame_number', 'brand_model', 'color'];
    } else if (lower.contains('jewel') || lower.contains('ювелир') || lower.contains('прикрас') || lower.contains('biżuteria')) {
      return ['brand_model', 'serial_number', 'hallmark', 'engraving'];
    } else if (lower.contains('key') || lower.contains('ключ') || lower.contains('klucz')) {
      return ['key_type', 'keychain_description'];
    } else if (lower.contains('bag') || lower.contains('сумк') || lower.contains('кошел') || lower.contains('portfel') || lower.contains('wallet')) {
      return ['brand_model', 'color', 'contents_description'];
    }

    return ['brand_model', 'serial_number', 'additional_info'];
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0F172A);
    const Color borderCyan = Color(0xFF00F2FF);

    final List<String> fields = getFieldsForCategoryLabel(subCategoryLabel);

    if (fields.isEmpty) {
      final String prompt = trans['thing_metadata.select_category_prompt'] ??
          trans['select_category_prompt'] ??
          'Select a category to view specific parameters (VIN, IMEI, frame number, documents, etc.).';
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: borderCyan, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                prompt,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final String titleText = subCategoryLabel != null
        ? 'IDENTIFIERS: ${subCategoryLabel!.toUpperCase()}'
        : (trans['thing_metadata.title'] ?? 'THING IDENTIFIERS');

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText.toUpperCase(),
            style: const TextStyle(
              color: borderCyan,
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...fields.map((field) {
            final String label = _getAttrLabel(field, trans);
            final String placeholder = _getAttrPlaceholder(field, trans);
            final TextEditingController controller = controllers[field] ?? TextEditingController();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _idTextField(
                context,
                controller,
                placeholder.isNotEmpty ? placeholder : label,
                'q[thing_metadata_$field]',
                labelOverride: label,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _idTextField(
    BuildContext context,
    TextEditingController controller,
    String hint,
    String filterKey, {
    String? labelOverride,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelOverride != null && labelOverride.isNotEmpty) ...[
          Text(
            labelOverride,
            style: const TextStyle(color: Color(0xFF00F2FF), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF00F2FF)),
            ),
          ),
          onChanged: (val) {
            context.read<SearchBloc>().add(UpdateFilterValue(filterId: filterKey, value: val));
          },
        ),
      ],
    );
  }

  String _getAttrLabel(String field, Map<String, dynamic> trans) {
    final keys = [
      'thing_metadata.attributes.$field',
      'thing_metadata_attributes_$field',
      'attributes.$field',
    ];
    for (final k in keys) {
      if (trans.containsKey(k) && trans[k] != null && trans[k].toString().isNotEmpty) {
        return trans[k].toString();
      }
    }
    switch (field) {
      case 'vin': return 'VIN Number';
      case 'license_plate': return 'License Plate';
      case 'imei': return 'IMEI Code';
      case 'serial_number': return 'Serial Number (S/N)';
      case 'frame_number': return 'Frame Number';
      case 'document_type': return 'Document Type';
      case 'document_number': return 'Document Number / Series';
      case 'full_name': return 'Full Name on Document';
      case 'brand_model': return 'Brand / Model';
      case 'color': return 'Color';
      case 'hallmark': return 'Hallmark / Stamp';
      case 'engraving': return 'Engraving / Markings';
      case 'key_type': return 'Key Type (car, apartment)';
      case 'keychain_description': return 'Keychain Description';
      case 'contents_description': return 'Contents Description';
      case 'additional_info': return 'Additional Distinctive Features';
      default: return field;
    }
  }

  String _getAttrPlaceholder(String field, Map<String, dynamic> trans) {
    final keys = [
      'thing_metadata.placeholders.$field',
      'thing_metadata_placeholders_$field',
      'placeholders.$field',
    ];
    for (final k in keys) {
      if (trans.containsKey(k) && trans[k] != null && trans[k].toString().isNotEmpty) {
        return trans[k].toString();
      }
    }
    switch (field) {
      case 'vin': return 'e.g., WBA3A51070F...';
      case 'imei': return '15 digits (e.g., 356890...)';
      case 'license_plate': return 'e.g., KR 12345';
      case 'frame_number': return 'e.g., WTU1234567X';
      case 'document_number': return 'e.g., AB 123456';
      case 'full_name': return 'Full name as shown on document';
      default: return '';
    }
  }
}