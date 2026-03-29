import 'package:dio/dio.dart';
import '../models/filter_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<FilterModel>> getFilters(String category, String locale);
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio client;

  SearchRemoteDataSourceImpl({required this.client});

  @override
  Future<List<FilterModel>> getFilters(String category, String locale) async {
    final response = await client.get(
      '/api/v1/filters',
      queryParameters: {
        'category': category,
        'locale': locale,
      },
    );

    if (response.statusCode == 200) {
      final List data = response.data['filters'];
      return data.map((json) => FilterModel.fromJson(json)).toList();
    } else {
      throw Exception('Server Error: ${response.statusCode}');
    }
  }
}