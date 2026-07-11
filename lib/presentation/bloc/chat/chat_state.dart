part of 'chat_bloc.dart';

class ChatState {
  final List<MessageModel> messages;
  final bool isTyping;
  final bool isLoading;
  final String? error;
  final bool autoSpeakEnabled;
  final String currentPersona;
  final bool isOffline;

  const ChatState({
    this.messages = const [],
    this.isTyping = false,
    this.isLoading = false,
    this.error,
    this.autoSpeakEnabled = false,
    this.currentPersona = 'assistant',
    this.isOffline = false,
  });

  ChatState copyWith({
    List<MessageModel>? messages,
    bool? isTyping,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? autoSpeakEnabled,
    String? currentPersona,
    bool? isOffline,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      autoSpeakEnabled: autoSpeakEnabled ?? this.autoSpeakEnabled,
      currentPersona: currentPersona ?? this.currentPersona,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}