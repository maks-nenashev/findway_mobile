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
}