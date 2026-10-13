import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'auth_interceptor.dart';

class DioClient {
  final Dio _dio;

  static final CookieJar _cookieJar = CookieJar();

  DioClient(this._dio, {void Function()? onUnauthenticated}) {
    _dio.options.baseUrl = 'http://10.0.2.2:3000';
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.options.validateStatus = (status) =>
        status != null && status < 500;

    _dio.interceptors.add(CookieManager(_cookieJar));

    _dio.interceptors.add(
      AuthInterceptor(onUnauthenticated: onUnauthenticated),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(url, queryParameters: queryParameters);
  }

  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response> delete(String url) async {
    return _dio.delete(url);
  }

  Future<Response> patch(String url, {dynamic data}) async {
    return _dio.patch(url, data: data);
  }
}
