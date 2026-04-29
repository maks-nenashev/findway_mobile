import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../../../../features/comments/presentation/bloc/comments_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_event.dart';
import '../../../../injection_container.dart';

import '../widgets/post_button_panel.dart';
import '../widgets/comments_section.dart';

class PostCardPage extends StatelessWidget {
  const PostCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: BlocListener<SearchBloc, SearchState>(
        listener: (context, state) {
        // В BlocListener (PostCardPage)
if (state is PostDeleteSuccess) {
  // Мы явно берем переводы из пришедшего стейта
  final msg = state.uiTranslations['destroy_success'] ?? "Deleted successfully!";
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg), // ✅ НИКОГДА не используем const здесь
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

              return BlocProvider(
                create: (context) => sl<CommentsBloc>(
                  param1: post.id,
                  param2: _mapCategory(post.category),
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
                                  post.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  post.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildLocationRow(post),
                                const SizedBox(height: 24),
                                
                                PostButtonPanel(
                                  tr: tr,
                                  onCommentTap: () =>
                                      CommentsSection.showAddCommentSheet(pageContext, tr),
                                  onEditTap: () => debugPrint("Edit Post Click"),
                                  onDeleteTap: () => _showDeleteConfirmation(
                                    context,
                                    post.id,
                                    post.category ?? 'people',
                                    tr, // Передаем словарь в диалог
                                  ),
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

  String _mapCategory(String? rawType) {
    final type = rawType?.toLowerCase() ?? 'article';
    if (type == 'article' || type == 'people') return 'people';
    if (type == 'sense' || type == 'animal' || type == 'animals') return 'animals';
    if (type == 'thing' || type == 'things') return 'things';
    return 'people';
  }

  Widget _buildGallery(dynamic post) {
    return SliverAppBar(
      expandedHeight: 350.0,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E14),
      flexibleSpace: FlexibleSpaceBar(
        background: _PostDetailsGallery(
          images: post.images != null ? List<String>.from(post.images) : [],
        ),
      ),
    );
  }

  Widget _buildAuthorHeader(dynamic post) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: post.author.avatarUrl != null
              ? NetworkImage(post.author.avatarUrl!)
              : null,
          child: post.author.avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("POSTED BY", style: TextStyle(fontSize: 10, color: Colors.grey)),
            Text(post.author.username, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const Spacer(),
        Text(post.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildLocationRow(dynamic post) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.blueAccent, size: 18),
        const SizedBox(width: 4),
        Text(post.local, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
      ],
    );
  }

  // ✅ ИСПРАВЛЕННЫЙ МЕТОД УДАЛЕНИЯ С ПОДХВАТОМ ПЕРЕВОДОВ
  void _showDeleteConfirmation(
    BuildContext context,
    int postId,
    String category,
    Map<String, dynamic> trData, // Получаем словарь переводов из билдера
  ) {
    final searchBloc = context.read<SearchBloc>();

    // Вспомогательная функция для ключей delete.title и т.д.
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
}

// Вспомогательный виджет галереи
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
  void initState() { super.initState(); _pageController = PageController(); }
  @override
  void dispose() { _pageController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported, size: 50));
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (page) => setState(() => _currentPage = page),
          itemBuilder: (context, index) => Image.network(widget.images[index], fit: BoxFit.cover),
        ),
        Positioned(
          bottom: 20, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4, width: index == _currentPage ? 16 : 4,
              decoration: BoxDecoration(
                color: index == _currentPage ? const Color(0xFF00F2FF) : Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
          ),
        ),
      ],
    );
  }
}