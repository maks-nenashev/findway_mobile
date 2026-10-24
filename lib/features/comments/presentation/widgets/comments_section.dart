// =============================================================================
// FILE: lib/features/comments/presentation/widgets/comments_section.dart
//
// LAYER: Presentation
// PURPOSE:
//   - Отображение списка комментариев.
//   - Добавление, редактирование и удаление комментариев.
//   - Корректная обработка URL аватаров.
//   - Поддержка локального Rails API через getBaseUrl().
//   - Отображение резервной иконки при отсутствии или ошибке аватара.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:findway_mobile/injection_container.dart';

import 'package:findway_mobile/features/comments/presentation/bloc/comments_bloc.dart';
import 'package:findway_mobile/features/comments/presentation/bloc/comments_event.dart';
import 'package:findway_mobile/features/comments/presentation/bloc/comments_state.dart';
import 'package:findway_mobile/features/comments/data/models/comment_model.dart';

// =============================================================================
// COMMENTS SECTION
// =============================================================================

class CommentsSection extends StatelessWidget {
  final Map<String, dynamic> tr;

  const CommentsSection({
    super.key,
    required this.tr,
  });

  static String? sanitizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final cleanUrl = url.trim();
    final baseUri = Uri.parse(getBaseUrl());
    final uri = Uri.tryParse(cleanUrl);

    if (uri == null) {
      return null;
    }

 
    // Преобразуем в абсолютный URL относительно Rails.
    if (!uri.hasScheme || uri.host.isEmpty) {
      return baseUri.resolve(cleanUrl).toString();
    }

    // Адреса, которые могли сохраниться в старых данных.
    const localHosts = {
      'localhost',
      '127.0.0.1',
      '10.0.2.2',
      '10.235.162.74',
    };

    // Локальные адреса заменяем текущим базовым адресом приложения.
    if (localHosts.contains(uri.host.toLowerCase())) {
      return uri
          .replace(
            scheme: baseUri.scheme,
            host: baseUri.host,
            port: baseUri.hasPort ? baseUri.port : null,
          )
          .toString();
    }

