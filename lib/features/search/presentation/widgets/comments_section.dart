import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_bloc.dart';
import '../../../../features/comments/presentation/bloc/comments_event.dart';
import '../../../../features/comments/presentation/bloc/comments_state.dart';
import '../../../../features/comments/data/models/comment_model.dart';

class CommentsSection extends StatelessWidget {
  final Map<String, dynamic> tr;

  const CommentsSection({super.key, required this.tr});

  // ✅ СТАТИЧЕСКИЙ МЕТОД: Теперь доступен из SearchDetailsPage
  static void showAddCommentSheet(BuildContext context, Map<String, dynamic> tr) {
    final controller = TextEditingController();
    final bloc = context.read<CommentsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr['your_comment'] ?? "Your Comment",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: tr['place_writhe'] ?? "Напишіть щось...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
              },
              child: Text(
                tr['submit_comment'] ?? "SUBMIT",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr['comments_title'] ?? "Comments",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        BlocBuilder<CommentsBloc, CommentsState>(
          builder: (context, state) {
            if (state is CommentsLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }
            if (state is CommentsLoaded) {
              if (state.comments.isEmpty) {
                return const Center(
                  child: Text("No comments yet", style: TextStyle(color: Colors.grey)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: state.comments.length,
                itemBuilder: (context, index) => _CommentNode(
                  comment: state.comments[index],
                  tr: tr,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

class _CommentNode extends StatelessWidget {
  final CommentModel comment;
  final Map<String, dynamic> tr;
  const _CommentNode({required this.comment, required this.tr});

  // ✅ ЛОКАЛЬНЫЙ МЕТОД: Теперь доступен внутри _CommentNode
  void _showEditCommentSheet(BuildContext context, CommentModel comment, Map<String, dynamic> tr) {
    final controller = TextEditingController(text: comment.body);
    final bloc = context.read<CommentsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr['edit_comment'] ?? "Редагувати",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty && controller.text != comment.body) {
                  bloc.add(UpdateComment(
                    commentId: comment.id,
                    newBody: controller.text.trim(),
                  ));
                }
                Navigator.pop(context);
              },
              child: Text(
                tr['save_comment'] ?? "ЗБЕРЕГТИ",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      Text(
                        comment.username,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        comment.createdAt,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.body, style: const TextStyle(fontSize: 14)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (comment.canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                          onPressed: () => _showEditCommentSheet(context, comment, tr),
                        ),
                      if (comment.canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          onPressed: () => context.read<CommentsBloc>().add(
                                DeleteComment(commentId: comment.id),
                              ),
                        ),
                    ],
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