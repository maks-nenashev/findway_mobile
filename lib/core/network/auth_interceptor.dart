
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final void Function()? onUnauthenticated;

  AuthInterceptor({this.onUnauthenticated});

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