    // Внешние URL не изменяем.
    // Это важно для S3 и других внешних хранилищ.
    return cleanUrl;
  }

  // ===========================================================================
  // ADD COMMENT BOTTOM SHEET
  // ===========================================================================

  static void showAddCommentSheet(
    BuildContext context,
    Map<String, dynamic> tr,
  ) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Индикатор верхней границы окна.
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Заголовок.
              Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFFFF8A00),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (tr['your_comment'] ?? 'Your Comment')
                        .toString()
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Поле ввода нового комментария.
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: tr['place_writhe'] ?? 'Напишіть щось...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8A00),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Отправка комментария через CommentsBloc.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: const Color(0xFF0F172A),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();

                  final text = controller.text.trim();

                  if (text.isNotEmpty) {
                    context.read<CommentsBloc>().add(
                          AddComment(text),
                        );

                    Navigator.pop(sheetContext);
                  }
                },
                child: Text(
                  tr['submit_comment'] ?? 'SUBMIT',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MAIN COMMENTS UI
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return BlocListener<CommentsBloc, CommentsState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        // Уведомления об успешном действии.
        if (state is CommentActionSuccess) {
          if (state.success != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.success!),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          if (state.warning != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(state.warning!),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // После добавления, редактирования или удаления
          // повторно загружаем список комментариев.
          context.read<CommentsBloc>().add(
                const FetchComments(),
              );
        }

        // Ошибки операций с комментариями.
        if (state is CommentsError) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок секции.
          Row(
            children: [
              const Icon(
                Icons.forum_rounded,
                color: Color(0xFF00F2FF),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                (tr['your_comment'] ?? 'КОМЕНТАРІ')
                    .toString()
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                  color: Color(0xFF00F2FF),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Отображение состояния списка комментариев.
          BlocBuilder<CommentsBloc, CommentsState>(
            builder: (context, state) {
              if (state is CommentsLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00F2FF),
                  ),
                );
              }

              if (state is CommentsLoaded) {
                // Пустой список.
                if (state.comments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white10,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tr['place_writhe'] ??
                            'Коментарів поки немає. Будьте першим!',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }

                // Список комментариев.
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.comments.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _CommentNode(
                      comment: state.comments[index],
                      tr: tr,
                    );
                  },
                );
              }

              // Для остальных состояний ничего не отображаем.
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// COMMENT NODE
//
// Отдельная карточка комментария:
//   - аватар автора;
//   - имя и дата;
//   - текст комментария;
//   - кнопки редактирования и удаления при наличии прав.
// =============================================================================

class _CommentNode extends StatelessWidget {
  final CommentModel comment;
  final Map<String, dynamic> tr;

  const _CommentNode({
    required this.comment,
    required this.tr,
  });

  // ===========================================================================
  // EDIT COMMENT BOTTOM SHEET
  // ===========================================================================

  void _showEditCommentSheet(BuildContext context) {
    final controller = TextEditingController(
      text: comment.body,
    );

    final bloc = context.read<CommentsBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr['edit_comment'] ?? 'Редагувати коментар',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),

              const SizedBox(height: 16),

              // Редактируемый текст.
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF3B82F6),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Сохранение изменений.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();

                  final text = controller.text.trim();

                  if (text.isNotEmpty && text != comment.body) {
                    bloc.add(
                      UpdateComment(
                        commentId: comment.id,
                        newBody: text,
                      ),
                    );
                  }

                  Navigator.pop(sheetContext);
                },
                child: Text(
                  tr['save_comment'] ?? 'ЗБЕРЕГТИ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // AVATAR WIDGET
  //
  // Image.network используется вместо backgroundImage, чтобы можно было
  // обработать ошибку загрузки и показать резервную иконку.
  // ===========================================================================

  Widget _buildAvatar(String? avatarUrl) {
    const avatarRadius = 16.0;
    const avatarSize = avatarRadius * 2;

    return Container(
      width: avatarSize + 3,
      height: avatarSize + 3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF00F2FF).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFF1E293B),
          child: avatarUrl == null
              ? _avatarFallback()
              : Image.network(
                  avatarUrl,
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.cover,

                  // Во время загрузки показываем нейтральный фон.
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return _avatarFallback();
                  },

                  // Если URL недоступен, возвращаем иконку пользователя.
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      '[CommentsSection] Avatar load failed: '
                      '$avatarUrl; error: $error',
                    );

                    return _avatarFallback();
                  },
                ),
        ),
      ),
    );
  }

  // Резервная иконка для отсутствующего или недоступного аватара.
  Widget _avatarFallback() {
    return const Center(
      child: Icon(
        Icons.person,
        size: 16,
        color: Color(0xFF00F2FF),
      ),
    );
  }

  // ===========================================================================
  // COMMENT CARD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    // Нормализуем URL перед передачей в Image.network.
    final String? avatarUrl = CommentsSection.sanitizeUrl(
      comment.avatarUrl,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F2FF).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Верхняя строка: аватар, имя, дата и действия.
          Row(
            children: [
              // Аватар с обработкой ошибки загрузки.
              _buildAvatar(avatarUrl),

              const SizedBox(width: 10),

              // Имя пользователя и дата комментария.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      comment.createdAt,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),

              // Редактирование доступно только при наличии прав.
              if (comment.canEdit)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: Color(0xFF3B82F6),
                  ),
                  onPressed: () => _showEditCommentSheet(context),
                ),

              // Удаление доступно только при наличии прав.
              if (comment.canDelete)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFFEF4444),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();

                    context.read<CommentsBloc>().add(
                          DeleteComment(
                            commentId: comment.id,
                          ),
                        );
                  },
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Текст комментария.
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              comment.body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}