// =============================================================================
// FILE: lib/features/auth/data/repositories/auth_repository.dart
// LAYER: Data
// PURPOSE: Authentication requests to the FindWay Rails backend.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  // Dependencies
  final Dio client;
  final SharedPreferences prefs;

  // Key used to store the Rails authentication token.
  static const String _tokenKey = 'auth_token';

  // Google OAuth configuration preserved.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '620503062302-u4so8o291u7vq3knipnand840rthkgeh.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  AuthRepository({
    required this.client,
    required this.prefs,
  });

  // ---------------------------------------------------------------------------
  // REGISTER
  // Rails endpoint: POST /users.json
  // ---------------------------------------------------------------------------

  Future<String> register(
    String username,
    String email,
    String password,
    String passwordConfirmation,
    bool termsAccepted,
  ) async {
    try {
      final response = await client.post(
        '/users.json',
        data: {
          'user': {
            'username': username.trim(),
            'email': email.trim(),
            'password': password,
            'password_confirmation': passwordConfirmation,
            'terms_accepted': termsAccepted,
          },
        },
      );

      debugPrint(
        '[AuthRepository] Registration response: '
        'status=${response.statusCode}, body=${response.data}',
      );

      await _saveTokenFromResponse(response);

      final data = response.data;

      if (data is Map &&
          data['message'] != null &&
          data['message'].toString().trim().isNotEmpty) {
        return data['message'].toString();
      }

      return 'Реєстрацію завершено. Перевірте електронну пошту.';
    } on DioException catch (e) {
      debugPrint(
        '[AuthRepository] Registration failed: '
        '${e.response?.statusCode} ${e.response?.data}',
      );

      throw Exception(_extractErrorMessage(e));
    } catch (e) {
      debugPrint('[AuthRepository] Registration failed: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // Rails endpoint: POST /users/sign_in.json
  // ---------------------------------------------------------------------------

  Future<void> login(String email, String password) async {
    try {
      final response = await client.post(
        '/users/sign_in.json',
        data: {
          'user': {
            'email': email,
            'password': password,
          },
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Невірний email або пароль');
      }

      await _saveTokenFromResponse(response);

      debugPrint('[AuthRepository] Email login succeeded');
    } on DioException catch (e) {
      debugPrint(
        '[AuthRepository] Login failed: '
        '${e.response?.statusCode} ${e.response?.data}',
      );

      throw Exception(_extractErrorMessage(e));
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE OAUTH
  // Existing authentication flow preserved.
  // ---------------------------------------------------------------------------

  Future<void> loginWithGoogle() async {
    try {
      debugPrint('[AuthRepository] Starting Google Sign-In');

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Вхід скасовано користувачем');
      }

      debugPrint(
        '[AuthRepository] Google account: ${googleUser.email}',
      );

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Не вдалося отримати idToken від Google');
      }

      final response = await client.post(
        '/api/v1/auth/google',
        data: {'id_token': idToken},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Помилка авторизації на сервері: HTTP ${response.statusCode}',
        );
      }

      // The Google ID token is different from the Rails auth token.
      await _saveTokenFromResponse(response);

      // A Rails token is required for authenticated API requests.
      if (!await hasValidToken()) {
        throw Exception(
          'Rails не повернув токен авторизації',
        );
      }

      debugPrint('[AuthRepository] Google authentication succeeded');
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Google authentication failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // TOKEN MANAGEMENT
  // ---------------------------------------------------------------------------

  Future<void> _saveTokenFromResponse(Response response) async {
    final dynamic body = response.data;
    String? token;

    // First, check the JSON response body.
    if (body is Map && body['token'] != null) {
      token = body['token'].toString().trim();
    }

    // If the body has no token, check the Authorization header.
    if (token == null || token.isEmpty) {
      final header = response.headers.value('Authorization');

      if (header != null && header.trim().isNotEmpty) {
        token = header
            .replaceFirst(
              RegExp(r'^Bearer\s+', caseSensitive: false),
              '',
            )
            .trim();
      }
    }

    // Store the token only when the server actually returned one.
    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
      debugPrint('[AuthRepository] Rails auth token saved');
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR HANDLING
  // ---------------------------------------------------------------------------

  String _extractErrorMessage(DioException error) {
    final dynamic data = error.response?.data;

    if (data is Map) {
      final dynamic errors = data['errors'];

      if (errors is List && errors.isNotEmpty) {
        return errors.join('\n');
      }

      if (errors is Map) {
        return errors.entries
            .map((entry) => '${entry.value}')
            .join('\n');
      }

      final dynamic message = data['message'];

      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    if (error.response?.statusCode == 422) {
      return 'Перевірте введені дані. Можливо, email вже зареєстрований '
          'або пароль не відповідає вимогам.';
    }

    if (error.response?.statusCode == 401 ||
        error.response?.statusCode == 403) {
      return 'Невірний email або пароль.';
    }

    if (error.response == null) {
      return 'Не вдалося з’єднатися із сервером. Перевірте інтернет.';
    }

    return 'Помилка сервера: HTTP ${error.response?.statusCode}';
  }

  // ---------------------------------------------------------------------------
  // LOGOUT SUPPORT
  // ---------------------------------------------------------------------------

  Future<void> clearToken() async {
    await prefs.remove(_tokenKey);
  }

  // ---------------------------------------------------------------------------
  // SESSION CHECK
  // ---------------------------------------------------------------------------

  Future<bool> hasValidToken() async {
    final token = prefs.getString(_tokenKey);
    return token != null && token.trim().isNotEmpty;
  }
}