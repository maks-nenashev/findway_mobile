// =============================================================================
// FILE: lib/features/search/presentation/pages/post_create_page.dart
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
import '../widgets/map/location_picker_widget.dart'; // 👉 Импорт карты

class PostCreatePage extends StatefulWidget {
  final String initialCategory;

  const PostCreatePage({
    super.key,
    required this.initialCategory,
  });

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);
  final Color _accentOrange = const Color(0xFFFF9800);
  final Color _accentCyan = const Color(0xFF00F2FF);
  final Color _textMuted = Colors.white54;

  late String _category;

  String _title = '';
  String _text = '';

  int? _localId;
  int? _choiceId;
  int? _actionId;

  // 👉 Геолокационные данные
  double? _latitude;
  double? _longitude;
  String _address = '';

  // Специфика животных
  String _chipNumber = '';
  String _passportNumber = '';
  String _insurancePolicyId = '';

  List<File> _images = [];

  Map<String, dynamic> _translations = {};
  List<FilterModel> _filters = [];

  final Map<String, String> _fallback = const {
    'title': 'New post!',
    'tytul_2': 'Title',
    'text_2': 'Text',
    'submit_article': 'Submit',
    'animal_identifiers': 'ANIMAL IDENTIFIERS',
  };

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;

    final bloc = context.read<SearchBloc>();
    bloc.add(LoadFilters(
      category: _category,
      locale: bloc.currentLocale,
    ));
  }

  String tr(String key) {
    return (_translations[key] ?? _fallback[key] ?? key).toString();
  }

  bool get _isAnimalCategory {
    final cat = _category.toLowerCase().trim();
    return cat == 'animals' || cat == 'animal' || cat == 'sense' || cat == 'senses';
  }

  Future<void> _pickImagesMobile() async {
    final selected = await _picker.pickMultiImage(imageQuality: 70, maxWidth: 1440);
    if (selected.isNotEmpty) {
      setState(() {
        _images = [..._images, ...selected.map((e) => File(e.path))].take(4).toList();
      });
    }
  }

  Future<void> _pickImagesDesktop() async {
    final typeGroup = XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']);
    final files = await openFiles(acceptedTypeGroups: [typeGroup]);
    if (files.isNotEmpty) {
      setState(() {
        _images = [..._images, ...files.map((f) => File(f.path))].take(4).toList();
      });
    }
  }

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

        if (state is PostCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('post_create_success')),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, state.postId);
        }

        if (state is PostCreateError) {
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
              onPressed: () => Navigator.pop(context),
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
                        const SizedBox(height: 20),
                        _input(tr('tytul_2'), (v) => _title = v),
                        const SizedBox(height: 20),
                        _input(tr('text_2'), (v) => _text = v, max: 6),
                        const SizedBox(height: 24),

                        // 👉 Интерактивная карта выбора точки события
                        LocationPickerWidget(
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

                        if (_isAnimalCategory) ...[
                          _buildAnimalMetadataSection(),
                          const SizedBox(height: 24),
                        ],

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

  Widget _buildPhotos() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length < 4 ? _images.length + 1 : 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == _images.length && _images.length < 4) {
            return GestureDetector(
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
            );
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(_images[i], width: 90, height: 90, fit: BoxFit.cover),
          );
        },
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
        if (sub != null) _dropdown(sub, _choiceId, (v) => _choiceId = v),
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
        onChanged: (v) => setState(() => onChanged(v)),
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

  Widget _input(String hint, Function(String) onChanged, {int max = 1}) {
    return TextFormField(
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
            icon: Icons.memory,
            iconColor: _accentCyan,
            onChanged: (v) => _chipNumber = v,
          ),
          const SizedBox(height: 12),
          _metaInputField(
            label: 'Passport / Reg №',
            icon: Icons.badge_outlined,
            iconColor: Colors.amber,
            onChanged: (v) => _passportNumber = v,
          ),
          const SizedBox(height: 12),
          _metaInputField(
            label: 'Insurance Policy',
            icon: Icons.verified_outlined,
            iconColor: Colors.greenAccent,
            onChanged: (v) => _insurancePolicyId = v,
          ),
        ],
      ),
    );
  }

  Widget _metaInputField({
    required String label,
    required IconData icon,
    required Color iconColor,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Monospace'),
      decoration: InputDecoration(
        labelText: label,
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

          context.read<SearchBloc>().add(CreatePost(
                category: _category,
                title: _title.trim(),
                text: _text.trim(),
                localId: _localId!,
                choiceId: _actionId!,
                catId: _choiceId,
                latitude: _latitude,   // 👉 Передача широты
                longitude: _longitude, // 👉 Передача долготы
                address: _address.trim(), // 👉 Передача текста адреса
                animalMetadata: animalMetadata,
                locale: context.read<SearchBloc>().currentLocale,
                imagePaths: _images.map((e) => e.path).toList(),
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