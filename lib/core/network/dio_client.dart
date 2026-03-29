import 'package:dio/dio.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = 'http://10.0.2.2:3000/api/v1' // Замени на свой IP/домен
      //..options.baseUrl = 'http://192.168.1.15/api/v1' // Замени на свой IP/домен
      ..options.connectTimeout = const Duration(seconds: 15)
      ..options.receiveTimeout = const Duration(seconds: 15)
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    // Добавляем логирование для отладки (в консоли будет видно как в Rails logs)
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Общий метод для GET запросов
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(url, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      // Здесь мы позже добавим Fail-safe логику и кастомные исключения
      rethrow;
    }
  }
}