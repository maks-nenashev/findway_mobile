import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final Dio client;
  final SharedPreferences prefs;

  static const String _tokenKey = 'auth_token';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '620503062302-u4so8o291u7vq3knipnand840rthkgeh.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  AuthRepository({
    required this.client,
    required this.prefs,
  });

  /// Вход через Google OAuth.
  Future<void> loginWithGoogle() async {
    try {
      debugPrint('[AuthRepository] Starting Google Sign-In');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

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

      // Rails returns its own auth token in JSON.
      // The Google idToken and the Rails auth token are different tokens.
      final dynamic body = response.data;
      String? token;

      if (body is Map) {
        final value = body['token'];
        if (value != null) {
          token = value.toString().trim();
        }
      }

      // Fallback if Rails returns the token in the Authorization header.
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

      if (token == null || token.isEmpty) {
        throw Exception(
          'Rails підтвердив вхід, але не повернув токен авторизації',
        );
      }

      await prefs.setString(_tokenKey, token);

      debugPrint('[AuthRepository] Rails auth token saved');
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Google authentication failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Вхід через email і пароль.
  Future<void> login(String email, String password) async {
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

    // Save a token if this endpoint returns one.
    final dynamic body = response.data;
    String? token;

    if (body is Map && body['token'] != null) {
      token = body['token'].toString().trim();
    }

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

    if (token != null && token.isNotEmpty) {
      await prefs.setString(_tokenKey, token);
    }
  }

  /// Удаление сохранённого токена.
  Future<void> clearToken() async {
    await prefs.remove(_tokenKey);
  }

  /// Проверка наличия сохранённого токена.
  Future<bool> hasValidToken() async {
    final token = prefs.getString(_tokenKey);
    return token != null && token.trim().isNotEmpty;
  }
}
