import 'package:flutter_bloc/flutter_bloc.dart';
import 'comments_event.dart';
import 'comments_state.dart';
import '../../domain/repositories/comment_repository.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final CommentRepository repository;
  final int parentId;
  final String type;

  CommentsBloc({required this.repository, required this.parentId, required this.type}) : super(CommentsInitial()) {
    on<FetchComments>((event, emit) async {
      emit(CommentsLoading());
      try {
        final comments = await repository.getComments(parentId, type);
        emit(CommentsLoaded(comments));
      } catch (e) { emit(CommentsError(e.toString())); }
    });

    on<AddComment>((event, emit) async {
      try {
        await repository.addComment(parentId, type, event.body);
        add(const FetchComments());
      } catch (e) { emit(CommentsError(e.toString())); }
    });

    on<DeleteComment>((event, emit) async {
      try {
        await repository.deleteComment(event.commentId);
        add(const FetchComments());
      } catch (e) { emit(CommentsError(e.toString())); }
    });
  }
}