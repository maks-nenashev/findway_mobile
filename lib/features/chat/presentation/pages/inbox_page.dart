import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'chat_room_page.dart';
import '../../../../injection_container.dart';

class InboxPage extends StatelessWidget {
  final String currentLocale;

  const InboxPage({super.key, required this.currentLocale});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('MESSAGES', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FF)));
          }

          if (state is InboxLoaded) {
            if (state.conversations.isEmpty) {
              return const Center(child: Text('No active conversations yet.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: state.conversations.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
              itemBuilder: (context, index) {
                final chat = state.conversations[index];
                final otherUser = chat['other_user']; // Тот, с кем переписка

                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: otherUser['avatar'] != null 
                        ? NetworkImage(otherUser['avatar']) 
                        : null,
                    child: otherUser['avatar'] == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(
                    otherUser['username'] ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  subtitle: Text(
                    chat['last_message']?['body'] ?? 'No messages',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: chat['unread_count'] > 0 
                      ? CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Text('${chat['unread_count']}', style: const TextStyle(fontSize: 10, color: Colors.white)))
                      : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    // Переход в конкретный чат
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => sl<ChatBloc>(),
                          child: ChatRoomPage(
                            recipientId: otherUser['id'],
                            recipientName: otherUser['username'],
                            avatarUrl: otherUser['avatar'],
                            currentLocale: currentLocale,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }

          if (state is ChatError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const SizedBox();
        },
      ),
    );
  }
}