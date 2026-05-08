import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/repositories/auth_repository.dart';

// ==============================
// 📢 EVENTS
// ==============================
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
}

class LogoutRequested extends AuthEvent {}

// ==============================
// 📊 STATES (Их не хватало!)
// ==============================
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ==============================
// 🧠 BLOC
// ==============================
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    
    // Вход
    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.login(event.email, event.password);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // Выход
    on<LogoutRequested>((event, emit) async {
      try {
        // Вызываем логаут через клиент репозитория
        await repository.client.delete('/users/sign_out.json');
      } catch (_) {
        // Ошибку сети при выходе игнорируем - нам важно сбросить стейт в приложении
      } finally {
        emit(AuthInitial());
      }
    });
  }
}