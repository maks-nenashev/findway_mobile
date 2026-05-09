import 'package:dio/dio.dart';
import '../models/message_model.dart';

class ChatRepository {
  final Dio client;
  ChatRepository({required this.client});

  Future<List<MessageModel>> getConversation(int recipientId, String locale) async {
    try {
      final response = await client.get('/api/v1/messages/$recipientId', queryParameters: {'locale': locale});
      final List<dynamic> data = response.data['messages'] ?? [];
      return data.map((m) => MessageModel.fromJson(m)).toList();
    } catch (e) { throw Exception('Failed to load conversation: $e'); }
  }

  Future<MessageModel> sendMessage(int recipientId, String body, String locale) async {
    try {
      final response = await client.post('/api/v1/messages', data: {
        'message': {'recipient_id': recipientId, 'body': body},
        'locale': locale
      });
      return MessageModel.fromJson(response.data);
    } catch (e) { throw Exception('Failed to send message: $e'); }
  }

  Future<void> deleteConversation(int recipientId) async {
    try {
      await client.delete('/api/v1/messages/purge', queryParameters: {'recipient_id': recipientId});
    } catch (e) { throw Exception('Failed to delete conversation: $e'); }
  }

  // 👉 ВОЗВРАЩАЕМ ИНБОКС ДЛЯ КОМПИЛЯЦИИ
  Future<List<dynamic>> getInbox(String locale) async {
    try {
      final response = await client.get('/api/v1/messages', queryParameters: {'locale': locale});
      return response.data['conversations'] ?? [];
    } catch (e) { throw Exception('Failed to load inbox: $e'); }
  }

  // 👉 НОВЫЙ МЕТОД ДЛЯ ПОЛУЧЕНИЯ ОБЩЕГО КОЛ-ВА НЕПРОЧИТАННЫХ СООБЩЕНИЙ
// Добавь этот метод ВНУТРЬ класса ChatRepository
  Future<int> getTotalUnreadCount() async {
    try {
      final response = await client.get('/api/v1/messages/unread_total');
      
      if (response.data != null && response.data is Map) {
        // Защита: переводим в строку, потом парсим в число. 
        // Это спасет, если Rails пришлет число как строку.
        final rawValue = response.data['unread_total'];
        final int count = int.tryParse(rawValue.toString()) ?? 0;
        
        return count;
      }
      return 0;
    } catch (e) {
      // Если сервер упал или 404, возвращаем 0, чтобы UI не дергался
      return 0;
    }
  }
}