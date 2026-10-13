// =============================================================================
// FILE: lib/features/auth/presentation/bloc/auth_bloc.dart
// LAYER: Presentation (BLoC)
// RESPONSIBILITY: Manages application authentication state transitions.
// =============================================================================

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:findway_mobile/features/auth/data/repositories/auth_repository.dart';

// ==============================
// 📢 EVENTS
// ==============================
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
}

class GoogleLoginSubmitted extends AuthEvent {} // 👉 Вынесено из конструктора

class LogoutRequested extends AuthEvent {}

// ==============================
// 📊 STATES
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
    
    // Проверка состояния сессии
    on<CheckAuthStatus>((event, emit) async {
      emit(AuthLoading());
      try {
        // Логика проверки токена / cookie
        emit(AuthAuthenticated());
      } catch (_) {
        emit(AuthInitial());
      }
    });

    // Вход по Email/Password
    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.login(event.email, event.password);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // Вход через Google OAuth
    on<GoogleLoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.loginWithGoogle();
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // Выход
    on<LogoutRequested>((event, emit) async {
      try {
        await repository.client.delete('/users/sign_out.json');
      } catch (_) {
        // Игнорируем ошибки сети при выходе
      } finally {
        emit(AuthInitial());
      }
    });
  }
}