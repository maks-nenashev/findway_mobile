import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

// Изменили название и сделали параметр позиционным для краткости
class GetProfileData extends ProfileEvent {
  final String locale;

  const GetProfileData(this.locale);

  @override
  List<Object?> get props => [locale];
}