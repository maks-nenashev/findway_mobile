import 'package:dio/dio.dart';
import '../models/dashboard_model.dart';

class ProfileRepository {
  final Dio client;

  ProfileRepository({required this.client});

  Future<DashboardModel> getDashboard({required String locale}) async {
    final cleanLocale = locale.trim().toLowerCase().split(RegExp('[-_]')).first;
    final response = await client.get(
      '/api/v1/dashboard',
      queryParameters: {
        'locale': cleanLocale,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      return DashboardModel.fromJson(response.data as Map<String, dynamic>);
    } else {
      throw Exception('Failed to load profile dashboard');
    }
  }
}