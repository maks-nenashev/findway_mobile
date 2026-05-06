import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Для форматирования времени
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../data/models/message_model.dart';
import '../../../../injection_container.dart';

class ChatRoomPage extends StatefulWidget {
  final int recipientId;
  final String recipientName;
  final String? avatarUrl;
  final String currentLocale;

  const ChatRoomPage({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.avatarUrl,
    required this.currentLocale,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Инициируем загрузку истории сообщений при входе
    context.read<ChatBloc>().add(FetchMessages(
      recipientId: widget.recipientId,
      locale: widget.currentLocale,
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(SendMessage(
      recipientId: widget.recipientId,
      body: text,
      locale: widget.currentLocale,
    ));

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00F2FF);
    const Color darkSlate = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
              child: widget.avatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.recipientName.toUpperCase(),
                style: const TextStyle(
                  color: darkSlate,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron', // Твой фирменный шрифт
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. СПИСОК СООБЩЕНИЙ
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatLoading) {
                  return const Center(child: CircularProgressIndicator(color: neonCyan));
                }

                if (state is ChatError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                if (state is ChatLoaded) {
                  final messages = state.messages.reversed.toList(); // Для reverse ListView

                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages yet. Say hello!'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Новые сообщения внизу
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      // Определяем, я отправитель или нет (ID берем из системы)
                      // Для простоты: если senderId == recipientId, значит это входящее
                      final bool isMe = msg.senderId != widget.recipientId;

                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),

          // 2. ПОЛЕ ВВОДА
          _buildInputArea(neonCyan, darkSlate),
        ],
      ),
    );
  }

  // Виджет пузырька сообщения
  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: !isMe ? Border.all(color: Colors.black.withOpacity(0.05)) : null,
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.body,
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.createdAt),
              style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // Поле ввода сообщения
  Widget _buildInputArea(Color accentColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), // Доп. отступ снизу
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _onSend,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}