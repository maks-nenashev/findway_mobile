import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:findway_mobile/features/comments/presentation/bloc/comments_bloc.dart';
import 'package:findway_mobile/features/comments/presentation/bloc/comments_event.dart';
import 'package:findway_mobile/features/comments/presentation/bloc/comments_state.dart';
import 'package:findway_mobile/features/comments/data/models/comment_model.dart';

class CommentsSection extends StatelessWidget {
  final Map<String, dynamic> tr;

  const CommentsSection({
    super.key,
    required this.tr,
  });

  /// =========================
  /// ADD COMMENT (НЕ ТРОГАЕМ UI)
  /// =========================
  static void showAddCommentSheet(
      BuildContext context, Map<String, dynamic> tr) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr['your_comment'] ?? "Your Comment",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: tr['place_writhe'] ?? "Напишіть щось...",
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.3)),
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
                ),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    context.read<CommentsBloc>().add(AddComment(text));
                    Navigator.pop(sheetContext);
                  }
                },
                child: Text(
                  tr['submit_comment'] ?? "SUBMIT",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// =========================
  /// MAIN UI
  /// =========================
  @override
  Widget build(BuildContext context) {
    return BlocListener<CommentsBloc, CommentsState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        /// ✅ SUCCESS
        if (state is CommentActionSuccess) {
          if (state.success != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.success!),
                backgroundColor: Colors.green,
              ),
            );
          }

          if (state.warning != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.warning!),
                backgroundColor: Colors.orange,
              ),
            );
          }

          context.read<CommentsBloc>().add(const FetchComments());
        }

        /// ✅ ERROR
        if (state is CommentsError) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }, // ✅ ВАЖНО: закрыли listener

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr['comments_title'] ?? "Comments",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          BlocBuilder<CommentsBloc, CommentsState>(
            builder: (context, state) {
              if (state is CommentsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: Colors.orange),
                );
              }

              if (state is CommentsLoaded) {
                if (state.comments.isEmpty) {
                  return const Center(
                    child: Text("No comments yet",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
      ),
    );
  }
}

/// =========================
/// COMMENT NODE (НЕ ЛОМАЕМ UI)
/// =========================
class _CommentNode extends StatelessWidget {
  final CommentModel comment;
  final Map<String, dynamic> tr;

  const _CommentNode({
    required this.comment,
    required this.tr,
  });

  void _showEditCommentSheet(BuildContext context) {
    final controller = TextEditingController(text: comment.body);
    final bloc = context.read<CommentsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr['edit_comment'] ?? "Редагувати",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
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
              ),
              onPressed: () {
                final text = controller.text.trim();

                if (text.isNotEmpty && text != comment.body) {
                  bloc.add(UpdateComment(
                    commentId: comment.id,
                    newBody: text,
                  ));
                }

                Navigator.pop(sheetContext);
              },
              child: Text(tr['save_comment'] ?? "ЗБЕРЕГТИ"),
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
            radius: 18,
            backgroundImage: comment.avatarUrl != null
                ? NetworkImage(comment.avatarUrl!)
                : null,
            child: comment.avatarUrl == null
                ? const Icon(Icons.person, size: 18)
                : null,
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
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(comment.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text(comment.createdAt,
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.body),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (comment.canEdit)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18,
                              color: Colors.blueAccent),
                          onPressed: () =>
                              _showEditCommentSheet(context),
                        ),
                      if (comment.canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18,
                              color: Colors.redAccent),
                          onPressed: () => context
                              .read<CommentsBloc>()
                              .add(DeleteComment(
                                  commentId: comment.id)),
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