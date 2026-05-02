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
        await repository.addComment(parentId, type, event.body);

        final comments = await repository.getComments(parentId, type);

        emit(CommentsLoaded(
          comments,
          message: "Коментар створено",
          warning: null, // 👉 или логика с published
        ));

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

        final updatedList =
            oldComments.where((c) => c.id != event.commentId).toList();

        emit(currentState.copyWith(comments: updatedList));

        try {
          await repository.deleteComment(event.commentId);

          emit(currentState.copyWith(
            comments: updatedList,
            message: "Коментар видалено",
          ));

        } catch (e) {
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
    final result = await repository.updateComment(
      event.commentId,
      event.newBody,
    );

    final comments = await repository.getComments(parentId, type);

    /// 🔥 логика от сервера (а не хардкод)
    final isPublished = result['published'] == true;

    emit(CommentsLoaded(
      comments,
      message: "Коментар оновлено",
      warning: isPublished
          ? null
          : "Коментар відправлено на модерацію",
    ));

  } catch (e) {
    emit(CommentsError(e.toString()));
  }
});
  }
}