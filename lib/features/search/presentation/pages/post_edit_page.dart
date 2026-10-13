// =============================================================================
// FILE: lib/features/search/presentation/pages/post_edit_page.dart
// LAYER: Presentation Layer (Page / Form)
// RESPONSIBILITY: Post edit form with expandable ID panel placed under category
//                 selector, initial data hydration, and dynamic field counts.
// =============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../../data/models/filter_model.dart';
import '../widgets/map/location_picker_widget.dart';

// =============================================================================
// 1. MAIN POST EDIT PAGE WIDGET & STATE
// =============================================================================
class PostEditPage extends StatefulWidget {
  final int postId;
  final String initialCategory;
  final String initialTitle;
  final String initialText;
  final int? initialLocalId;
  final int? initialChoiceId;
  final int? initialActionId;

  // Geolocation & Metadata
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Map<String, dynamic>? initialAnimalMetadata;
  final Map<String, dynamic>? initialThingMetadata;

  final List<String> existingImages;

  const PostEditPage({
    super.key,
    required this.postId,
    required this.initialCategory,
    required this.initialTitle,
    required this.initialText,
    this.initialLocalId,
    this.initialChoiceId,
    this.initialActionId,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.initialAnimalMetadata,
    this.initialThingMetadata,
    this.existingImages = const [],
  });

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Palette
  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);
  final Color _accentOrange = const Color(0xFFFF8A00);
  final Color _accentCyan = const Color(0xFF00F2FF);
  final Color _textMuted = Colors.white54;

  late String _category;
  late String _title;
  late String _text;

  int? _localId;
  int? _choiceId;
  int? _actionId;

  // Geolocation
  double? _latitude;
  double? _longitude;
  String _address = '';

  // Animal Metadata
  String _chipNumber = '';
  String _passportNumber = '';
  String _insurancePolicyId = '';

  // Thing Metadata
  bool _isThingMetadataOpen = false;
  final Map<String, String> _thingMetadataValues = {};

  // Photos
  late List<String> _existingImages;
  List<File> _newImages = [];

  Map<String, dynamic> _translations = {};
  List<FilterModel> _filters = [];

  final Map<String, String> _fallback = const {
    'title': 'Edit post',
    'tytul_2': 'Title',
    'text_2': 'Text',
    'submit_article': 'Update',
    'animal_identifiers': 'ANIMAL IDENTIFIERS',
    'thing_identifiers': 'THING IDENTIFIERS & SPECS',
  };

  // =============================================================================
  // 2. LIFECYCLE & HELPERS
  // =============================================================================
  @override
  void initState() {
    super.initState();
    
    _category = widget.initialCategory;
    _title = widget.initialTitle;
    _text = widget.initialText;
    _localId = widget.initialLocalId;
    _choiceId = widget.initialChoiceId;
    _actionId = widget.initialActionId;

    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _address = widget.initialAddress ?? '';

    _existingImages = List.from(widget.existingImages);

    // Hydrate Animal Metadata
    if (widget.initialAnimalMetadata != null) {
      _chipNumber = widget.initialAnimalMetadata!['chip_number']?.toString() ?? '';
      _passportNumber = widget.initialAnimalMetadata!['passport_number']?.toString() ?? '';
      _insurancePolicyId = widget.initialAnimalMetadata!['insurance_policy_id']?.toString() ?? '';
    }

    // Hydrate Thing Metadata
    if (widget.initialThingMetadata != null) {
      widget.initialThingMetadata!.forEach((k, v) {
        if (v != null) {
          _thingMetadataValues[k] = v.toString();
        }
      });
      // Если у нас уже есть заполненные метаданные — разворачиваем панель по умолчанию
      if (_thingMetadataValues.isNotEmpty) {
        _isThingMetadataOpen = true;
      }
    }

    final bloc = context.read<SearchBloc>();
    final currentState = bloc.state;
    bool hasFilters = false;

    if (currentState is PostDetailsLoaded && currentState.filters.isNotEmpty) {
      _translations = currentState.uiTranslations;
      _filters = currentState.filters;
      hasFilters = true;
    } else if (currentState is FiltersLoaded && currentState.filters.isNotEmpty) {
      _translations = currentState.uiTranslations;
      _filters = currentState.filters;
      hasFilters = true;
    } else if (currentState is SearchSuccess && currentState.filters.isNotEmpty) {
      _translations = currentState.uiTranslations;
      _filters = currentState.filters;
      hasFilters = true;
    }

    if (!hasFilters) {
      bloc.add(LoadFilters(
        category: _category,
        locale: bloc.currentLocale, 
      ));
    }
  }

  String tr(String key) {
    return (_translations[key] ?? _fallback[key] ?? key).toString();
  }

  int get _totalPhotosCount => _existingImages.length + _newImages.length;

  bool get _isAnimalCategory {
    final cat = _category.toLowerCase().trim();
    return cat == 'animals' || cat == 'animal' || cat == 'sense' || cat == 'senses';
  }

  bool get _isThingCategory {
    final cat = _category.toLowerCase().trim();
    return cat == 'things' || cat == 'thing';
  }

  String? get _selectedSubCategoryLabel {
    if (_choiceId == null || _filters.length < 2) return null;
    final subFilter = _filters[1];
    final options = subFilter.options ?? [];
    for (final opt in options) {
      if (opt.id == _choiceId) {
        return opt.label;
      }
    }
    return null;
  }

  // =============================================================================
  // 3. IMAGE PICKERS
  // =============================================================================
  Future<void> _pickImagesMobile() async {
    if (_totalPhotosCount >= 4) return;
    
    final selected = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1440);
    if (selected.isNotEmpty) {
      setState(() {
        final availableSlots = 4 - _totalPhotosCount;
        _newImages = [
          ..._newImages,
          ...selected.map((e) => File(e.path))
        ].take(_newImages.length + availableSlots).toList();
      });
    }
  }

  Future<void> _pickImagesDesktop() async {
    if (_totalPhotosCount >= 4) return;

    final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);

    if (files.isNotEmpty) {
      setState(() {
        final availableSlots = 4 - _totalPhotosCount;
        _newImages = [
          ..._newImages,
          ...files.map((f) => File(f.path))
        ].take(_newImages.length + availableSlots).toList();
      });
    }
  }

  // =============================================================================
  // 4. MAIN BUILD METHOD
  // =============================================================================
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SearchBloc, SearchState>(
      listener: (context, state) {
        if (state is FiltersLoaded) {
          setState(() {
            _translations = state.uiTranslations;
            _filters = state.filters;
          });
        }

        if (state is PostUpdateSuccess) { 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('post_update_success')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }

        if (state is PostUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _bgDark,
          appBar: AppBar(
            backgroundColor: _bgDark,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),
            title: Text(
              tr('title'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: _filters.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotos(),
                        const SizedBox(height: 24),
                        _buildFilters(),

                        // 👉 ДИНАМИЧЕСКИЙ БЛОК METADATA СРАЗУ ПОД ДРОПДАУНАМИ
                        if (_isThingCategory) ...[
                          const SizedBox(height: 16),
                          _buildThingMetadataSection(),
                        ],

                        if (_isAnimalCategory) ...[
                          const SizedBox(height: 16),
                          _buildAnimalMetadataSection(),
                        ],

                        const SizedBox(height: 20),
                        _input(tr('tytul_2'), widget.initialTitle, (v) => _title = v),
                        const SizedBox(height: 20),
                        _input(tr('text_2'), widget.initialText, (v) => _text = v, max: 6),
                        const SizedBox(height: 24),

                        // Interactive Map Picker
                        LocationPickerWidget(
                          initialLat: _latitude ?? 50.0412,
                          initialLng: _longitude ?? 21.9991,
                          translations: _translations,
                          onLocationSelected: (lat, lng) {
                            _latitude = lat;
                            _longitude = lng;
                          },
                          onAddressChanged: (addr) {
                            _address = addr;
                          },
                        ),
                        const SizedBox(height: 24),

                        _submitButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // =============================================================================
  // 5. FORM COMPONENTS
  // =============================================================================
  Widget _buildPhotos() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 1. Existing Server Images
          ..._existingImages.asMap().entries.map((entry) {
            final index = entry.key;
            final url = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      url,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90, height: 90, color: Colors.grey,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                  _buildRemoveButton(() {
                    setState(() => _existingImages.removeAt(index));
                  }),
                ],
              ),
            );
          }),

          // 2. Local New Images
          ..._newImages.asMap().entries.map((entry) {
            final index = entry.key;
            final file = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      file,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  _buildRemoveButton(() {
                    setState(() => _newImages.removeAt(index));
                  }),
                ],
              ),
            );
          }),

          // 3. Add Photo Button
          if (_totalPhotosCount < 4)
            GestureDetector(
              onTap: () async {
                try {
                  await _pickImagesDesktop();
                } catch (_) {
                  await _pickImagesMobile();
                }
              },
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accentCyan.withOpacity(0.3)),
                ),
                child: Icon(Icons.add_a_photo, color: _accentOrange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(VoidCallback onTap) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, size: 14, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final action = _filters.first;
    final sub = _filters.length > 1 ? _filters[1] : null;
    final region = _filters.last;

    return Column(
      children: [
        _dropdown(action, _actionId, (v) => _actionId = v),
        const SizedBox(height: 16),
        if (sub != null)
          _dropdown(sub, _choiceId, (v) => _choiceId = v),
        const SizedBox(height: 16),
        _dropdown(region, _localId, (v) => _localId = v),
      ],
    );
  }

  Widget _dropdown(FilterModel f, int? val, Function(int?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<int>(
        value: val,
        items: f.options
                ?.map((e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(e.label, style: const TextStyle(color: Colors.white)),
                    ))
                .toList() ??
            [],
        onChanged: (v) {
          setState(() {
            onChanged(v);
          });
        },
        validator: (v) => v == null ? 'Required' : null,
        dropdownColor: _cardDark,
        decoration: InputDecoration(
          labelText: f.label,
          labelStyle: TextStyle(color: _textMuted),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _input(String hint, String initial, Function(String) onChanged, {int max = 1}) {
    return TextFormField(
      initialValue: initial, 
      maxLines: max,
      onChanged: onChanged,
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textMuted),
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // =============================================================================
  // 6. COLLAPSIBLE THING METADATA PANEL (Under Category Select)
  // =============================================================================
  Widget _buildThingMetadataSection() {
    final String label = _selectedSubCategoryLabel ?? '';
    final List<String> fields = _getFieldsForCategoryLabel(label);
    final int fieldsCount = fields.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Кнопка переключения состояния (Кнопка со счетчиком)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isThingMetadataOpen = !_isThingMetadataOpen;
              });
            },
            icon: Icon(
              _isThingMetadataOpen ? Icons.keyboard_arrow_up : Icons.security,
              size: 18,
            ),
            label: Text(
              fieldsCount > 0
                  ? 'ID SPECIFIC PARAMETERS ($fieldsCount)'
                  : 'ID SPECIFIC PARAMETERS',
              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accentCyan,
              side: BorderSide(color: _accentCyan.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),

        // Выдвижная панель полей
        if (_isThingMetadataOpen) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentCyan.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fields.isEmpty)
                  Text(
                    tr('thing_metadata.select_category_prompt'),
                    style: TextStyle(color: _textMuted, fontSize: 12),
                  )
                else ...[
                  Text(
                    'IDENTIFIERS: ${label.toUpperCase()}',
                    style: TextStyle(
                      color: _accentCyan,
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  ...fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _metaInputField(
                        label: _getAttrLabel(field),
                        hint: _getAttrPlaceholder(field),
                        icon: _getIconForField(field),
                        iconColor: _accentCyan,
                        initialVal: _thingMetadataValues[field] ?? '',
                        onChanged: (v) => _thingMetadataValues[field] = v.trim(),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // =============================================================================
  // 7. ANIMAL METADATA SECTION BUILDER
  // =============================================================================
  Widget _buildAnimalMetadataSection() {
    final String sectionTitle = tr('animal_identifiers');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accentCyan.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: _accentCyan, size: 18),
              const SizedBox(width: 8),
              Text(
                sectionTitle.toUpperCase(),
                style: TextStyle(
                  color: _accentCyan,
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          _metaInputField(
            label: 'Microchip ID',
            hint: 'e.g. 98512...',
            initialVal: _chipNumber,
            icon: Icons.memory,
            iconColor: _accentCyan,
            onChanged: (v) => _chipNumber = v,
          ),
          const SizedBox(height: 12),
          _metaInputField(
            label: 'Passport / Reg №',
            hint: 'Reg number',
            initialVal: _passportNumber,
            icon: Icons.badge_outlined,
            iconColor: Colors.amber,
            onChanged: (v) => _passportNumber = v,
          ),
          const SizedBox(height: 12),
          _metaInputField(
            label: 'Insurance Policy',
            hint: 'Policy ID',
            initialVal: _insurancePolicyId,
            icon: Icons.verified_outlined,
            iconColor: Colors.greenAccent,
            onChanged: (v) => _insurancePolicyId = v,
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // 8. METADATA INPUT HELPERS
  // =============================================================================
  List<String> _getFieldsForCategoryLabel(String? label) {
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

  IconData _getIconForField(String key) {
    switch (key) {
      case 'vin':
      case 'license_plate': return Icons.directions_car_outlined;
      case 'imei': return Icons.phone_android_outlined;
      case 'serial_number':
      case 'frame_number': return Icons.pin_outlined;
      case 'document_type':
      case 'document_number': return Icons.badge_outlined;
      case 'full_name': return Icons.person_outline;
      case 'brand_model': return Icons.sell_outlined;
      case 'color': return Icons.palette_outlined;
      case 'hallmark':
      case 'engraving': return Icons.diamond_outlined;
      case 'key_type':
      case 'keychain_description': return Icons.key_outlined;
      case 'contents_description': return Icons.inventory_2_outlined;
      default: return Icons.tag;
    }
  }

  String _getAttrLabel(String field) {
    final trKey = 'thing_metadata.attributes.$field';
    if (_translations.containsKey(trKey) && _translations[trKey] != null) {
      return _translations[trKey].toString();
    }
    return field.split('_').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  String _getAttrPlaceholder(String field) {
    final trKey = 'thing_metadata.placeholders.$field';
    if (_translations.containsKey(trKey) && _translations[trKey] != null) {
      return _translations[trKey].toString();
    }
    return '';
  }

  Widget _metaInputField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Function(String) onChanged,
    String? hint,
    String initialVal = '',
  }) {
    return TextFormField(
      initialValue: initialVal,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Monospace'),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
        labelStyle: TextStyle(color: _textMuted, fontSize: 12),
        prefixIcon: Icon(icon, color: iconColor, size: 18),
        filled: true,
        fillColor: _bgDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // =============================================================================
  // 9. SUBMIT BUTTON
  // =============================================================================
  Widget _submitButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accentOrange,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          Map<String, dynamic>? animalMetadata;
          if (_isAnimalCategory) {
            animalMetadata = {
              'chip_number': _chipNumber.trim(),
              'passport_number': _passportNumber.trim(),
              'insurance_policy_id': _insurancePolicyId.trim(),
            };
          }

          Map<String, dynamic>? thingMetadata;
          if (_isThingCategory) {
            final cleaned = Map<String, dynamic>.from(_thingMetadataValues)
              ..removeWhere((k, v) => v == null || v.toString().trim().isEmpty);
            if (cleaned.isNotEmpty) {
              thingMetadata = cleaned;
            }
          }

          context.read<SearchBloc>().add(UpdatePost(
                postId: widget.postId,
                category: _category,
                title: _title.trim(),
                text: _text.trim(),
                localId: _localId!,
                choiceId: _actionId!,
                catId: _choiceId,
                latitude: _latitude,
                longitude: _longitude,
                address: _address.trim(),
                animalMetadata: animalMetadata,
                thingMetadata: thingMetadata,
                locale: context.read<SearchBloc>().currentLocale,
                existingImages: _existingImages,
                newImagePaths: _newImages.map((e) => e.path).toList(),
              ));
        }
      },
      child: Text(
        tr('submit_article'),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}