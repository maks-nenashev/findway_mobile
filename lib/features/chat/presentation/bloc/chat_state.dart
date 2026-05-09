import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}
class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  const ChatLoaded({required this.messages});
  @override
  List<Object?> get props => [messages];
}

// 👉 ВОЗВРАЩАЕМ ТИП ДЛЯ INBOX_PAGE
class InboxLoaded extends ChatState {
  final List<dynamic> conversations;
  const InboxLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}