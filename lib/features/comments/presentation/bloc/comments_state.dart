import '../../data/models/comment_model.dart';

abstract class CommentsState {}

class CommentsInitial extends CommentsState {}
class CommentsLoading extends CommentsState {}
class CommentsLoaded extends CommentsState {
  final List<CommentModel> comments;
  CommentsLoaded(this.comments);
}
class CommentsError extends CommentsState {
  final String message;
  CommentsError(this.message);
}