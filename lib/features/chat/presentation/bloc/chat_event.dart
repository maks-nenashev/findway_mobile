import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// Загрузить историю сообщений
class FetchMessages extends ChatEvent {
  final int recipientId;
  final String locale;

  const FetchMessages({required this.recipientId, required this.locale});

  @override
  List<Object?> get props => [recipientId, locale];
}

// Отправить новое сообщение
class SendMessage extends ChatEvent {
  final int recipientId;
  final String body;
  final String locale;

  const SendMessage({
    required this.recipientId, 
    required this.body, 
    required this.locale
  });

  @override
  List<Object?> get props => [recipientId, body, locale];
}

class FetchInbox extends ChatEvent {
  final String locale;
  const FetchInbox({required this.locale});
  
  @override
  List<Object?> get props => [locale];
}