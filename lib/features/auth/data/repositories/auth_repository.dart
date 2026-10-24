// =============================================================================
// FILE: lib/features/auth/data/repositories/auth_repository.dart
// PURPOSE: Authentication requests and stable translation keys.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final Dio client;
  final SharedPreferences prefs;

  static const String _tokenKey = 'auth_token';

  // Stable message keys consumed by LoginPage; never return mixed-language text.
  static const String registrationPendingKey =
      'devise.registrations.signed_up_but_unconfirmed';
  static const String invalidCredentialsKey = 'devise.failure.invalid';
  static const String registrationInvalidKey = 'errors.registration.invalid';
  static const String networkErrorKey = 'errors.network';
  static const String serverErrorKey = 'errors.server';
  static const String googleCancelledKey = 'auth.google.cancelled';
  static const String googleTokenMissingKey = 'auth.google.token_missing';
  static const String railsTokenMissingKey = 'auth.token.missing';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '620503062302-u4so8o291u7vq3knipnand840rthkgeh.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  AuthRepository({
    required this.client,
    required this.prefs,
  });

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
        'status=${response.statusCode}',
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        await _saveTokenFromResponse(response);
        return registrationPendingKey;
      }

      throw Exception(_keyForStatus(status, registration: true));
    } on DioException catch (e) {
      debugPrint(
        '[AuthRepository] Registration failed: '
        '${e.response?.statusCode}',
      );
      throw Exception(_keyForStatus(
        e.response?.statusCode,
        registration: true,
        noResponse: e.response == null,
      ));
    } catch (e) {
      debugPrint('[AuthRepository] Registration failed: $e');
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await client.post(
        '/users/sign_in.json',
        data: {
          'user': {
            'email': email.trim(),
            'password': password,
          },
        },
      );

      final status = response.statusCode ?? 0;
      if (status != 200 && status != 201) {
        throw Exception(_keyForStatus(status));
      }

      await _saveTokenFromResponse(response);
      debugPrint('[AuthRepository] Email login succeeded');
    } on DioException catch (e) {
      debugPrint(
        '[AuthRepository] Login failed: ${e.response?.statusCode}',
      );
      throw Exception(_keyForStatus(
        e.response?.statusCode,
        noResponse: e.response == null,
      ));
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      debugPrint('[AuthRepository] Starting Google Sign-In');

      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception(googleCancelledKey);
      }

      debugPrint('[AuthRepository] Google account selected');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(googleTokenMissingKey);
      }

      final response = await client.post(
        '/api/v1/auth/google',
        data: {'id_token': idToken},
      );

      final status = response.statusCode ?? 0;
      if (status != 200 && status != 201) {
        throw Exception(_keyForStatus(status));
      }

      // Preserve existing Rails-token storage behavior.
      await _saveTokenFromResponse(response);

      if (!await hasValidToken()) {
        throw Exception(railsTokenMissingKey);
      }

      debugPrint('[AuthRepository] Google authentication succeeded');
    } catch (e, stackTrace) {
      debugPrint('[AuthRepository] Google authentication failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> _saveTokenFromResponse(Response response) async {
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
      debugPrint('[AuthRepository] Rails auth token saved');
    }
  }

  String _keyForStatus(
    int? status, {
    bool registration = false,
    bool noResponse = false,
  }) {
    if (noResponse) return networkErrorKey;
    if (status == 401 || status == 403) return invalidCredentialsKey;
    if (status == 422) {
      return registration ? registrationInvalidKey : invalidCredentialsKey;
    }
    return serverErrorKey;
  }

  Future<void> clearToken() async {
    await prefs.remove(_tokenKey);
  }

  Future<bool> hasValidToken() async {
    final token = prefs.getString(_tokenKey);
    return token != null && token.trim().isNotEmpty;
  }
}