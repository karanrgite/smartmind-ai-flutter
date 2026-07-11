part of 'chat_bloc.dart';

abstract class ChatEvent {}

class LoadMessagesEvent extends ChatEvent {
  final String conversationId;
  LoadMessagesEvent(this.conversationId);
}

class SendMessageEvent extends ChatEvent {
  final String conversationId;
  final String message;
  SendMessageEvent({required this.conversationId, required this.message});
}

class ToggleAutoSpeakEvent extends ChatEvent {
  @override
  List<Object?> get props => [];
}

class DeleteConversationEvent extends ChatEvent {
  final String conversationId;
  DeleteConversationEvent(this.conversationId);
}

class ChangePersonaEvent extends ChatEvent {
  final String conversationId;
  final String persona;
  ChangePersonaEvent({required this.conversationId, required this.persona});
}
class ConnectivityChangedEvent extends ChatEvent {
  final bool isOffline;
  ConnectivityChangedEvent(this.isOffline);
}

class ClearErrorEvent extends ChatEvent {}