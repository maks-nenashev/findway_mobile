import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/search_repository.dart';
import 'post_create_event.dart';
import 'post_create_state.dart';

class PostCreateBloc extends Bloc<PostCreateEvent, PostCreateState> {
  final SearchRepository repository;

  PostCreateBloc({required this.repository}) : super(PostCreateInitial()) {
    on<SubmitPost>((event, emit) async {
      emit(PostCreateInProgress());

      try {
        final result = await repository.createPost(
          category: event.category,
          title: event.title,
          text: event.text,
          localId: event.localId,
          choiceId: event.choiceId,
          catId: event.catId,
          locale: event.locale,
          imagePaths: event.imagePaths,
        );

        if (result['success'] == true) {
          emit(PostCreateSuccess(postId: result['id']));
        } else {
          final errorMsg = (result['errors'] as List).join(', ');
          emit(PostCreateFailure(error: errorMsg));
        }
      } catch (e) {
        emit(PostCreateFailure(error: e.toString()));
      }
    });
  }
}