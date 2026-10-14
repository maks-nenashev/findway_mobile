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
    final isGoogleAuthRequest = options.path.contains('/api/v1/auth/google');
    final token = prefs.getString(_tokenKey);

    if (!isGoogleAuthRequest && token != null && token.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Так как DioClient пробивает 401 через validateStatus < 500, обрабатываем 401 здесь
    if (response.statusCode == 401) {
      _processUnauthenticated(response.requestOptions.path);
    }

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    if (err.response?.statusCode == 401) {
      _processUnauthenticated(err.requestOptions.path);
    }

    handler.next(err);
  }

  /// Проверяет, является ли 401 критической ошибкой сессии
  void _processUnauthenticated(String path) {
    // НЕ выбиваем пользователя из приложения при ошибках загрузки контента (статей, биометрии)
    // Разлогин вызываем только при отказе системных эндпоинтов авторизации/профиля
    final isContentEndpoint = path.contains('/articles') || 
                              path.contains('/biometrics') || 
                              path.contains('/posts') ||
                              path.contains('/matches');

    if (!isContentEndpoint) {
      onUnauthenticated?.call();
    }
  }
}