import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthInterceptor extends Interceptor {
  final SharedPreferences prefs;
  final void Function()? onUnauthenticated;

  static const String _tokenKey = 'auth_token';

  AuthInterceptor({
    required this.prefs,
    this.onUnauthenticated,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final isGoogleAuthRequest =
        options.path.contains('/api/v1/auth/google');

    final token = prefs.getString(_tokenKey);

    if (!isGoogleAuthRequest &&
        token != null &&
        token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (err.response?.statusCode == 401) {
      onUnauthenticated?.call();
    }

    handler.next(err);
  }
}