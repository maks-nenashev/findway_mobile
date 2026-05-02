import 'package:equatable/equatable.dart';
import '../../data/models/comment_model.dart';

/// ======================================================
/// BASE STATE
/// ======================================================
abstract class CommentsState extends Equatable {
  const CommentsState();

  @override
  List<Object?> get props => [];
}

/// ======================================================
/// INITIAL
/// ======================================================
class CommentsInitial extends CommentsState {}

/// ======================================================
/// LOADING
/// ======================================================
class CommentsLoading extends CommentsState {}

/// ======================================================
/// LOADED (ЕДИНЫЙ ПРАВИЛЬНЫЙ STATE)
/// ======================================================
class CommentsLoaded extends CommentsState {
  final List<CommentModel> comments;

  /// 🔥 уведомления (для Snackbar)
  final String? message;
  final String? warning;

  const CommentsLoaded(
    this.comments, {
    this.message,
    this.warning,
  });

  /// copyWith для обновлений
  CommentsLoaded copyWith({
    List<CommentModel>? comments,
    String? message,
    String? warning,
  }) {
    return CommentsLoaded(
      comments ?? this.comments,
      message: message,
      warning: warning,
    );
  }

  @override
  List<Object?> get props => [comments, message, warning];
}

/// ======================================================
/// ERROR
/// ======================================================
class CommentsError extends CommentsState {
  final String message;

  const CommentsError(this.message);

  @override
  List<Object?> get props => [message];
}