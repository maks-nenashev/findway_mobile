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
}

class DeleteComment extends CommentsEvent {
  final int commentId;
  const DeleteComment(this.commentId);
}