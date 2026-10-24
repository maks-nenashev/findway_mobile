import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class FetchProfileEvent extends ProfileEvent {
  final String locale;

  const FetchProfileEvent({required this.locale});

  @override
  List<Object?> get props => [locale];
}