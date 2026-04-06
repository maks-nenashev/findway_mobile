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

            return CustomScrollView(
              slivers: [
                // 1. ГАЛЕРЕЯ
                SliverAppBar(
                  expandedHeight: 350.0,
                  pinned: true,
                  backgroundColor: const Color(0xFF0A0E14),
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
                        _buildControlPanel(context),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // 3. ДИНАМИЧЕСКАЯ СЕКЦИЯ КОММЕНТАРИЕВ
                SliverToBoxAdapter(
                  child: BlocProvider(
                    create: (context) {
                      final rawType = post.category ?? 'Article';
                      String mappedCategory;

                      switch (rawType.toLowerCase()) {
                        case 'article':
                        case 'people':
                          mappedCategory = 'people';
                          break;
                        case 'sense':
                        case 'animal':
                        case 'animals':
                          mappedCategory = 'animals';
                          break;
                        case 'thing':
                        case 'things':
                          mappedCategory = 'things';
                          break;
                        default:
                          mappedCategory = 'people';
                      }

                      debugPrint("🔍 FINAL_ROUTE_CHECK: ID=${post.id}, ReceivedRaw=$rawType, MappedTo=$mappedCategory");

                      return sl<CommentsBloc>(
                        param1: post.id,
                        param2: mappedCategory,
                      )..add(const FetchComments());
                    },
                    child: Builder(
                      builder: (innerContext) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr['comments_title'] ?? "Comments",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildCommentInputField(innerContext, tr),
                              const SizedBox(height: 24),
                              BlocBuilder<CommentsBloc, CommentsState>(
                                builder: (context, state) {
                                  if (state is CommentsLoading) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(color: Colors.orange),
                                      ),
                                    );
                                  }
                                  if (state is CommentsLoaded) {
                                    if (state.comments.isEmpty) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 40),
                                        child: Center(
                                          child: Text(
                                            "Коментарів ще немає. Будьте першим!",
                                            style: TextStyle(color: Colors.grey, fontSize: 14),
                                          ),
                                        ),
                                      );
                                    }
                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: EdgeInsets.zero,
                                      itemCount: state.comments.length,
                                      itemBuilder: (context, index) => _CommentNode(comment: state.comments[index]),
                                    );
                                  }
                                  if (state is CommentsError) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Ошибка загрузки: ${state.message}",
                                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 4. ТЕХНИЧЕСКИЕ ОТСТУПЫ
                const SliverToBoxAdapter(child: SizedBox(height: 50)),

                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                ),
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

  // ========== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ (Внутри класса) ==========

  Widget _buildAuthorHeader(dynamic post) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blueGrey[50],
          backgroundImage: post.author.avatarUrl != null ? NetworkImage(post.author.avatarUrl!) : null,
          child: post.author.avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
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

  Widget _buildControlPanel(BuildContext context) {
    return Row(
      children: [
        _actionButton(Icons.arrow_back, Colors.white, () => Navigator.pop(context), bgColor: const Color(0xFF0A0E14)),
        const SizedBox(width: 12),
        _actionButton(Icons.alternate_email, Colors.cyan, () => debugPrint("Message Form")),
        const SizedBox(width: 12),
        _actionButton(Icons.chat_bubble_outline, Colors.orange, () => debugPrint("Comment Form")),
      ],
    );
  }

  Widget _buildCommentInputField(BuildContext context, Map<String, dynamic> tr) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: tr['place_writhe'] ?? "Add a comment...",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send, color: Colors.orange),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              context.read<CommentsBloc>().add(AddComment(controller.text));
              controller.clear();
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.blueGrey[100],
      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap, {Color? bgColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
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
                  if (comment.canDelete)
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => context.read<CommentsBloc>().add(DeleteComment(comment.id)),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        ),
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