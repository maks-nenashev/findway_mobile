import 'package:dio/dio.dart';
import '../models/message_model.dart';

class ChatRepository {
  final Dio client;

  ChatRepository({required this.client});

  // =========================================================
  // 👉 1. ПОЛУЧИТЬ ИСТОРИЮ ЧАТА
  // =========================================================
  Future<List<MessageModel>> getConversation(int recipientId, String locale) async {
    try {
      final response = await client.get(
        '/messages/$recipientId.json',
        queryParameters: {'locale': locale},
      );
      
      final List<dynamic> messagesData = response.data['messages'] ?? [];
      return messagesData.map((m) => MessageModel.fromJson(m)).toList();
    } catch (e) {
      throw Exception('Failed to load conversation: $e');
    }
  }

  // =========================================================
  // 👉 2. ОТПРАВИТЬ СООБЩЕНИЕ
  // =========================================================
  Future<MessageModel> sendMessage(int recipientId, String body, String locale) async {
    try {
      final response = await client.post(
        '/messages.json',
        queryParameters: {'locale': locale},
        data: {
          'message': {
            'recipient_id': recipientId,
            'body': body,
          }
        },
      );

      return MessageModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
  
  // =========================================================
  // 👉 3. ПОЛУЧИТЬ СПИСОК ДИАЛОГОВ (INBOX)
  // =========================================================
  Future<List<dynamic>> getInbox(String locale) async {
    try {
      final response = await client.get(
        '/messages.json',
        queryParameters: {'locale': locale},
      );
      return response.data['conversations'] ?? [];
    } catch (e) {
      throw Exception('Failed to load inbox: $e');
    }
  }
}