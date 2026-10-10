import 'package:dio/dio.dart';
import '../models/message_model.dart';

class ChatRepository {
  final Dio client;

  ChatRepository({required this.client});

  /// Получение списка сообщений диалога с конкретным пользователем
  Future<List<MessageModel>> getConversation(int recipientId, String locale) async {
    try {
      final response = await client.get(
        '/api/v1/messages/$recipientId',
        queryParameters: {'locale': locale},
      );
      final List<dynamic> data = response.data['messages'] ?? [];
      return data.map((m) => MessageModel.fromJson(m)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load conversation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load conversation: $e');
    }
  }

  /// Отправка нового сообщения
  Future<MessageModel> sendMessage(int recipientId, String body, String locale) async {
    try {
      final response = await client.post(
        '/api/v1/messages',
        data: {
          'message': {'recipient_id': recipientId, 'body': body},
          'locale': locale,
        },
      );
      return MessageModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Удаление переписки с пользователем
  Future<void> deleteConversation(int recipientId) async {
    try {
      await client.delete(
        '/api/v1/messages/purge',
        queryParameters: {'recipient_id': recipientId},
      );
    } on DioException catch (e) {
      throw Exception('Failed to delete conversation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Получение списка диалогов (Inbox)
  Future<List<dynamic>> getInbox(String locale) async {
    try {
      final response = await client.get(
        '/api/v1/messages',
        queryParameters: {'locale': locale},
      );
      return response.data['conversations'] ?? [];
    } on DioException catch (e) {
      throw Exception('Failed to load inbox: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load inbox: $e');
    }
  }

  /// Получение общего количества непрочитанных сообщений
  Future<int> getTotalUnreadCount() async {
    try {
      final response = await client.get('/api/v1/messages/unread_total');

      if (response.data != null && response.data is Map) {
        final rawValue = response.data['unread_total'];
        return int.tryParse(rawValue.toString()) ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      // 401 Unauthorized — штатное гостевое состояние.
      // Не бросаем исключение, чтобы не ломать фоновый опрос и не засорять логи.
      if (e.response?.statusCode == 401) {
        return 0;
      }
      // Безопасный фоллбек для остальных ошибок (500, таймауты и т.д.)
      return 0;
    } catch (_) {
      return 0;
    }
  }
}