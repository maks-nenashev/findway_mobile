import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_state.dart';

class SearchDetailsPage extends StatelessWidget {
  const SearchDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is PostDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PostDetailsLoaded) {
            final post = state.post;
            final tr = state.uiTranslations;

            return CustomScrollView(
              slivers: [
                // 1. ГАЛЕРЕЯ
                SliverAppBar(
                  expandedHeight: 350.0,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (post.images.isNotEmpty)
                          Image.network(
                            post.images.first, 
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                          )
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
                ),

                // 2. КОНТЕНТНАЯ ЧАСТЬ
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Автор
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueGrey[50],
                              backgroundImage: post.author.avatarUrl != null 
                                  ? NetworkImage(post.author.avatarUrl!) 
                                  : null,
                              child: post.author.avatarUrl == null 
                                  ? const Icon(Icons.person, color: Colors.grey) 
                                  : null,
                              radius: 20,
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
                        ),
                        const Divider(height: 32),

                        // Заголовок и Текст
                        Text(post.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text(post.text, style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
                        
                        const SizedBox(height: 16),
                        // Локация
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blueAccent, size: 18),
                            const SizedBox(width: 4),
                            Text(post.local, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // CONTROL PANEL
                        Row(
                          children: [
                            // Теперь этот вызов НЕ БУДЕТ выдавать ошибку
                            _actionButton(Icons.arrow_back, Colors.white, () {
                              Navigator.pop(context);
                            }, bgColor: const Color(0xFF0A0E14)), 
                            
                            const SizedBox(width: 12),
                            
                            _actionButton(Icons.alternate_email, Colors.cyan, () {
                              debugPrint("Open Message Form");
                            }),
                            
                            const SizedBox(width: 12),
                            
                            _actionButton(Icons.chat_bubble_outline, Colors.orange, () {
                              debugPrint("Open Comment Form");
                            }),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        Text(tr['comments_title'] ?? "Comments", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 3. СПИСОК КОММЕНТАРИЕВ
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final comment = post.comments[index];
                      return _CommentNode(comment: comment);
                    },
                    childCount: post.comments.length,
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 50)),
              ],
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

  // --- ВОТ ЭТО И ЕСТЬ "НИЗ" КЛАССА SearchDetailsPage ---

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.blueGrey[100], 
      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey)
    );
  }

  // ОБНОВЛЕННЫЙ МЕТОД (Теперь принимает bgColor)
  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {Color? bgColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          // Логика: если bgColor есть (черная кнопка), берем его. 
          // Если нет (цветные кнопки) — берем color с прозрачностью.
          color: bgColor ?? color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: bgColor != null ? color.withOpacity(0.5) : color.withOpacity(0.5), 
            width: 2
          ),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

// Отдельный класс для комментариев (вне SearchDetailsPage)
class _CommentNode extends StatelessWidget {
  final dynamic comment;
  const _CommentNode({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.blueGrey[50],
            backgroundImage: comment.avatar != null ? NetworkImage(comment.avatar) : null,
            child: comment.avatar == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(comment.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(comment.date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}