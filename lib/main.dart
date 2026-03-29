import 'package:flutter/material.dart';
import 'injection_container.dart' as di;
// Не забудь импортировать страницу поиска
import 'features/search/presentation/pages/search_page.dart'; 

void main() async {
  // Гарантируем инициализацию фреймворка перед вызовом асинхронных методов
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем зависимости (Dio, DataSources, BLoCs)
  await di.init();
  
  runApp(const FindWayApp());
}

class FindWayApp extends StatelessWidget {
  const FindWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Убираем дебаг-плашку для чистоты
      title: 'FindWay',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue, 
      ),
      // Указываем наш основной экран поиска
      home: const SearchPage(), 
    );
  }
}