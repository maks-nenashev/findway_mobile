import 'package:equatable/equatable.dart';

abstract class PostCreateState extends Equatable {
  const PostCreateState();
  @override
  List<Object?> get props => [];
}

class PostCreateInitial extends PostCreateState {}

class PostCreateInProgress extends PostCreateState {}

class PostCreateSuccess extends PostCreateState {
  final int postId;
  const PostCreateSuccess({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class PostCreateFailure extends PostCreateState {
  final String error;
  const PostCreateFailure({required this.error});
  @override
  List<Object?> get props => [error];
}