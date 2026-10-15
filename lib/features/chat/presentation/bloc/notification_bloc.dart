import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';

abstract class NotificationEvent {}
class CheckUnread extends NotificationEvent {}

class NotificationBloc extends Bloc<NotificationEvent, int> {
  final ChatRepository repository;
  Timer? _timer;

  NotificationBloc({required this.repository}) : super(0) {
    on<CheckUnread>((event, emit) async {
      try {
        final count = await repository.getTotalUnreadCount();
        emit(count);
      } catch (_) {
        emit(0);
      }
    });

    // Таймер на 30 секунд
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => add(CheckUnread()));
    add(CheckUnread());
  }

  @override
  Future<void> close() {
    _timer?.cancel(); // Критично для памяти
    return super.close();
  }
}