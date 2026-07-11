part of 'history_bloc.dart';

abstract class HistoryEvent {}

class LoadConversationsEvent extends HistoryEvent {}

class DeleteConversationFromHistoryEvent extends HistoryEvent {
  final String conversationId;
  DeleteConversationFromHistoryEvent(this.conversationId);
}

class CreateNewConversationEvent extends HistoryEvent {}