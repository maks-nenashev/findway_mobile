import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart'; // ✅ Добавить
import 'package:cookie_jar/cookie_jar.dart';               // ✅ Добавить

// Импорты фич
import 'features/search/domain/repositories/search_repository.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/data/datasources/search_remote_data_source.dart';
import 'features/search/presentation/bloc/search_bloc.dart';
import 'features/comments/data/datasources/comment_remote_data_source.dart';
import 'features/comments/domain/repositories/comment_repository.dart';
import 'features/comments/presentation/bloc/comments_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // 1. Search Feature
  sl.registerLazySingleton(() => SearchBloc(repository: sl()));
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(client: sl()),
  );

  // 2. Comments Feature
  sl.registerFactoryParam<CommentsBloc, int, String>(
    (parentId, type) => CommentsBloc(
      repository: sl(),
      parentId: parentId,
      type: type,
    ),
  );

  sl.registerLazySingleton<CommentRepository>(
    () => CommentRepository(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<CommentRemoteDataSource>(
    () => CommentRemoteDataSourceImpl(client: sl()),
  );

  // 3. External (Dio & Cookies)
  // Регистрируем CookieJar как синглтон, чтобы сессия жила всё время работы приложения
  sl.registerLazySingleton<CookieJar>(() => CookieJar());

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:3000', 
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // ✅ Интеграция CookieManager ВНУТРИ инициализации Dio
    dio.interceptors.add(CookieManager(sl<CookieJar>()));
    
    dio.interceptors.add(LogInterceptor(
      responseBody: true, 
      requestBody: true,
      requestHeader: true,
    ));

    return dio;
  });
}