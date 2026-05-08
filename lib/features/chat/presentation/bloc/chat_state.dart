import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

// Состояние первичной загрузки истории
class ChatLoading extends ChatState {}

// Состояние, когда сообщения успешно загружены и отображаются
class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  // Добавляем флаг отправки, чтобы UI мог показать "отправляется..."
  final bool isSending; 

  const ChatLoaded({required this.messages, this.isSending = false});

  @override
  List<Object?> get props => [messages, isSending];

  ChatLoaded copyWith({List<MessageModel>? messages, bool? isSending}) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// Состояние для списка всех диалогов
class InboxLoaded extends ChatState {
  final List<dynamic> conversations;
  const InboxLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}