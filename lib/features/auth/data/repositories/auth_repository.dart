// =============================================================================
// FILE: lib/features/auth/data/repositories/auth_repository.dart
// LAYER: Data Layer (Repository)
// RESPONSIBILITY: Coordinates authentication requests with Dio & Google Auth SDK.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final Dio client;

  // Web Client ID из Google Cloud Console (для валидации idToken на стороне Rails API)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '620503062302-u4so8o291u7vq3knipnand840rthkgeh.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  AuthRepository({required this.client});

  /// 🔑 Нативный вход через Google OAuth
  Future<void> loginWithGoogle() async {
    try {
      debugPrint('>>> [AuthRepository] Triggering GoogleSignIn().signIn()...');

      // 1. Нативный вызов Google Play Services
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('>>> [AuthRepository] User cancelled Google Sign-In dialog');
        throw Exception('Вхід скасовано користувачем');
      }

      debugPrint('>>> [AuthRepository] Google Account selected: ${googleUser.email}');

      // 2. Извлечение idToken
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      debugPrint('>>> [AuthRepository] Obtained idToken: ${idToken != null ? "SUCCESS" : "NULL"}');

      if (idToken == null) {
        throw Exception('Не вдалося отримати idToken від Google');
      }

      // 3. Передача idToken на Rails API
      debugPrint('>>> [AuthRepository] Sending idToken to Rails /api/v1/auth/google...');
      final response = await client.post(
        '/api/v1/auth/google',
        data: {'id_token': idToken},
      );

      debugPrint('>>> [AuthRepository] Rails Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.headers.value('Authorization');
        if (token != null) {
          debugPrint('>>> [AuthRepository] JWT Session Token saved: $token');
        }
      } else {
        throw Exception('Помилка авторизації на сервері');
      }
    } catch (e, stackTrace) {
      debugPrint('>>> [AuthRepository] Google Auth Exception: $e');
      debugPrint('>>> [AuthRepository] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// 📧 Стандартный вход по Email / Password (Devise)
  Future<void> login(String email, String password) async {
    final response = await client.post('/users/sign_in.json', data: {
      'user': {
        'email': email,
        'password': password,
      }
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Невірний email або пароль');
    }
  }

  /// 🚪 Сброс сессии
  Future<void> clearToken() async {
    // Очистка локального хранилища токенов
  }

  /// 🔍 Проверка наличия сохраненного токена
  Future<bool> hasValidToken() async {
    return false; // Заглушка: проверяется через AuthInterceptor / SecureStorage
  }
}