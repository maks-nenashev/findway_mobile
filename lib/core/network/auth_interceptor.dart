import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final Function() onUnauthenticated;

  AuthInterceptor({required this.onUnauthenticated});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // При получении 401 сбрасываем сессию/токен и уведомляем AuthBloc
      onUnauthenticated();
    }
    super.onError(err, handler);
  }
}