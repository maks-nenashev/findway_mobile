import 'package:dio/dio.dart';
import '../models/message_model.dart';

class ChatRepository {
  final Dio client;

  ChatRepository({required this.client});

  // =========================================================
  // 👉 1. ПОЛУЧИТЬ ИСТОРИЮ ЧАТА (Метод show)
  // =========================================================
  Future<List<MessageModel>> getConversation(int recipientId, String locale) async {
    try {
      // Согласно твоему контроллеру: GET /api/v1/messages/:id
      final response = await client.get(
        '/api/v1/messages/$recipientId', 
        queryParameters: {'locale': locale},
      );
      
      // Твой контроллер возвращает { recipient: ..., messages: [...] }
      final List<dynamic> messagesData = response.data['messages'] ?? [];
      return messagesData.map((m) => MessageModel.fromJson(m)).toList();
    } catch (e) {
      throw Exception('Failed to load conversation: $e');
    }
  }

  // =========================================================
  // 👉 2. ОТПРАВИТЬ СООБЩЕНИЕ (Метод create)
  // =========================================================
  Future<MessageModel> sendMessage(int recipientId, String body, String locale) async {
    try {
      final response = await client.post(
        '/api/v1/messages',
        data: {
          'message': {
            'recipient_id': recipientId,
            'body': body,
          },
          'locale': locale
        },
      );

      // Контроллер возвращает созданный объект @message
      return MessageModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }
  
  // =========================================================
  // 👉 3. ПОЛУЧИТЬ СПИСОК ДИАЛОГОВ (Метод index)
  // =========================================================
  Future<List<dynamic>> getInbox(String locale) async {
    try {
      final response = await client.get(
        '/api/v1/messages', 
        queryParameters: {'locale': locale},
      );
      // Твой контроллер возвращает { conversations: [...] }
      return response.data['conversations'] ?? [];
    } catch (e) {
      throw Exception('Failed to load inbox: $e');
    }
  }
}