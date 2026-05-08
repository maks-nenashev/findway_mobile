import 'package:equatable/equatable.dart';
// 👉 ВОТ ЭТОТ ИМПОРТ:
import 'package:findway_mobile/features/profile/data/models/dashboard_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}
class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final DashboardModel dashboard; // Теперь DashboardModel — валидный тип
  const ProfileLoaded({required this.dashboard});

  @override
  List<Object?> get props => [dashboard];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError({required this.message});
  @override
  List<Object?> get props => [message];
}

class Unauthenticated extends ProfileState {}