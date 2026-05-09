import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class InboxPage extends StatelessWidget {
  final String currentLocale;

  const InboxPage({super.key, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('MESSAGES', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: darkSlate,
        elevation: 1,
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InboxLoaded) {
            final conversations = state.conversations;

            if (conversations.isEmpty) {
              return const Center(child: Text('No conversations yet.'));
            }

            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                // 👉 ВОТ ЗДЕСЬ ОПРЕДЕЛЯЕМ ПЕРЕМЕННУЮ conversation
                final conversation = conversations[index];
                final otherUser = conversation['other_user'] ?? {};
                final lastMessage = conversation['last_message'] ?? {};
                final String? avatarUrl = otherUser['avatar_url'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // --- АВАТАРКА В СПИСКЕ ---
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    (otherUser['username'] ?? 'Unknown').toString().toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    lastMessage['body'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    lastMessage['created_at'] ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  onTap: () {
                    // --- ПЕРЕДАЧА ДАННЫХ В ЧАТ ---
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: {
                        'recipientId': otherUser['id'],
                        'username': otherUser['username'],
                        'avatarUrl': avatarUrl, // Передаем ссылку дальше
                        'currentLocale': currentLocale,
                      },
                    );
                  },
                );
              },
            );
          }

          if (state is ChatError) {
            return Center(child: Text(state.message));
          }

          return const SizedBox();
        },
      ),
    );
  }
}