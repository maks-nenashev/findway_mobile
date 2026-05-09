import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/message_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<FetchMessages>(_onFetchMessages);
    on<SendMessage>(_onSendMessage);
    on<DeleteChat>(_onDeleteChat);
    on<FetchInbox>(_onFetchInbox);
  }

  Future<void> _onFetchMessages(FetchMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final messages = await repository.getConversation(event.recipientId, event.locale);
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      try {
        final newMessage = await repository.sendMessage(event.recipientId, event.body, event.locale);
        final updated = List<MessageModel>.from(currentState.messages)..add(newMessage);
        emit(ChatLoaded(messages: updated));
      } catch (e) {
        emit(ChatError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteChat(DeleteChat event, Emitter<ChatState> emit) async {
    try {
      await repository.deleteConversation(event.recipientId);
      emit(const ChatLoaded(messages: []));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

Future<void> _onFetchInbox(FetchInbox event, Emitter<ChatState> emit) async {
  emit(ChatLoading());
  try {
    final conversations = await repository.getInbox(event.locale);
    emit(InboxLoaded(conversations));
  } catch (e) {
    emit(ChatError(e.toString()));
  }
}
}