import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;

// Страницы
import 'package:findway_mobile/features/search/presentation/pages/search_page.dart';
import 'package:findway_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:findway_mobile/features/profile/presentation/pages/profile_page.dart';

// Блоки и События
import 'package:findway_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:findway_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:findway_mobile/features/profile/presentation/bloc/profile_event.dart';

import 'package:findway_mobile/features/search/presentation/bloc/search_bloc.dart';
import 'package:findway_mobile/features/search/presentation/bloc/search_event.dart';
import 'package:findway_mobile/features/search/presentation/pages/post_card_page.dart';
import 'package:findway_mobile/features/search/presentation/pages/post_edit_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const FindWayApp());
}

class FindWayApp extends StatelessWidget {
  const FindWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
          fontFamily: 'Orbitron',
        ),
        //initialRoute: '/login', 
        // Временно подменяем стартовое состояние
       initialRoute: '/profile', // Вместо '/login' for Starting with Profile Page
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            case '/post_details':
              final args = settings.arguments as Map<String, dynamic>?;
              final postId = args?['id'] as int? ?? 0;
              final category = args?['category'] as String? ?? 'people';
              
              return MaterialPageRoute(
                builder: (_) => BlocProvider(
                  // 👉 ИСПОЛЬЗУЕМ ТВОЙ ГОТОВЫЙ БЛОК И ИВЕНТ
                  create: (context) => di.sl<SearchBloc>()..add(LoadPostDetails(
                    id: postId,
                    category: category,
                    locale: 'uk', // Можешь передавать текущую локаль, если нужно
                  )),
                  // 👉 ОТКРЫВАЕМ ТВОЙ ГОТОВЫЙ ЭКРАН
                  child: const PostCardPage(), 
                ),
              );
            case '/post_edit':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  // 👉 КЛЮЧЕВОЙ МОМЕНТ: Передаем ЖИВОЙ Блок из предыдущего экрана
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
            case '/':
              return MaterialPageRoute(builder: (_) => const SearchPage());
            case '/profile':
              return MaterialPageRoute(
                builder: (_) => BlocProvider(
                  // Теперь GetProfileData('uk') совпадает с определением в файле
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