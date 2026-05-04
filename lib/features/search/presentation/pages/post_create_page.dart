import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart'; // ✅ ДОБАВЛЕНО
import 'package:google_fonts/google_fonts.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../../data/models/filter_model.dart';

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
  final Color _textMuted = Colors.white54;

  late String _category;

  String _title = '';
  String _text = '';

  int? _localId;
  int? _choiceId;
  int? _actionId;

  List<File> _images = [];

  Map<String, dynamic> _translations = {};
  List<FilterModel> _filters = [];

  final Map<String, String> _fallback = const {
    'title': 'New post!',
    'tytul_2': 'Title',
    'text_2': 'Text',
    'submit_article': 'Submit',
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

  // ================= MOBILE PICKER =================
  Future<void> _pickImagesMobile() async {
    final selected = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1440,
    );

    if (selected.isNotEmpty) {
      setState(() {
        _images = [
          ..._images,
          ...selected.map((e) => File(e.path))
        ].take(4).toList();
      });
    }
  }

  // ================= DESKTOP PICKER (НОВОЕ) =================
  Future<void> _pickImagesDesktop() async {
    final typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png'],
    );

    final files = await openFiles(acceptedTypeGroups: [typeGroup]);

    if (files.isNotEmpty) {
      setState(() {
        _images = [
          ..._images,
          ...files.map((f) => File(f.path))
        ].take(4).toList();
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
          
          // =========================================================
          // 👉 ИСПРАВЛЕНИЕ: Передаем ID нового поста на главную страницу
          // =========================================================
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
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPhotos(),
                        const SizedBox(height: 24),
                        _buildFilters(),
                        const SizedBox(height: 20),
                        _input(tr('tytul_2'), (v) => _title = v),
                        const SizedBox(height: 20),
                        _input(tr('text_2'), (v) => _text = v, max: 6),
                        const SizedBox(height: 40),
                        _submitButton(),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  // ================= UI =================

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
              // ✅ ВОТ ЕДИНСТВЕННОЕ ИЗМЕНЕНИЕ ЛОГИКИ
              onTap: () async {
                try {
                  await _pickImagesDesktop(); // пробуем desktop
                } catch (_) {
                  await _pickImagesMobile(); // fallback
                }
              },
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

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              _images[i],
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
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
                      child: Text(e.label,
                          style: const TextStyle(color: Colors.white)),
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
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          context.read<SearchBloc>().add(CreatePost(
                category: _category,
                title: _title,
                text: _text,
                localId: _localId!,
                choiceId: _actionId!,
                catId: _choiceId,
                locale: context.read<SearchBloc>().currentLocale,
                imagePaths: _images.map((e) => e.path).toList(),
              ));
        }
      },
      child: Text(tr('submit_article')),
    );
  }
}