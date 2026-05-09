import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class FetchMessages extends ChatEvent {
  final int recipientId;
  final String locale;
  const FetchMessages({required this.recipientId, required this.locale});
}

class SendMessage extends ChatEvent {
  final int recipientId;
  final String body;
  final String locale;
  const SendMessage({required this.recipientId, required this.body, required this.locale});
}

class DeleteChat extends ChatEvent {
  final int recipientId;
  const DeleteChat({required this.recipientId});
}

// 👉 ВОЗВРАЩАЕМ СОБЫТИЕ ДЛЯ SEARCH_PAGE
class FetchInbox extends ChatEvent {
  final String locale;
  const FetchInbox({required this.locale});
  @override
  List<Object?> get props => [locale];
}