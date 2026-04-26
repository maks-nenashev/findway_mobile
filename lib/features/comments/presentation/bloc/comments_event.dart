import 'package:equatable/equatable.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();
  @override
  List<Object> get props => [];
}

class FetchComments extends CommentsEvent {
  const FetchComments();
}

class AddComment extends CommentsEvent {
  final String body;
  const AddComment(this.body);
  @override
  List<Object> get props => [body];
}

// ✅ Фикс конструктора: убираем именованный параметр, делаем позиционным
class DeleteComment extends CommentsEvent {
  final int commentId;

  // ✅ ПОСЛЕ: Добавляем фигурные скобки и required
  const DeleteComment({required this.commentId}); 

  @override
  List<Object> get props => [commentId];
}

// ✅ Сразу проверь UpdateComment, он должен быть таким же:
class UpdateComment extends CommentsEvent {
  final int commentId;
  final String newBody;

  const UpdateComment({required this.commentId, required this.newBody});

  @override
  List<Object> get props => [commentId, newBody];
}