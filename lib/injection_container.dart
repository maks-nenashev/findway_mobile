import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/search/domain/repositories/search_repository.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/data/datasources/search_remote_data_source.dart';
import 'features/search/presentation/bloc/search_bloc.dart';

import 'features/comments/data/datasources/comment_remote_data_source.dart';
import 'features/comments/domain/repositories/comment_repository.dart';
import 'features/comments/presentation/bloc/comments_bloc.dart';

class LocaleRepository {
  final SharedPreferences prefs;

  LocaleRepository(this.prefs);

  String getCachedLocale() =>
      prefs.getString('locale') ?? 'uk';
}

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences =
      await SharedPreferences.getInstance();

  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => LocaleRepository(sl()));

  sl.registerFactory(() => SearchBloc(
        repository: sl(),
        initialLocale: sl<LocaleRepository>().getCachedLocale(),
      ));

  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(client: sl()),
  );

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

  sl.registerLazySingleton<CookieJar>(() => CookieJar());

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:3000',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(CookieManager(sl<CookieJar>()));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    return dio;
  });
}