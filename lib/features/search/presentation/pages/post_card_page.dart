// lib/features/search/presentation/pages/post_card_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../../../../features/comments/presentation/bloc/comments_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_event.dart';
import '../../../../injection_container.dart';

import '../widgets/post_button_panel.dart';
import '../widgets/map/show_map_widget.dart';
import 'package:findway_mobile/features/comments/presentation/widgets/comments_section.dart';

class PostCardPage extends StatelessWidget {
  const PostCardPage({super.key});

  void _onEditTapped(BuildContext context, dynamic post, SearchBloc searchBloc) async {
    final String category = _getSafeString(post, 'category', fallback: 'people');
    final int postId = _getSafeInt(post, 'id');

    await Navigator.pushNamed(context, '/post_edit', arguments: {
      'bloc': searchBloc,
      'postId': postId,
      'initialCategory': category,
      'initialTitle': _getSafeString(post, 'title'),
      'initialText': _getSafeString(post, 'text'),
      'initialLocalId': null, 
      'initialChoiceId': null,
      'initialActionId': null,
      'existingImages': _getSafeList(post, 'images'),
    });

    if (context.mounted) {
      searchBloc.add(LoadPostDetails(
        id: postId,
        category: category,
        locale: searchBloc.currentLocale,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: BlocListener<SearchBloc, SearchState>(
        listener: (context, state) {
          if (state is PostDeleteSuccess) {
            final msg = state.uiTranslations['post_destroy_success'] ?? "Deleted successfully!";
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is SearchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is PostDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PostDetailsLoaded) {
              final post = state.post;
              final tr = state.uiTranslations;
              final int postId = _getSafeInt(post, 'id');
              final String category = _getSafeString(post, 'category', fallback: 'people');

              final double? lat = _getSafeDouble(post, 'lat');
              final double? lng = _getSafeDouble(post, 'lng');


              final String address = _getSafeString(post, 'address');
              final String title = _getSafeString(post, 'title');

              return BlocProvider(
                create: (context) => sl<CommentsBloc>(
                  param1: postId,
                  param2: _mapCategory(category),
                )..add(const FetchComments()),
                child: Builder(
                  builder: (pageContext) {
                    return CustomScrollView(
                      slivers: [
                        _buildGallery(post),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAuthorHeader(post),
                                const Divider(height: 32),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _getSafeString(post, 'text'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Блок идентификторов животных (animal_metadata)
                                _buildAnimalMetadataCard(post, tr),

                                _buildLocationRow(post),
                                const SizedBox(height: 16),

                                // Интерактивная карта OpenStreetMap / Leaflet ( shared/map_show )
                                if (lat != null && lng != null)
                                  ShowMapWidget(
                                    lat: lat,
                                    lng: lng,
                                    title: title,
                                    address: address,
                                    translations: tr,
                                  ),

                                const SizedBox(height: 24),
                                PostButtonPanel(
                                  tr: tr,
                                  showEdit: _getCanEdit(post),
                                  showDelete: _getCanDelete(post),
                                  onCommentTap: () => CommentsSection.showAddCommentSheet(pageContext, tr),
                                  onEditTap: () => _onEditTapped(context, post, context.read<SearchBloc>()),
                                  onDeleteTap: () => _showDeleteConfirmation(context, postId, category, tr),
                                  onMessageTap: () {
                                    final searchBloc = context.read<SearchBloc>();
                                    final authorId = _getAuthorId(post);
                                    final authorName = _getAuthorName(post);
                                    final avatarUrl = _getAuthorAvatar(post);

                                    Navigator.pushNamed(context, '/chat', arguments: {
                                      'recipientId': authorId,
                                      'username': authorName,
                                      'avatarUrl': avatarUrl,
                                      'currentLocale': searchBloc.currentLocale,
                                    });
                                  },
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: CommentsSection(tr: tr),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Блок спецификаций животного (animal_metadata)
  // ---------------------------------------------------------------------------
  Widget _buildAnimalMetadataCard(dynamic post, Map<String, dynamic> tr) {
    final meta = _getAnimalMeta(post);
    if (meta.isEmpty) return const SizedBox.shrink();

    final String chip = meta['chip_number']?.toString().trim() ?? '';
    final String passport = meta['passport_number']?.toString().trim() ?? '';
    final String insurance = meta['insurance_policy_id']?.toString().trim() ?? '';

    if (chip.isEmpty && passport.isEmpty && insurance.isEmpty) {
      return const SizedBox.shrink();
    }

    final String headerTitle = tr['animal_identifiers'] ?? 
                                tr['senses.show.animal_identifiers'] ?? 
                                'ІДЕНТИФІКАТОРИ ТВАРИНИ';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00F2FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF00F2FF), size: 16),
              const SizedBox(width: 8),
              Text(
                headerTitle.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF00F2FF),
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 20),
          if (chip.isNotEmpty)
            _specRow('Microchip ID:', chip, const Color(0xFF00F2FF)),
          if (passport.isNotEmpty)
            _specRow('Passport / Reg №:', passport, Colors.amber),
          if (insurance.isNotEmpty)
            _specRow('Insurance Policy:', insurance, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontFamily: 'Monospace',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _mapCategory(String? rawType) {
    final type = rawType?.toLowerCase() ?? 'article';
    if (type == 'article' || type == 'people') return 'people';
    if (type == 'sense' || type == 'animal' || type == 'animals') return 'animals';
    if (type == 'thing' || type == 'things') return 'things';
    return 'people';
  }

  Widget _buildGallery(dynamic post) {
    final List<String> images = _getSafeList(post, 'images');
    return SliverAppBar(
      expandedHeight: 350.0,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E14),
      flexibleSpace: FlexibleSpaceBar(
        background: _PostDetailsGallery(images: images),
      ),
    );
  }

  Widget _buildAuthorHeader(dynamic post) {
    final String username = _getAuthorName(post);
    final String? avatarUrl = _getAuthorAvatar(post);
    final String createdAt = _getSafeString(post, 'created_at', fallback: _getSafeString(post, 'createdAt'));

    return Row(
      children: [
        CircleAvatar(
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("POSTED BY", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Spacer(),
        Text(createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildLocationRow(dynamic post) {
    final String localTitle = _getSafeString(post, 'local');
    if (localTitle.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 4),
        Text(
          localTitle, 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    int postId,
    String category,
    Map<String, dynamic> trData, 
  ) {
    final searchBloc = context.read<SearchBloc>();

    String t(String key, String fallback) {
      final fullKey = 'delete.$key';
      return (trData[fullKey] ?? trData[key] ?? fallback).toString();
    }

    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          t('delete_title', 'Delete?'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          t('delete_message', 'Are you sure?'),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: Text(
              t('cancel', 'CANCEL'),
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              searchBloc.add(DeletePost(postId: postId, category: category));
              Navigator.pop(confirmContext);
            },
            child: Text(
              t('confirm', 'DELETE'),
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Безопасные универсальные считыватели полей (Map & Dart Class Objects)
  // ---------------------------------------------------------------------------
  String _getSafeString(dynamic obj, String key, {String fallback = ''}) {
    if (obj == null) return fallback;
    try {
      if (obj is Map) return obj[key]?.toString() ?? fallback;
      final val = (obj as dynamic).toJson()[key] ?? (obj as dynamic).toString();
      return val.toString();
    } catch (_) {
      try {
        switch (key) {
          case 'title': return obj.title?.toString() ?? fallback;
          case 'text': return obj.text?.toString() ?? fallback;
          case 'category': return obj.category?.toString() ?? fallback;
          case 'local': return obj.local?.toString() ?? fallback;
          case 'address': return obj.address?.toString() ?? fallback;
          case 'created_at':
          case 'createdAt': return obj.createdAt?.toString() ?? obj.created_at?.toString() ?? fallback;
        }
      } catch (_) {}
    }
    return fallback;
  }

  int _getSafeInt(dynamic obj, String key) {
    if (obj == null) return 0;
    try {
      if (obj is Map) return int.tryParse(obj[key].toString()) ?? 0;
      return (obj.id as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  double? _getSafeDouble(dynamic obj, String key) {
    if (obj == null) return null;
    try {
      // 1. Проверка структуры Map
      if (obj is Map) {
        final v = obj[key] ??
            (key == 'lat' ? (obj['latitude'] ?? obj['lat']) : (obj['longitude'] ?? obj['lng']));
        if (v == null) return null;
        return double.tryParse(v.toString());
      }

      // 2. Проверка свойства Dart Class (например, PostModel)
      if (key == 'lat') {
        try { final v = (obj as dynamic).lat; if (v != null) return (v as num).toDouble(); } catch (_) {}
        try { final v = (obj as dynamic).latitude; if (v != null) return (v as num).toDouble(); } catch (_) {}
      } else if (key == 'lng') {
        try { final v = (obj as dynamic).lng; if (v != null) return (v as num).toDouble(); } catch (_) {}
        try { final v = (obj as dynamic).longitude; if (v != null) return (v as num).toDouble(); } catch (_) {}
      }

      // 3. Проверка через вызов toJson()
      try {
        final map = (obj as dynamic).toJson();
        if (map is Map) {
          final v = map[key] ?? (key == 'lat' ? map['latitude'] : map['longitude']);
          if (v != null) return double.tryParse(v.toString());
        }
      } catch (_) {}
    } catch (_) {}
    return null;
  }

  List<String> _getSafeList(dynamic obj, String key) {
    if (obj == null) return [];
    try {
      if (obj is Map) {
        final list = obj[key] as List?;
        return list?.map((e) => e.toString()).toList() ?? [];
      }
      if (obj.images != null) {
        return List<String>.from(obj.images);
      }
    } catch (_) {}
    return [];
  }

  Map<String, dynamic> _getAnimalMeta(dynamic obj) {
    if (obj == null) return {};
    try {
      if (obj is Map) {
        final meta = obj['animal_metadata'] ?? obj['animalMetadata'];
        if (meta is Map) return Map<String, dynamic>.from(meta);
      } else {
        final meta = obj.animalMetadata ?? obj.animal_metadata;
        if (meta is Map) return Map<String, dynamic>.from(meta);
      }
    } catch (_) {}
    return {};
  }

  bool _getCanEdit(dynamic obj) {
    try {
      if (obj is Map) return obj['permissions']?['can_edit'] == true;
      return obj.permissions.canEdit == true;
    } catch (_) {
      return false;
    }
  }

  bool _getCanDelete(dynamic obj) {
    try {
      if (obj is Map) return obj['permissions']?['can_delete'] == true;
      return obj.permissions.canDelete == true;
    } catch (_) {
      return false;
    }
  }

  int _getAuthorId(dynamic obj) {
    try {
      if (obj is Map) return int.tryParse(obj['author']?['id'].toString() ?? '0') ?? 0;
      return obj.author.id as int;
    } catch (_) {
      return 0;
    }
  }

  String _getAuthorName(dynamic obj) {
    try {
      if (obj is Map) return obj['author']?['username']?.toString() ?? 'Guest';
      return obj.author.username.toString();
    } catch (_) {
      return 'Guest';
    }
  }

  String? _getAuthorAvatar(dynamic obj) {
    try {
      if (obj is Map) return obj['author']?['avatar_url']?.toString();
      return obj.author.avatarUrl?.toString();
    } catch (_) {
      return null;
    }
  }
}

// =============================================================================
// ВСПОМОГАТЕЛЬНЫЙ ВИДЖЕТ ГАЛЕРЕИ ИЗОБРАЖЕНИЙ (_PostDetailsGallery)
// =============================================================================
class _PostDetailsGallery extends StatefulWidget {
  final List<String> images;
  const _PostDetailsGallery({required this.images});

  @override
  State<_PostDetailsGallery> createState() => _PostDetailsGalleryState();
}

class _PostDetailsGalleryState extends State<_PostDetailsGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image_not_supported, size: 50),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, index) => Image.network(
            widget.images[index], 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[800],
              child: const Icon(Icons.broken_image, color: Colors.white54, size: 40),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 4,
                width: index == _currentPage ? 16 : 4,
                decoration: BoxDecoration(
                  color: index == _currentPage ? const Color(0xFF00F2FF) : Colors.white54,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}