import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

// --- FEATURE IMPORTS ---
// Search
import 'features/search/domain/repositories/search_repository.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/data/datasources/search_remote_data_source.dart';
import 'features/search/presentation/bloc/search_bloc.dart';

// Comments
import 'features/comments/data/datasources/comment_remote_data_source.dart';
import 'features/comments/domain/repositories/comment_repository.dart';
import 'features/comments/presentation/bloc/comments_bloc.dart';

// Chat
import 'features/chat/data/repositories/chat_repository.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';

// Profile
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

// Auth
import 'package:findway_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // =========================================================
  // ⚙️ 1. БАЗОВЫЕ ЗАВИСИМОСТИ (CORE)
  // =========================================================
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => LocaleRepository(sl()));

  // =========================================================
  // 🍪 2. СИСТЕМА СЕССИЙ И СЕТЬ (NETWORK)
  // =========================================================
  
  // Получаем путь для хранения куки (Persistence)
  final appDocDir = await getApplicationDocumentsDirectory();
  final String appDocPath = appDocDir.path;

  // Регистрируем ПЕРСИСТЕНТНЫЙ CookieJar
  final persistCookieJar = PersistCookieJar(
    ignoreExpires: false,
    storage: FileStorage("$appDocPath/.cookies/"),
  );
  sl.registerLazySingleton<CookieJar>(() => persistCookieJar);

  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(
      BaseOptions(
        baseUrl: getBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // Добавляем менеджер куки, использующий наш PersistCookieJar
    dio.interceptors.add(CookieManager(sl<CookieJar>()));
    
    // Логирование для отладки сессий в консоли
    dio.interceptors.add(LogInterceptor(
      requestHeader: true, 
      requestBody: true, 
      responseBody: true,
      responseHeader: true, // Важно видеть Set-Cookie от Rails
    ));
    
    return dio;
  });

  // =========================================================
  // 🔍 3. SEARCH
  // =========================================================
  sl.registerFactory(() => SearchBloc(
        repository: sl(),
        initialLocale: sl<LocaleRepository>().getCachedLocale(),
      ));
  sl.registerLazySingleton<SearchRepository>(() => SearchRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<SearchRemoteDataSource>(() => SearchRemoteDataSourceImpl(client: sl()));

  // =========================================================
  // 💬 4. COMMENTS
  // =========================================================
  sl.registerFactoryParam<CommentsBloc, int, String>((parentId, type) => CommentsBloc(
      repository: sl(),
      parentId: parentId,
      type: type,
    ));
  sl.registerLazySingleton<CommentRepository>(() => CommentRepository(remoteDataSource: sl()));
  sl.registerLazySingleton<CommentRemoteDataSource>(() => CommentRemoteDataSourceImpl(client: sl()));
  
  // =========================================================
  // ✉️ 5. CHAT
  // =========================================================
  sl.registerFactory(() => ChatBloc(repository: sl()));
  sl.registerLazySingleton<ChatRepository>(() => ChatRepository(client: sl()));
  
  // =========================================================
  // 👤 6. PROFILE / DASHBOARD
  // =========================================================
  sl.registerFactory(() => ProfileBloc(repository: sl()));
  sl.registerLazySingleton<ProfileRepository>(() => ProfileRepository(client: sl()));

  // =========================================================
  // 🔐 7. AUTH
  // =========================================================
  sl.registerFactory(() => AuthBloc(repository: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(client: sl()));
}

// --- HELPER FUNCTIONS ---

const bool useRealDevice = false;

String getBaseUrl() {
  if (kIsWeb) return "http://localhost:3000";
  if (Platform.isAndroid) {
    // 10.0.2.2 — стандартный алиас localhost для эмулятора Android
    return useRealDevice ? "http://192.168.1.106:3000" : "http://10.0.2.2:3000";
  }
  return "http://127.0.0.1:3000";
}

class LocaleRepository {
  final SharedPreferences prefs;
  LocaleRepository(this.prefs);
  String getCachedLocale() => prefs.getString('locale') ?? 'uk';
}