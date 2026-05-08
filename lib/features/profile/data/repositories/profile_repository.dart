import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import '../../../../injection_container.dart';
// 👉 ДОБАВЬ ЭТОТ ИМПОРТ (проверь путь к файлу модели)
import '../models/dashboard_model.dart'; 

class ProfileRepository {
  final Dio client;

  ProfileRepository({required this.client});

  Future<DashboardModel> getDashboard(String locale) async {
    try {
      final cookies = await sl<CookieJar>().loadForRequest(Uri.parse(client.options.baseUrl));

      final response = await client.get(
        '/api/v1/dashboard',
        queryParameters: {'locale': locale},
      );

      return DashboardModel.fromJson(response.data);
    } catch (e) {
      print("❌ Ошибка профиля: $e");
      rethrow;
    }
  }
}