import 'package:flutter_bloc/flutter_bloc.dart';
import 'comments_event.dart';
import 'comments_state.dart';
import '../../domain/repositories/comment_repository.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final CommentRepository repository;
  final int parentId;
  final String type;

  CommentsBloc({
    required this.repository,
    required this.parentId,
    required this.type,
  }) : super(CommentsInitial()) {

    /// ==============================
    /// FETCH
    /// ==============================
    on<FetchComments>((event, emit) async {
      emit(CommentsLoading());

      try {
        final comments = await repository.getComments(parentId, type);
        emit(CommentsLoaded(comments));
      } catch (e) {
        emit(CommentsError(e.toString()));
      }
    });

    /// ==============================
    /// ADD
    /// ==============================
    on<AddComment>((event, emit) async {
      try {
        final response = await repository.addComment(
          parentId,
          type,
          event.body,
        );

        /// 🔥 правильная логика модерации (ключ, не текст!)
        final warningKey = response['published'] == false
            ? (response['moderation_status'] == 'rejected'
                ? 'rejected'
                : 'pending')
            : null;

        emit(CommentActionSuccess(
          success: response['success'],
          warning: warningKey,
        ));

        add(const FetchComments());

      } catch (e) {
        emit(CommentsError(e.toString()));
      }
    });

    /// ==============================
    /// DELETE
    /// ==============================
    on<DeleteComment>((event, emit) async {
      final currentState = state;

      if (currentState is CommentsLoaded) {
        final oldComments = currentState.comments;

        /// ⚡ optimistic UI
        final updatedList =
            oldComments.where((c) => c.id != event.commentId).toList();

        emit(currentState.copyWith(comments: updatedList));

        try {
          final response =
              await repository.deleteComment(event.commentId);

          emit(CommentActionSuccess(
            success: response['success'], // ✅ из API
          ));

        } catch (e) {
          /// rollback
          emit(CommentsLoaded(oldComments));
          emit(CommentsError(e.toString()));
        }
      }
    });

    /// ==============================
    /// UPDATE
    /// ==============================
    on<UpdateComment>((event, emit) async {
      try {
        final response = await repository.updateComment(
          event.commentId,
          event.newBody,
        );

        final warningKey = response['published'] == false
            ? (response['moderation_status'] == 'rejected'
                ? 'rejected'
                : 'pending')
            : null;

        emit(CommentActionSuccess(
          success: response['success'],
          warning: warningKey,
        ));

        add(const FetchComments());

      } catch (e) {
        emit(CommentsError(e.toString()));
      }
    });
  }
}