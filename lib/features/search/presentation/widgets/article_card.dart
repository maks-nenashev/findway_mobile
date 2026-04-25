import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:findway_mobile/features/comments/presentation/widgets/comments_section.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../pages/search_details_page.dart';

/// Карточка материала (человека, вещи, животного) в сетке поиска.
/// Показывает картинку, статус, название – с плавным градиентом.
/// При клике загружает детали и после возврата обновляет список.
class ArticleCard extends StatelessWidget {
  final dynamic post;           // Данные поста/материала
  final String currentLocale;   // Текущая локаль

  const ArticleCard({
    required this.post,
    required this.currentLocale,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Получаем метку статуса (верхний голубой бейдж)
    final String statusLabel = (post['choice_label'] ?? '').toString().toUpperCase();

    // ✅ ИСПРАВЛЕНО: Добавлен return, чтобы виджет вернулся на экран
    return GestureDetector(
      // ✅ ИСПРАВЛЕНО: Сделали функцию async для работы с Navigator
      onTap: () async {
        // Захватываем bloc до асинхронного перехода, чтобы передать его на следующий экран
        final bloc = context.read<SearchBloc>();
        final String category = post['category'] ?? 'people';

        // 1. Отправляем событие с ПРАВИЛЬНОЙ ЛОКАЛЬЮ
        bloc.add(LoadPostDetails(
          id: post['id'], 
          category: category, 
          locale: currentLocale, // 🔒 Фикс: жестко передаем локаль интерфейса
        ));

        // 2. Переходим на страницу деталей, прокидывая текущий BLoC
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: const SearchDetailsPage(),
            ),
          ),
        );

        // 3. После возврата автоматически обновляем фильтры и список
        // ✅ ИСПРАВЛЕНО: Используем динамическую категорию вместо захардкоженного 'people'
        if (context.mounted) {
          bloc.add(RestoreSearch());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Эффект тени под картой
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ------ ФОТО ------
              Image.network(
                post['image_url'] ?? "",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]), // если картинки нет
              ),

              // ------ Полупрозрачный градиент-сабблер ------
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),

              // ------ Контент-область снизу ------
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Метка статуса (если есть)
                    if (statusLabel.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00F2FF).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFF00F2FF),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Color(0xFF00F2FF),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ),

                    // ===== Название поста
                    Text(
                      post['title'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Orbitron',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}