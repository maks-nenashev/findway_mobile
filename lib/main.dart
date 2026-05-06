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
        initialRoute: '/login', 
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
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