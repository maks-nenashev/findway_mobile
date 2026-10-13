// =============================================================================
// FILE: lib/main.dart
// LAYER: Application Root & Navigation
// RESPONSIBILITY: Global dependency initialization, MultiBlocProvider setup,
//                 and reactive auth-state routing (Production Guard).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;

// --- СТРАНИЦЫ (PAGES) ---
import 'package:findway_mobile/features/search/presentation/pages/search_page.dart';
import 'package:findway_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:findway_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:findway_mobile/features/search/presentation/pages/post_card_page.dart';
import 'package:findway_mobile/features/search/presentation/pages/post_edit_page.dart';
import 'package:findway_mobile/features/chat/presentation/pages/chat_room_page.dart';

// --- БЛОКИ И СОБЫТИЯ (BLOCS & EVENTS) ---
import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:findway_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:findway_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/chat_bloc.dart'; // 👉 ДОБАВЛЕН
import 'package:findway_mobile/features/chat/presentation/bloc/notification_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация сервисов и инжектора зависимостей (GetIt)
  await di.init();
  
  runApp(const FindWayApp());
}

class FindWayApp extends StatelessWidget {
  const FindWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // --- ГЛОБАЛЬНЫЕ БЛОКИ ---
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => di.sl<NotificationBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FindWay',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF00F2FF),
          fontFamily: 'Orbitron',
        ),

        // =====================================================================
        // 🔥 АВТОМАТИЧЕСКИЙ РЕАКТИВНЫЙ РОУТИНГ (PRODUCTION GUARD)
        // =====================================================================
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // 1. Проверка состояния сессии
            if (state is AuthLoading) {
              return const Scaffold(
                backgroundColor: Color(0xFF0F172A),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00F2FF)),
                ),
              );
            }

            // 2. Успешная авторизация -> Главная
            if (state is AuthAuthenticated) {
              return const SearchPage();
            }

            // 3. Неавторизован -> Экран логина
            return const LoginPage();
          },
        ),

        // --- ИМЕНОВАННЫЕ МАРШРУТЫ ---
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());

            case '/':
              return MaterialPageRoute(builder: (_) => const SearchPage());

            // --- КАРТОЧКА ПОСТА ---
            case '/post_details':
              final args = settings.arguments as Map<String, dynamic>?;
              final postId = args?['id'] as int? ?? 0;
              final category = args?['category'] as String? ?? 'people';
              
              return MaterialPageRoute(
                builder: (_) => BlocProvider<SearchBloc>(
                  create: (context) => di.sl<SearchBloc>()..add(LoadPostDetails(
                    id: postId,
                    category: category,
                    locale: 'uk', 
                  )),
                  child: const PostCardPage(), 
                ),
              );

            // --- РЕДАКТИРОВАНИЕ ПОСТА ---
            case '/post_edit':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => BlocProvider<SearchBloc>.value(
                  value: args['bloc'] as SearchBloc, 
                  child: PostEditPage(
                    postId: args['postId'],
                    initialCategory: args['initialCategory'],
                    initialTitle: args['initialTitle'],
                    initialText: args['initialText'],
                    initialLocalId: args['initialLocalId'],
                    initialChoiceId: args['initialChoiceId'],
                    initialActionId: args['initialActionId'],
                    existingImages: args['existingImages'] as List<String>? ?? [],
                  ),
                ),
              );

            // --- ЛИЧНЫЕ СООБЩЕНИЯ (ЧАТ) ---
            case '/chat':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => BlocProvider<ChatBloc>(
                  create: (context) => di.sl<ChatBloc>(), 
                  child: ChatRoomPage(
                    recipientId: args['recipientId'] as int,
                    recipientName: args['username'] as String,
                    avatarUrl: args['avatarUrl'] as String?,
                    currentLocale: args['currentLocale'] as String,
                  ),
                ),
              );

            // --- ЛИЧНЫЙ КАБИНЕТ (ПРОФИЛЬ) ---
            case '/profile':
              return MaterialPageRoute(
                builder: (_) => BlocProvider<ProfileBloc>(
                  create: (context) => di.sl<ProfileBloc>()..add(GetProfileData('uk')), 
                  child: const ProfilePage(currentLocale: 'uk'),
                ),
              );

            default:
              return MaterialPageRoute(builder: (_) => const LoginPage());
          }
        },
      ),
    );
  }
}