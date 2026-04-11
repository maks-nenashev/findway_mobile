import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart';
import '../../data/models/comment_model.dart';
import '../bloc/comments_bloc.dart';
import '../bloc/comments_event.dart';
import '../bloc/comments_state.dart';

class CommentsSection extends StatelessWidget {
  final int postId;
  final String category;

  const CommentsSection({
    required this.postId,
    required this.category,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<CommentsBloc>(param1: postId, param2: category)..add(FetchComments()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _CommentInput(),
          const SizedBox(height: 24),
          _CommentsList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF8A00)),
        const SizedBox(width: 10),
        Text(
          "КОМЕНТАРІ",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CommentInput extends StatefulWidget {
  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFF8A00).withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Напишіть щось...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          contentPadding: const EdgeInsets.all(16),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFFF8A00)),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                context.read<CommentsBloc>().add(AddComment(text));
                controller.clear();
              }
            },
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _CommentsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) return const Center(child: CircularProgressIndicator());
        if (state is CommentsError) return Text(state.message, style: const TextStyle(color: Colors.red));
        if (state is CommentsLoaded) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.comments.length,
            itemBuilder: (context, index) => _CommentCard(comment: state.comments[index]),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CommentCard extends StatelessWidget {
  final CommentModel comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    const Color neonOrange = Color(0xFFFF8A00);
    const Color darkSlate = Color(0xFF1E293B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkSlate.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonOrange.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: neonOrange.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: comment.avatarUrl != null
                    ? NetworkImage(comment.avatarUrl!)
                    : null,
                child: comment.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    comment.createdAt,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 8),
            child: Text(
              comment.body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          if (comment.canEdit || comment.canDelete)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 12),
              child: Row(
                children: [
                  if (comment.canEdit)
                    _buildActionButton(
                      icon: Icons.edit_note,
                      label: "РЕДАГУВАТИ",
                      onTap: () {
                        // TODO: логика редактирования
                      },
                    ),
                  if (comment.canEdit && comment.canDelete)
                    const SizedBox(width: 16),
                  if (comment.canDelete)
                    _buildActionButton(
                      icon: Icons.delete_sweep,
                      label: "ВИДАЛИТИ",
                      isDelete: true,
                      onTap: () => _confirmDelete(context),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDelete = false,
  }) {
    final Color color = isDelete ? Colors.redAccent : const Color(0xFF00F2FF);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    context.read<CommentsBloc>().add(DeleteComment(comment.id));
  }
}