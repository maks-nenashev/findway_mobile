import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  Map<String, dynamic> _translationsCache = <String, dynamic>{};

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<FetchMessages>(_onFetchMessages);
    on<SendMessage>(_onSendMessage);
    on<DeleteChat>(_onDeleteChat);
    on<FetchInbox>(_onFetchInbox);
  }

  Future<void> _onFetchMessages(
    FetchMessages event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading(translations: _translationsCache));

    try {
      // Запускаем оба запроса параллельно: сообщения и переводы Rails.
      final messagesFuture =
          repository.getConversation(event.recipientId, event.locale);
      final translationsFuture = repository.getTranslations(event.locale);

      final messages = await messagesFuture;
      final incomingTranslations = await translationsFuture;
      if (incomingTranslations.isNotEmpty) {
        _translationsCache = incomingTranslations;
      }

      emit(ChatLoaded(
        messages: messages,
        translations: _translationsCache,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    try {
      final newMessage = await repository.sendMessage(
        event.recipientId,
        event.body,
        event.locale,
      );
      final updated = List<MessageModel>.from(currentState.messages)
        ..add(newMessage);

      emit(ChatLoaded(
        messages: updated,
        translations: currentState.translations,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onDeleteChat(
    DeleteChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await repository.deleteConversation(event.recipientId);
      emit(ChatLoaded(
        messages: const <MessageModel>[],
        translations: _translationsCache,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onFetchInbox(
    FetchInbox event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading(translations: _translationsCache));

    try {
      // Запускаем оба запроса параллельно, чтобы лишний раз не ждать сеть.
      final conversationsFuture = repository.getInbox(event.locale);
      final translationsFuture = repository.getTranslations(event.locale);

      final conversations = await conversationsFuture;
      final incomingTranslations = await translationsFuture;
      if (incomingTranslations.isNotEmpty) {
        _translationsCache = incomingTranslations;
      }

      emit(InboxLoaded(
        conversations,
        translations: _translationsCache,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }
}