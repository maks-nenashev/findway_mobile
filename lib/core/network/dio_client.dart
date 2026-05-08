import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

class DioClient {
  final Dio _dio;

  /// 🔥 ГЛАВНОЕ — ОДИН CookieJar
  static final CookieJar _cookieJar = CookieJar();

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = 'http://10.0.2.2:3000'
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }

      /// ✅ теперь cookie НЕ теряется
      ..interceptors.add(CookieManager(_cookieJar))

      ..interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
  }

  Future<Response> get(String url,
      {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(url, queryParameters: queryParameters);
  }

  Future<Response> post(String url,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post(
      url,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response> delete(String url) async {
    return await _dio.delete(url);
  }

  Future<Response> patch(String url, {dynamic data}) async {
    return await _dio.patch(url, data: data);
  }
}