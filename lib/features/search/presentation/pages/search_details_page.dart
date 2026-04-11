import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_state.dart';
import '../../../../features/comments/presentation/bloc/comments_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_event.dart';
import '../../../../features/comments/presentation/bloc/comments_state.dart';
import '../../../../features/comments/data/models/comment_model.dart';
import '../../../../injection_container.dart';

class SearchDetailsPage extends StatelessWidget {
  const SearchDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is PostDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostDetailsLoaded) {
            final post = state.post;
            final tr = state.uiTranslations;

            // ✅ ШАГ 1: Поднимаем провайдер на уровень всей страницы
            return BlocProvider(
              create: (context) => sl<CommentsBloc>(
                param1: post.id,
                param2: _mapCategory(post.category),
              )..add(const FetchComments()),
              child: Builder(
                builder: (pageContext) { // pageContext теперь видит CommentsBloc
                  return CustomScrollView(
                    slivers: [
                      // 1. ГАЛЕРЕЯ
                      _buildGallery(post),

                      // 2. КОНТЕНТНАЯ ЧАСТЬ ПОСТА
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
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                post.text,
                                style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                              ),
                              const SizedBox(height: 16),
                              _buildLocationRow(post),
                              const SizedBox(height: 24),
                              // ✅ Передаем pageContext в панель управления
                              _buildControlPanel(pageContext, tr),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),

                     // 3. СЕКЦИЯ КОММЕНТАРИЕВ
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    // Просто вызываем метод списка. 
    // Вся логика Padding и Column должна быть внутри самого метода/виджета.
    child: _buildCommentsList(), 
  ),
),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  );
                },
              ),
            );
          }

          if (state is SearchError) {
            return Center(child: Text("Помилка: ${state.message}", style: const TextStyle(color: Colors.red)));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ========== ЛОГИКА И ОКНА ==========

  String _mapCategory(String? rawType) {
    final type = rawType?.toLowerCase() ?? 'article';
    if (type == 'article' || type == 'people') return 'people';
    if (type == 'sense' || type == 'animal' || type == 'animals') return 'animals';
    if (type == 'thing' || type == 'things') return 'things';
    return 'people';
  }

  void _showCommentSheet(BuildContext context, Map<String, dynamic> tr) {
  final controller = TextEditingController();
  final bloc = context.read<CommentsBloc>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr['new_comment_title'] ?? "НОВИЙ КОМЕНТАР",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: tr['write_something'] ?? "Напишіть щось...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(AddComment(controller.text.trim()));
                Navigator.pop(context);
              }
            }, // ✅ Все скобки на месте
            child: Text(
              tr['submit_comment'] ?? "ВІДПРАВИТИ",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ========== BUILDER-МЕТОДЫ ==========

  Widget _buildGallery(dynamic post) {
    return SliverAppBar(
      expandedHeight: 350.0,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E14),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (post.images.isNotEmpty)
              Image.network(post.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildImagePlaceholder())
            else
              _buildImagePlaceholder(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                  stops: [0.0, 0.3],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, Map<String, dynamic> tr) { // ✅ Теперь он "знает" про tr
    return Row(
      children: [
        _actionButton(Icons.arrow_back, Colors.white, () => Navigator.pop(context), bgColor: const Color(0xFF0A0E14)),
        const SizedBox(width: 12),
        _actionButton(Icons.alternate_email, Colors.cyan, () => debugPrint("Email Click")),
        const SizedBox(width: 12),
        // ✅ ОРАНЖЕВАЯ КНОПКА ТЕПЕРЬ РАБОТАЕТ
        _actionButton(
          Icons.chat_bubble_outline, 
          Colors.orange, 
          () => _showCommentSheet(context, tr), // ✅ Передаем tr в метод показа комментариев
        ),
      ],
    );
  }

  Widget _buildCommentsList() {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        if (state is CommentsLoaded) {
          if (state.comments.isEmpty) {
            return const Center(child: Text("Коментарів ще немає", style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: state.comments.length,
            itemBuilder: (context, index) => _CommentNode(comment: state.comments[index]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }


  Widget _buildAuthorHeader(dynamic post) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: post.author.avatarUrl != null ? NetworkImage(post.author.avatarUrl!) : null,
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

  Widget _buildImagePlaceholder() {
    return Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported));
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {Color? bgColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: bgColor ?? color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// ========== ВИДЖЕТ КОММЕНТАРИЯ (Node) ==========

class _CommentNode extends StatelessWidget {
  final CommentModel comment;
  const _CommentNode({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: comment.avatarUrl != null ? NetworkImage(comment.avatarUrl!) : null,
            child: comment.avatarUrl == null ? const Icon(Icons.person, size: 20) : null,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(comment.createdAt, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.body, style: const TextStyle(fontSize: 14)),
                  // ✅ ИСПРАВЛЕНО: Используем именованный параметр
                  if (comment.canDelete)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.read<CommentsBloc>().add(DeleteComment(commentId: comment.id)),
                        child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}