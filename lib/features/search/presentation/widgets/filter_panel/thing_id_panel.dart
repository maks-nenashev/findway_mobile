// =============================================================================
// FILE: lib/features/search/presentation/widgets/filter_panel/thing_id_panel.dart
// LAYER: Presentation Layer (Widget)
// RESPONSIBILITY: Dynamic search panel for item metadata (VIN, IMEI, Serial, Documents)
//                 strictly utilizing YAML translation keys without hardcoded locales.
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

  /// Универсальный поиск ключей перевода (поддерживает nested Map и dot-notation)
  static String? _lookup(Map<String, dynamic> trans, String dotPath) {
    if (trans.isEmpty) return null;

    // 1. Проверка плоского ключа ("thing_metadata.attributes.vin")
    if (trans.containsKey(dotPath) && trans[dotPath] != null && trans[dotPath].toString().isNotEmpty) {
      return trans[dotPath].toString();
    }

    // 2. Итеративный обход вложенного Map ("thing_metadata" -> "attributes" -> "vin")
    final parts = dotPath.split('.');
    dynamic current = trans;

    for (final part in parts) {
      if (current is Map) {
        dynamic foundKey;
        for (final k in current.keys) {
          if (k.toString().toLowerCase() == part.toLowerCase()) {
            foundKey = k;
            break;
          }
        }
        if (foundKey != null) {
          current = current[foundKey];
        } else {
          current = null;
          break;
        }
      } else {
        current = null;
        break;
      }
    }

    if (current != null && current is! Map && current.toString().isNotEmpty) {
      return current.toString();
    }

    return null;
  }

  /// Языконезависимое определение подкатегории (DE / EN / UK / PL)
  static List<String> getFieldsForCategoryLabel(String? label) {
    if (label == null || label.trim().isEmpty) return [];

    final String lower = label.toLowerCase().trim();

    // 1. DOCUMENTS / DOKUMENTE / DOKUMENTY / ДОКУМЕНТИ / ПАСПОРТ
    if (lower.contains('doc') || 
        lower.contains('dok') || 
        lower.contains('urk') || 
        lower.contains('ausweis') || 
        lower.contains('пасп') || 
        lower.contains('pasp') || 
        lower.contains('pass') || 
        lower.contains('посвідч') || 
        lower.contains('прав')) {
      return ['document_type', 'document_number', 'full_name'];
    } 
    // 2. PHONES / HANDY / ELEKTRONIK / TELEFONY / ТЕЛЕФОНИ
    else if (lower.contains('phon') || 
             lower.contains('handy') || 
             lower.contains('telef') || 
             lower.contains('gadg') || 
             lower.contains('ґадж') || 
             lower.contains('гадж') || 
             lower.contains('смартф') || 
             lower.contains('ноут') || 
             lower.contains('планш') ||
             lower.contains('elek') ||
             lower.contains('елек')) {
      return ['imei', 'serial_number', 'brand_model', 'color'];
    } 
    // 3. JEWELRY / SCHMUCK / BIŻUTERIA / ЮВЕЛІРНІ ВИРОБИ
    else if (lower.contains('jewel') || 
             lower.contains('schmuck') || 
             lower.contains('ювел') || 
             lower.contains('прикрас') || 
             lower.contains('biżut') || 
             lower.contains('bizut') ||
             lower.contains('кошт')) {
      return ['serial_number', 'brand_model', 'hallmark', 'engraving'];
    }
    // 4. CARS / FAHRZEUGE / AUTO / SAMOCHODY / АВТОМОБІЛІ & МОТОЦИКЛИ
    else if (lower.contains('car') || 
             lower.contains('fahrzeug') || 
             lower.contains('auto') || 
             lower.contains('pkw') || 
             lower.contains('kfz') || 
             lower.contains('авто') || 
             lower.contains('маш') || 
             lower.contains('samoch') || 
             lower.contains('moto') || 
             lower.contains('мото') || 
             lower.contains('трансп')) {
      return ['vin', 'license_plate', 'brand_model', 'color'];
    } 
    // 5. BICYCLES / FAHRRÄDER / ROWERY / ВЕЛОСИПЕДИ
    else if (lower.contains('bik') || 
             lower.contains('fahrrad') || 
             lower.contains('rad') || 
             lower.contains('вело') || 
             lower.contains('rower') || 
             lower.contains('самок')) {
      return ['frame_number', 'brand_model', 'color'];
    } 
    // 6. KEYS / SCHLÜSSEL / KLUCZE / КЛЮЧІ
    else if (lower.contains('key') || 
             lower.contains('schlüssel') || 
             lower.contains('schluessel') || 
             lower.contains('ключ') || 
             lower.contains('klucz')) {
      return ['key_type', 'keychain_description'];
    } 
    // 7. BAGS / TASCHEN / WALLETS / TORBY / СУМКИ / ГАМАНЦІ
    else if (lower.contains('bag') || 
             lower.contains('tasch') || 
             lower.contains('börs') || 
             lower.contains('boers') || 
             lower.contains('сумк') || 
             lower.contains('кошел') || 
             lower.contains('portf') || 
             lower.contains('wall') ||
             lower.contains('гаман') ||
             lower.contains('портф') ||
             lower.contains('рюкз')) {
      return ['brand_model', 'color', 'contents_description'];
    }

    // 8. DEFAULT FALLBACK
    return ['serial_number', 'brand_model', 'additional_info'];
  }

  @override
  Widget build(BuildContext context) {
    const Color darkBg = Color(0xFF0F172A);
    const Color borderCyan = Color(0xFF00F2FF);

    final List<String> fields = getFieldsForCategoryLabel(subCategoryLabel);

    if (fields.isEmpty) {
      final String prompt = _lookup(trans, 'thing_metadata.select_category_prompt') ?? '';
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

    final String defaultTitle = _lookup(trans, 'thing_metadata.title') ?? 'IDENTIFIERS';
    final String titleText = subCategoryLabel != null
        ? '${defaultTitle.toUpperCase()}: ${subCategoryLabel!.toUpperCase()}'
        : defaultTitle;

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
    final paths = [
      'thing_metadata.attributes.$field',
      'thing_metadata_attributes_$field',
      'attributes.$field',
    ];
    for (final p in paths) {
      final res = _lookup(trans, p);
      if (res != null) return res;
    }
    return field.replaceAll('_', ' ').toUpperCase();
  }

  String _getAttrPlaceholder(String field, Map<String, dynamic> trans) {
    final paths = [
      'thing_metadata.placeholders.$field',
      'thing_metadata_placeholders_$field',
      'placeholders.$field',
    ];
    for (final p in paths) {
      final res = _lookup(trans, p);
      if (res != null) return res;
    }
    return '';
  }
}