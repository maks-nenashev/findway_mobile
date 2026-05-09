import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;

// --- СТРАНИЦЫ ---
import 'package:findway_mobile/features/search/presentation/pages/search_page.dart';
import 'package:findway_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:findway_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:findway_mobile/features/search/presentation/pages/post_card_page.dart';
import 'package:findway_mobile/features/search/presentation/pages/post_edit_page.dart';
import 'package:findway_mobile/features/chat/presentation/pages/chat_room_page.dart'; // 👉 Добавлено

// --- БЛОКИ И СОБЫТИЯ ---
import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:findway_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:findway_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';
import 'package:findway_mobile/features/chat/presentation/bloc/chat_bloc.dart'; // 👉 Добавлено

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация зависимостей (GetIt)
  await di.init();
  
  runApp(const FindWayApp());
}

class FindWayApp extends StatelessWidget {
  const FindWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Глобальные блоки (доступны везде)
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FindWay',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF00F2FF),
          fontFamily: 'Orbitron', // Твой фирменный стиль
        ),
        
        // Точка входа (Меняй на '/' или '/login' при релизе)
        initialRoute: '/profile', 

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

            // --- РЕДАКТИРОВАНИЕ ---
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

            // --- ПРОФИЛЬ ---
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