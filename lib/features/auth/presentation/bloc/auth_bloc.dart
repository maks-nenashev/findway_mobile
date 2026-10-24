// =============================================================================
// FILE: lib/features/auth/presentation/bloc/auth_bloc.dart
// PURPOSE: Authentication state transitions; messages remain stable keys.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:findway_mobile/features/auth/data/repositories/auth_repository.dart';

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

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String username;
  final String email;
  final String password;
  final String passwordConfirmation;
  final bool termsAccepted;

  const RegisterSubmitted({
    required this.username,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.termsAccepted,
  });

  @override
  List<Object?> get props => [
        username,
        email,
        password,
        passwordConfirmation,
        termsAccepted,
      ];
}

class GoogleLoginSubmitted extends AuthEvent {}

class LogoutRequested extends AuthEvent {}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthRegistrationSuccess extends AuthState {
  /// Stable translation key, not a localized server sentence.
  final String message;

  const AuthRegistrationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  /// Stable translation key, not a localized server sentence.
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<CheckAuthStatus>((event, emit) async {
      emit(AuthLoading());
      try {
        emit(AuthAuthenticated());
      } catch (_) {
        emit(AuthInitial());
      }
    });

    on<LoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.login(event.email, event.password);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(_messageKey(e)));
      }
    });

    on<RegisterSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        final messageKey = await repository.register(
          event.username,
          event.email,
          event.password,
          event.passwordConfirmation,
          event.termsAccepted,
        );
        debugPrint('[AuthBloc] Registration succeeded: $messageKey');
        emit(AuthRegistrationSuccess(messageKey));
      } catch (e) {
        emit(AuthError(_messageKey(e)));
      }
    });

    on<GoogleLoginSubmitted>((event, emit) async {
      emit(AuthLoading());
      try {
        await repository.loginWithGoogle();
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(_messageKey(e)));
      }
    });

    on<LogoutRequested>((event, emit) async {
      try {
        await repository.client.delete('/users/sign_out.json');
      } catch (_) {
        // Ignore network errors during logout.
      } finally {
        emit(AuthInitial());
      }
    });
  }

  String _messageKey(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    // Do not expose raw exception wrappers to the UI.
    if (message.startsWith('devise.') ||
        message.startsWith('errors.') ||
        message.startsWith('auth.')) {
      return message;
    }

    debugPrint('[AuthBloc] Unmapped authentication error: $message');
    return AuthRepository.serverErrorKey;
  }
}