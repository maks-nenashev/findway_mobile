import 'package:equatable/equatable.dart'; // ✅ Добавь в pubspec.yaml если нет
import '../../data/models/comment_model.dart';

abstract class CommentsState extends Equatable {
  const CommentsState();

  @override
  List<Object?> get props => [];
}

class CommentsInitial extends CommentsState {}

class CommentsLoading extends CommentsState {}

class CommentsLoaded extends CommentsState {
  final List<CommentModel> comments;
  
  const CommentsLoaded(this.comments);

  // ✅ Этот метод решает проблему с ошибкой в Блоке
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

class CommentsError extends CommentsState {
  final String message;
  
  const CommentsError(this.message);

  @override
  List<Object?> get props => [message];
}