import 'package:equatable/equatable.dart';

import '../../data/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

/// Loading state keeps the last known translations available to the UI.
class ChatLoading extends ChatState {
  final Map<String, dynamic> translations;

  const ChatLoading({this.translations = const <String, dynamic>{}});

  @override
  List<Object?> get props => [translations];
}

class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  final Map<String, dynamic> translations;

  const ChatLoaded({
    required this.messages,
    this.translations = const <String, dynamic>{},
  });

  @override
  List<Object?> get props => [messages, translations];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class InboxLoaded extends ChatState {
  final List<dynamic> conversations;
  final Map<String, dynamic> translations;

  const InboxLoaded(
    this.conversations, {
    this.translations = const <String, dynamic>{},
  });

  @override
  List<Object?> get props => [conversations, translations];
}