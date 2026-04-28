import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../../data/models/filter_model.dart';

class PostCreatePage extends StatefulWidget {
  final String initialCategory;
  const PostCreatePage({super.key, required this.initialCategory});

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);
  final Color _accentOrange = const Color(0xFFFF9800);
  final Color _textMuted = Colors.white54;

  late String _category;
  String _title = '';
  String _text = '';

  int? _localId;
  int? _choiceId;   // subcategory
  int? _actionId;   // status (choice_id)
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> selected = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1440,
      );
      if (selected.isNotEmpty) {
        setState(() => _images = [..._images, ...selected].take(4).toList());
      }
    } catch (e) {
      debugPrint("ImagePicker Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = context.watch<SearchBloc>().state;
    final Map<String, dynamic> trans = _getTranslations(searchState);
    final List<FilterModel> availableFilters = _getFilters(searchState);

    return BlocListener<SearchBloc, SearchState>(
      listener: (context, state) {
        if (state is PostCreateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Успішно опубліковано!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
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
      child: Scaffold(
        backgroundColor: _bgDark,
        appBar: AppBar(
          backgroundColor: _bgDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            trans['title'] ?? "Створити пост",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoSelector(),
                const SizedBox(height: 25),

                _buildFilterGrid(availableFilters, trans),

                const SizedBox(height: 20),
                _buildStyledTextField(
                  label: trans['tytul'] ?? "Заголовок",
                  onChanged: (v) => _title = v,
                ),

                const SizedBox(height: 20),
                _buildStyledTextField(
                  label: trans['text'] ?? "Опишіть вашу ситуацію...",
                  maxLines: 7,
                  onChanged: (v) => _text = v,
                ),

                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= FILTERS =================

  Widget _buildFilterGrid(List<FilterModel> filters, Map<String, dynamic> trans) {
    if (filters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    final actionFilter = filters.firstWhere(
      (f) => f.label.toLowerCase().contains('do') ||
             f.label.toLowerCase().contains('choic'),
      orElse: () => filters[0],
    );

    final subCatFilter = filters.length > 1 ? filters[1] : null;

    final regionFilter = filters.firstWhere(
      (f) => f.label.toLowerCase().contains('regio') ||
             f.label.toLowerCase().contains('local'),
      orElse: () => filters.last,
    );

    return Column(
      children: [
        // STATUS (choice_id)
        _buildFilterDropdown(
          filter: actionFilter,
          selectedValue: _actionId,
          onChanged: (val) => setState(() => _actionId = val),
        ),

        const SizedBox(height: 16),

        // SUBCATEGORY (cat_id / live_id / phone_id)
        if (subCatFilter != null)
          _buildFilterDropdown(
            filter: subCatFilter,
            selectedValue: _choiceId,
            onChanged: (val) => setState(() => _choiceId = val),
          ),

        const SizedBox(height: 16),

        // REGION
        _buildFilterDropdown(
          filter: regionFilter,
          selectedValue: _localId,
          onChanged: (val) => setState(() => _localId = val),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required FilterModel filter,
    required int? selectedValue,
    required Function(int?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<int>(
          value: selectedValue,
          items: filter.options?.map((opt) => DropdownMenuItem<int>(
            value: opt.id,
            child: Text(
              opt.label,
              style: const TextStyle(color: Colors.white),
            ),
          )).toList() ?? [],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Обов\'язково' : null,
          dropdownColor: _cardDark,
          icon: Icon(Icons.expand_more, color: _accentOrange),
          decoration: InputDecoration(
            labelText: filter.label,
            labelStyle: TextStyle(color: _textMuted),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // ================= SUBMIT =================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            context.read<SearchBloc>().add(CreatePost(
              category: _category,
              title: _title,
              text: _text,
              localId: _localId!,

              // ✅ FIX (КЛЮЧЕВОЙ)
              choiceId: _actionId!,   // статус
              catId: _choiceId,       // подкатегория

              locale: context.read<SearchBloc>().currentLocale,
              imagePaths: _images.map((e) => e.path).toList(),
            ));
          }
        },
        child: const Text(
          "ОПУБЛІКУВАТИ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ================= UI =================

  Widget _buildPhotoSelector() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length < 4 ? _images.length + 1 : 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == _images.length && _images.length < 4) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.add_a_photo, color: _accentOrange),
              ),
            );
          }
          return Image.file(
            File(_images[index].path),
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget _buildStyledTextField({
    required String label,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      maxLines: maxLines,
      onChanged: onChanged,
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Заповніть поле' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ================= DATA =================

  Map<String, dynamic> _getTranslations(SearchState state) {
    if (state is FiltersLoaded) return state.uiTranslations;
    if (state is SearchSuccess) return state.uiTranslations;
    if (state is PostDetailsLoaded) return state.uiTranslations;
    return {};
  }

  List<FilterModel> _getFilters(SearchState state) {
    if (state is FiltersLoaded) return state.filters;
    if (state is SearchSuccess) return state.filters;
    if (state is PostDetailsLoaded) return state.filters;
    return [];
  }
}