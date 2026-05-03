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

        // ✅ Ищем message от бэкенда. Fallback на success, если репо мапит странно.
        emit(CommentActionSuccess(
           success: (response['message'] ?? response['success'])?.toString(), 
           warning: response['warning']?.toString(),
        ));

        // Перезагружаем комментарии (UI сбросится в Loading, но SnackBar уже вызван)
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
        final updatedList = oldComments.where((c) => c.id != event.commentId).toList();

        // Оптимистичный UI: показываем список без удаленного элемента
        emit(currentState.copyWith(comments: updatedList));

        try {
          final response = await repository.deleteComment(event.commentId);

          // Показываем SnackBar с текстом от бэкенда
          emit(CommentActionSuccess(
            success: (response['message'] ?? response['success'])?.toString(),
          ));

          // ⚠️ КРИТИЧНО: Возвращаем стейт с данными обратно! 
          // Иначе список комментариев полностью исчезнет с экрана.
          emit(CommentsLoaded(updatedList));

        } catch (e) {
          emit(CommentsLoaded(oldComments)); // Откат при ошибке
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

        emit(CommentActionSuccess(
          success: (response['message'] ?? response['success'])?.toString(),
          warning: response['warning']?.toString(),
        ));

        add(const FetchComments());

      } catch (e) {
        emit(CommentsError(e.toString()));
      }
    });
  }
}