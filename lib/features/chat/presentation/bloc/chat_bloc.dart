import 'package:flutter_bloc/flutter_bloc.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../data/repositories/chat_repository.dart';
import 'package:findway_mobile/features/chat/data/models/message_model.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    
    // ОБРАБОТКА: Загрузка истории
    on<FetchMessages>((event, emit) async {
      emit(ChatLoading());
      try {
        final messages = await repository.getConversation(event.recipientId, event.locale);
        emit(ChatLoaded(messages: messages));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });

    // ОБРАБОТКА: Отправка сообщения
    on<SendMessage>((event, emit) async {
      final currentState = state;
      
      // Если у нас уже есть загруженные сообщения
      if (currentState is ChatLoaded) {
        // 1. Показываем индикатор отправки (Optimistic UI)
        emit(currentState.copyWith(isSending: true));

        try {
          // 2. Шлем запрос в Rails
          final newMessage = await repository.sendMessage(
            event.recipientId, 
            event.body, 
            event.locale
          );

          // 3. Добавляем полученное сообщение из Rails в текущий список
          final updatedMessages = List<MessageModel>.from(currentState.messages)
            ..add(newMessage);
          
          emit(ChatLoaded(messages: updatedMessages, isSending: false));
        } catch (e) {
          // В случае ошибки возвращаем старый список и выключаем индикатор
          emit(ChatError(e.toString()));
        }
      }
    });
     // ОБРАБОТКА: Загрузка списка диалогов (Inbox)
     on<FetchInbox>((event, emit) async {
      emit(ChatLoading());
      try {
        final conversations = await repository.getInbox(event.locale);
        emit(InboxLoaded(conversations));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    });
  
  }
}