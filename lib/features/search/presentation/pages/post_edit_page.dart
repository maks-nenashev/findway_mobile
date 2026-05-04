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

class PostEditPage extends StatefulWidget {
  final int postId;
  final String initialCategory;
  final String initialTitle;
  final String initialText;
  final int? initialLocalId;
  final int? initialChoiceId;
  final int? initialActionId;
  final List<String> existingImages; // URL картинки, которые уже есть на сервере

  const PostEditPage({
    super.key,
    required this.postId,
    required this.initialCategory,
    required this.initialTitle,
    required this.initialText,
    this.initialLocalId,
    this.initialChoiceId,
    this.initialActionId,
    this.existingImages = const [],
  });

  @override
  State<PostEditPage> createState() => _PostEditPageState();
}

class _PostEditPageState extends State<PostEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final Color _bgDark = const Color(0xFF0F172A);
  final Color _cardDark = const Color(0xFF1E293B);
  final Color _accentOrange = const Color(0xFFFF9800);
  final Color _textMuted = Colors.white54;

  late String _category;
  late String _title;
  late String _text;

  int? _localId;
  int? _choiceId;
  int? _actionId;

  // Разделяем существующие (URL) и новые (File) картинки
  late List<String> _existingImages;
  List<File> _newImages = [];

  Map<String, dynamic> _translations = {};
  List<FilterModel> _filters = [];

  final Map<String, String> _fallback = const {
    'title': 'Edit post',
    'tytul_2': 'Title',
    'text_2': 'Text',
    'submit_article': 'Update',
  };

  @override
  void initState() {
    super.initState();
    
    // Инициализация (Hydration) текущими данными
    _category = widget.initialCategory;
    _title = widget.initialTitle;
    _text = widget.initialText;
    _localId = widget.initialLocalId;
    _choiceId = widget.initialChoiceId;
    _actionId = widget.initialActionId;
    _existingImages = List.from(widget.existingImages);

    final bloc = context.read<SearchBloc>();
    bloc.add(LoadFilters(
      category: _category,
      locale: bloc.currentLocale,
    ));
  }

  String tr(String key) {
    return (_translations[key] ?? _fallback[key] ?? key).toString();
  }

  // Общее количество фото не должно превышать 4
  int get _totalPhotosCount => _existingImages.length + _newImages.length;

  // ================= PICKERS =================
  Future<void> _pickImagesMobile() async {
    if (_totalPhotosCount >= 4) return;
    
    final selected = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1440,
    );

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

    final typeGroup = XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png'],
    );

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

  // ================= BUILDER =================
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

        // Внимание: Нужно добавить PostUpdateSuccess в BLoC
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
                        // Передаем initialValue для заполнения
                        _input(tr('tytul_2'), widget.initialTitle, (v) => _title = v),
                        const SizedBox(height: 20),
                        _input(tr('text_2'), widget.initialText, (v) => _text = v, max: 6),
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

  // ================= UI COMPONENTS =================

  Widget _buildPhotos() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 1. Рендерим старые картинки (с сервера)
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

          // 2. Рендерим новые локальные картинки
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

          // 3. Кнопка добавления (если лимит 4 не достигнут)
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
                ),
                child: Icon(Icons.add_a_photo, color: _accentOrange),
              ),
            ),
        ],
      ),
    );
  }

  // Вспомогательный виджет для удаления картинок
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

  // Добавлен initialValue для предзаполнения
  Widget _input(String hint, String initial, Function(String) onChanged, {int max = 1}) {
    return TextFormField(
      initialValue: initial, 
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
          // Внимание: Здесь вызывается UpdatePost вместо CreatePost
          context.read<SearchBloc>().add(UpdatePost(
                postId: widget.postId,
                category: _category,
                title: _title,
                text: _text,
                localId: _localId!,
                choiceId: _actionId!,
                catId: _choiceId,
                locale: context.read<SearchBloc>().currentLocale,
                existingImages: _existingImages, // передаем оставшиеся старые фото
                newImagePaths: _newImages.map((e) => e.path).toList(), // передаем новые
              ));
        }
      },
      child: Text(tr('submit_article')),
    );
  }
}