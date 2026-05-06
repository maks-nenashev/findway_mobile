import 'package:dio/dio.dart';

class AuthRepository {
  final Dio client;

  AuthRepository({required this.client});

  // Вход (Login) — теперь возвращает bool (успех/провал)
  Future<bool> login(String email, String password) async {
    try {
      final response = await client.post(
        '/api/v1/login',
        data: {
          'user': {
            'email': email,
            'password': password,
          }
        },
      );

      // Если 200 или 201 — CookieManager УЖЕ сохранил куку в PersistCookieJar
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; 
      }

      throw Exception('Ошибка сервера: ${response.statusMessage}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Неправильный логин или пароль');
      }
      throw Exception('Сетевая ошибка: ${e.message}');
    }
  }

  // Выход (Logout) — куки удалятся автоматически при успешном DELETE
  Future<void> logout() async {
    try {
      final response = await client.delete(
        '/users/sign_out.json',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('Вы успешно вышли из системы');
        return;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Игнорируем, если сессия уже истекла
        return;
      }
      throw Exception('Ошибка при выходе: ${e.message}');
    }
  }

  // Методы saveToken/getToken больше не нужны для Cookies, 
  // но если они используются в блоках для логики переключения экранов, 
  // их можно оставить пустыми или переделать под проверку наличия куки.
}