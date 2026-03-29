import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

// Импорты слоев архитектуры
import 'features/search/domain/repositories/search_repository.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/data/datasources/search_remote_data_source.dart';
import 'features/search/presentation/bloc/search_bloc.dart';

final sl = GetIt.instance; // Service Locator

Future<void> init() async {
  // 1. Presentation Layer (Blocs)
  sl.registerFactory(
    () => SearchBloc(repository: sl()), 
  );

  // 2. Domain Layer (Repositories)
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );

  // 3. Data Sources
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(client: sl()), 
  );

  // 4. External (Сетевой шлюз)
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        // Для Android Emulator 10.0.2.2 — это твой localhost (Rails)
        // Если сервер на Hetzner, замени на: https://api.yourdomain.com
        baseUrl: 'http://10.0.2.2:3000', 
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Включаем логирование запросов для Explainability (контроль в консоли)
    dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
    ));

    return dio;
  });
}