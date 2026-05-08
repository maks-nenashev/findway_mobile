import 'package:equatable/equatable.dart';
import '../../data/models/comment_model.dart';

abstract class CommentsState extends Equatable {
  const CommentsState();

  @override
  List<Object?> get props => [];
}

/// INITIAL
class CommentsInitial extends CommentsState {}

/// LOADING
class CommentsLoading extends CommentsState {}

/// DATA (ТОЛЬКО ДАННЫЕ)
class CommentsLoaded extends CommentsState {
  final List<CommentModel> comments;

  const CommentsLoaded(this.comments);

  CommentsLoaded copyWith({
    List<CommentModel>? comments,
  }) {
    return CommentsLoaded(
      comments ?? this.comments,
    );
  }

  @override
  List<Object?> get props => [comments];
}

/// ERROR
class CommentsError extends CommentsState {
  final String message;

  const CommentsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// SUCCESS (под YAML: success + warning)
class CommentActionSuccess extends CommentsState {
  final String? success;
  final String? warning;

  const CommentActionSuccess({
    this.success,
    this.warning,
  });

  @override
  List<Object?> get props => [success, warning];
}