import 'package:flutter_bloc/flutter_bloc.dart';
// Используем абсолютный путь к репозиторию
import 'package:findway_mobile/features/profile/data/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    
    on<GetProfileData>((event, emit) async {
      emit(ProfileLoading());
      try {
        final dashboardData = await repository.getDashboard(event.locale);
        emit(ProfileLoaded(dashboard: dashboardData));
      } catch (e) {
        emit(ProfileError(message: e.toString()));
      }
    });
  }
}