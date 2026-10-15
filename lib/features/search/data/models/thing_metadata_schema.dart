// =============================================================================
// FILE: lib/features/search/data/models/thing_metadata_schema.dart
// RESPONSIBILITY: Схема соответствия подкатегории вещи (Phone slug) 
//                 и списка разрешенных атрибутов идентификации.
// =============================================================================

class ThingMetadataSchema {
  static const Map<String, List<String>> schema = {
    'documents': ['document_type', 'document_number', 'full_name'],
    'phones': ['brand_model', 'imei', 'serial_number', 'color'],
    'cars': ['brand_model', 'vin', 'license_plate', 'color'],
    'motorcycles': ['brand_model', 'vin', 'license_plate', 'color'],
    'bicycles': ['brand_model', 'frame_number', 'color'],
    'jewelry': ['brand_model', 'serial_number', 'hallmark', 'engraving'],
    'keys': ['key_type', 'keychain_description'],
    'bags_wallets': ['brand_model', 'color', 'contents_description'],
    'other': ['brand_model', 'serial_number', 'additional_info'],
  };

  static const Map<String, String> fieldLabels = {
    'vin': 'VIN Code',
    'license_plate': 'License Plate / Reg №',
    'imei': 'IMEI',
    'serial_number': 'Serial Number',
    'frame_number': 'Frame Number',
    'document_type': 'Document Type',
    'document_number': 'Document Number',
    'full_name': 'Full Name',
    'brand_model': 'Brand / Model',
    'color': 'Color',
    'hallmark': 'Hallmark',
    'engraving': 'Engraving',
    'key_type': 'Key Type',
    'keychain_description': 'Keychain Description',
    'contents_description': 'Contents Description',
    'additional_info': 'Additional Info',
  };

  /// Возвращает список полей для категории по её slug/title
  static List<String> getFieldsForCategory(String? categorySlug) {
    if (categorySlug == null) return [];
    final key = categorySlug.toLowerCase().trim();
    return schema[key] ?? schema['other']!;
  }
}