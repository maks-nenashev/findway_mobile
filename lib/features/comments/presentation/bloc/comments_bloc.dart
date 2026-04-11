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
    required this.type
  }) : super(CommentsInitial()) {
    
    // --- 1. ЗАГРУЗКА ---
    on<FetchComments>((event, emit) async {
      emit(CommentsLoading());
      try {
        final comments = await repository.getComments(parentId, type);
        emit(CommentsLoaded(comments));
      } catch (e) { 
        emit(CommentsError(e.toString())); 
      }
    });

    // --- 2. ДОБАВЛЕНИЕ ---
    on<AddComment>((event, emit) async {
      try {
        await repository.addComment(parentId, type, event.body);
        // После добавления всегда тянем свежие данные с сервера (Truth Source)
        add(const FetchComments());
      } catch (e) { 
        emit(CommentsError(e.toString())); 
      }
    });

    // --- 3. УДАЛЕНИЕ (Optimistic UI) ---
    on<DeleteComment>((event, emit) async {
      final currentState = state;
      if (currentState is CommentsLoaded) {
        // Сохраняем старый список на случай ошибки (Risk Control)
        final oldComments = currentState.comments;
        final updatedList = oldComments.where((c) => c.id != event.commentId).toList();
        
        // Мгновенное обновление UI (UX/Stability)
        emit(currentState.copyWith(comments: updatedList));

        try {
          await repository.deleteComment(event.commentId);
          // Не нужно вызывать FetchComments, если всё ок — список уже чист в UI
        } catch (e) {
          // Если сервер вернул ошибку — откатываем UI к реальности
          emit(CommentsLoaded(oldComments));
          emit(CommentsError("Failed to delete: ${e.toString()}"));
        }
      }
    });

    // --- 4. РЕДАКТИРОВАНИЕ ---
    on<UpdateComment>((event, emit) async {
      try {
        final result = await repository.updateComment(event.commentId, event.newBody);
        
        // Policy Layer: Если модерация скрыла пост после правки
        if (result['published'] == false) {
           // Можно добавить специфичный стейт или просто уведомить пользователя
           print("Content is hidden for moderation");
        }
        
        // Обновляем список, чтобы получить актуальные данные из БД
        add(const FetchComments());
      } catch (e) {
        emit(CommentsError(e.toString()));
      }
    });
  }
}