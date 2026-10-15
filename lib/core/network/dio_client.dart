import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_interceptor.dart';

class DioClient {
  final Dio _dio;

  static final CookieJar _cookieJar = CookieJar();

  DioClient(
    this._dio, {
    required SharedPreferences prefs,
    void Function()? onUnauthenticated,
    String? customBaseUrl,
  }) {
    // 💡 Определяем корректный URL в зависимости от среды
    _dio.options.baseUrl = customBaseUrl ?? _resolveBaseUrl();
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    _dio.options.validateStatus = (status) => status != null && status < 500;

    _dio.interceptors.add(
      CookieManager(_cookieJar),
    );

    _dio.interceptors.add(
      AuthInterceptor(
        prefs: prefs,
        onUnauthenticated: onUnauthenticated,
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
      ),
    );
  }

  static String _resolveBaseUrl() {
    if (kReleaseMode) {
      return 'https://findway.pro';
    }
    // Для реального Android-устройства с adb reverse tcp:3000 tcp:3000
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://localhost:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(
      url,
      queryParameters: queryParameters,
    );
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

  Future<Response> patch(
    String url, {
    dynamic data,
  }) async {
    return _dio.patch(
      url,
      data: data,
    );
  }
}