import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_state.dart';

/// Inbox page styled to match FindWay's dark navy / neon accent visual system.
/// Conversation loading, navigation, unread counts, and Rails translations remain
/// connected to the existing ChatBloc and API flow.
class InboxPage extends StatelessWidget {
  final String currentLocale;

  const InboxPage({super.key, required this.currentLocale});

  // White canvas keeps the Inbox light; the app bar and conversation cards stay dark.
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _badgeInk = Color(0xFF0B1020);
  static const Color _pageTextMuted = Color(0xFF475569);
  static const Color _surface = Color(0xFF151A2D);
  static const Color _surfaceElevated = Color(0xFF1C2637);
  static const Color _cyan = Color(0xFF00E5F2);
  static const Color _textPrimary = Color(0xFFF4F7FB);
  static const Color _textMuted = Color(0xFF8D9AAF);
  static const Color _outline = Color(0xFF26394B);

  Map<String, dynamic> _translationsFor(ChatState state) {
    if (state is InboxLoaded) return state.translations;
    if (state is ChatLoading) return state.translations;
    if (state is ChatLoaded) return state.translations;
    return const <String, dynamic>{};
  }

  String _tr(
    Map<String, dynamic> translations,
    String key,
    String fallback,
  ) {
    final value = translations[key];
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        centerTitle: false,
        shape: const Border(
          bottom: BorderSide(color: _cyan, width: 0.8),
        ),
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            final translations = _translationsFor(state);
            return Row(
              children: [
                const Icon(Icons.forum_rounded, color: _cyan, size: 23),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    _tr(
                      translations,
                      'shared.message_form.title',
                      'MESSAGES',
                    ).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _cyan),
            );
          }

          if (state is InboxLoaded) {
            final conversations = state.conversations;
            final translations = state.translations;

            if (conversations.isEmpty) {
              return _buildEmptyState(
                _tr(
                  translations,
                  'messages.index.empty',
                  'No conversations yet.',
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final otherUser = conversation['other_user'] ?? {};
                final lastMessage = conversation['last_message'] ?? {};
                final String? avatarUrl = otherUser['avatar_url']?.toString();
                final String username = (otherUser['username'] ??
                        _tr(
                          translations,
                          'messages.index.unknown_user',
                          'Unknown',
                        ))
                    .toString();
                final String messagePreview =
                    lastMessage['body']?.toString() ?? '';
                final String timestamp =
                    lastMessage['created_at']?.toString() ?? '';
                final int unreadCount = int.tryParse(
                      '${conversation['unread_count'] ?? 0}',
                    ) ??
                    0;
                final bool hasUnread = unreadCount > 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: {
                            'recipientId': otherUser['id'],
                            'username': otherUser['username'],
                            'avatarUrl': avatarUrl,
                            'currentLocale': currentLocale,
                          },
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasUnread ? _cyan.withValues(alpha: 0.72) : _outline,
                            width: hasUnread ? 1.0 : 0.7,
                          ),
                          boxShadow: hasUnread
                              ? [
                                  BoxShadow(
                                    color: _cyan.withValues(alpha: 0.07),
                                    blurRadius: 12,
                                    spreadRadius: 0.2,
                                  ),
                                ]
                              : const [],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(13, 14, 13, 14),
                          child: Row(
                            children: [
                              _buildAvatar(
                                avatarUrl: avatarUrl,
                                username: username,
                                hasUnread: hasUnread,
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            username,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _textPrimary,
                                              fontSize: 14,
                                              fontWeight: hasUnread
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (timestamp.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            timestamp,
                                            style: const TextStyle(
                                              color: _textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 7),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            messagePreview,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: hasUnread
                                                  ? _textPrimary
                                                  : _textMuted,
                                              fontSize: 13,
                                              height: 1.35,
                                              fontWeight: hasUnread
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (hasUnread) ...[
                                          const SizedBox(width: 10),
                                          Container(
                                            constraints: const BoxConstraints(
                                              minWidth: 22,
                                              minHeight: 22,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _cyan,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              unreadCount > 99 ? '99+' : '$unreadCount',
                                              style: const TextStyle(
                                                color: _badgeInk,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: _textMuted,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          if (state is ChatError) {
            return _buildErrorState(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildAvatar({
    required String? avatarUrl,
    required String username,
    required bool hasUnread,
  }) {
    final bool hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hasUnread ? _cyan : _outline,
          width: hasUnread ? 1.5 : 1,
        ),
      ),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: _surfaceElevated,
        backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
        child: hasAvatar
            ? null
            : Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: _cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _cyan.withValues(alpha: 0.55)),
              ),
              child: const Icon(
                Icons.forum_outlined,
                size: 35,
                color: _cyan,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _pageTextMuted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFF5263).withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5263)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: _textPrimary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
