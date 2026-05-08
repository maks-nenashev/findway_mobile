import 'package:equatable/equatable.dart';

abstract class PostCreateEvent extends Equatable {
  const PostCreateEvent();
  @override
  List<Object?> get props => [];
}

class SubmitPost extends PostCreateEvent {
  final String category;
  final String title;
  final String text;
  final int localId;
  final int choiceId;
  final int? catId;
  final String locale;
  final List<String> imagePaths;

  const SubmitPost({
    required this.category,
    required this.title,
    required this.text,
    required this.localId,
    required this.choiceId,
    this.catId,
    required this.locale,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [category, title, text, localId, choiceId, catId, locale, imagePaths];
}