import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

// --- CORE NETWORK IMPORTS ---
import 'core/network/auth_interceptor.dart';

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
import 'features/chat/presentation/bloc/notification_bloc.dart';

// Profile
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

// Auth
import 'package:findway_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // =========================================================
  // 1. CORE DEPENDENCIES
  // =========================================================

  final sharedPreferences = await SharedPreferences.getInstance();

  sl.registerLazySingleton<SharedPreferences>(
    () => sharedPreferences,
  );

  sl.registerLazySingleton<LocaleRepository>(
    () => LocaleRepository(sl<SharedPreferences>()),
  );

  // =========================================================
  // 2. SESSION STORAGE AND NETWORK
  // =========================================================

  final appDocDir = await getApplicationDocumentsDirectory();
  final String appDocPath = appDocDir.path;

  final persistCookieJar = PersistCookieJar(
    ignoreExpires: false,
    storage: FileStorage('$appDocPath/.cookies/'),
  );

  sl.registerLazySingleton<CookieJar>(
    () => persistCookieJar,
  );

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
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Dynamic Accept-Language Header Interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final locale = sl<LocaleRepository>().getCachedLocale();
          options.headers['Accept-Language'] = locale;
          return handler.next(options);
        },
      ),
    );

    // Persistent Rails session cookies.
    dio.interceptors.add(
      CookieManager(sl<CookieJar>()),
    );

    // Automatically attaches the saved Rails auth token.
    dio.interceptors.add(
      AuthInterceptor(
        prefs: sl<SharedPreferences>(),
        onUnauthenticated: () {
          // 401 handling will be implemented in Stage 2.
        },
      ),
    );

    // Log request/response metadata without sensitive headers or bodies.
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        requestBody: false,
        responseBody: false,
        responseHeader: false,
      ),
    );

    return dio;
  });

  // =========================================================
  // 3. SEARCH
  // =========================================================

  sl.registerFactory(
    () => SearchBloc(
      repository: sl<SearchRepository>(),
      initialLocale: sl<LocaleRepository>().getCachedLocale(),
    ),
  );

  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      remoteDataSource: sl<SearchRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(
      client: sl<Dio>(),
    ),
  );

  // =========================================================
  // 4. COMMENTS
  // =========================================================

  sl.registerFactoryParam<CommentsBloc, int, String>(
    (parentId, type) => CommentsBloc(
      repository: sl<CommentRepository>(),
      parentId: parentId,
      type: type,
    ),
  );

  sl.registerLazySingleton<CommentRepository>(
    () => CommentRepository(
      remoteDataSource: sl<CommentRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<CommentRemoteDataSource>(
    () => CommentRemoteDataSourceImpl(
      client: sl<Dio>(),
    ),
  );

  // =========================================================
  // 5. CHAT AND NOTIFICATIONS
  // =========================================================

  sl.registerFactory(
    () => ChatBloc(
      repository: sl<ChatRepository>(),
    ),
  );

  sl.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(
      repository: sl<ChatRepository>(),
    ),
  );

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepository(
      client: sl<Dio>(),
    ),
  );

  // =========================================================
  // 6. PROFILE
  // =========================================================

  sl.registerFactory(
    () => ProfileBloc(
      repository: sl<ProfileRepository>(),
    ),
  );

  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(
      client: sl<Dio>(),
    ),
  );

  // =========================================================
  // 7. AUTHENTICATION
  // =========================================================

  sl.registerFactory(
    () => AuthBloc(
      repository: sl<AuthRepository>(),
    ),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(
      client: sl<Dio>(),
      prefs: sl<SharedPreferences>(),
    ),
  );
}

// ===========================================================
// HELPER FUNCTIONS
// ===========================================================

String getBaseUrl() {
  // 1. ВЫСШИЙ ПРИОРИТЕТ: Явный URL из флага сборки (--dart-define=BASE_URL=https://...)
  const String customUrl = String.fromEnvironment('BASE_URL');
  if (customUrl.isNotEmpty) {
    return customUrl;
  }

  // 2. PRODUCTION (RELEASE BUILD ДЛЯ GOOGLE PLAY / APP STORE)
  // Автоматически включается при `flutter build appbundle --release`
  if (kReleaseMode) {
    return 'https://findway.pro'; // 👈 Укажи здесь твой боевой HTTPS-домен с валидным SSL
  }

  // 3. LOCAL DEVELOPMENT (DEBUG MODE)
  // Полностью сохраняет твою удобную схему для эмуляторов, кабеля и Wi-Fi

  // Web-платформа
  if (kIsWeb) {
    return 'http://localhost:3000';
  }

  // Android (Физическое устройство / Эмулятор)
  if (Platform.isAndroid) {
    // Флаг для туннеля ADB Reverse
    const bool useAdbReverse = bool.fromEnvironment('ADB_REVERSE', defaultValue: false);
    if (useAdbReverse) {
      return 'http://localhost:3000';
    }

    // Флаг для Android Emulator (AVD)
    const bool isEmulator = bool.fromEnvironment('EMULATOR', defaultValue: false);
    if (isEmulator) {
      return 'http://10.0.2.2:3000';
    }

    // По умолчанию для физического телефона — прямой IP ThinkPad в локальной сети
    return 'http://192.168.1.127:3000';
  }

  // Linux Desktop / iOS
  return 'http://127.0.0.1:3000';
}
// ===========================================================
// LOCALE REPOSITORY
// ===========================================================

class LocaleRepository {
  final SharedPreferences prefs;

  LocaleRepository(this.prefs);

  String getCachedLocale() {
    return prefs.getString('locale') ?? 'uk';
  }

  Future<void> setLocale(String locale) async {
    await prefs.setString('locale', locale);
  }
}