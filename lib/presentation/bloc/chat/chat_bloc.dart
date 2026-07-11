import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  ChatBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(const ChatState()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<DeleteConversationEvent>(_onDeleteConversation);
    on<ClearErrorEvent>((_, emit) => emit(state.copyWith(clearError: true)));
    on<ToggleAutoSpeakEvent>((event, emit) {
      emit(state.copyWith(autoSpeakEnabled: !state.autoSpeakEnabled));
    });
    on<ChangePersonaEvent>(_onChangePersona);
    on<ConnectivityChangedEvent>((event, emit) {
      emit(state.copyWith(isOffline: event.isOffline));
    });

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((result) {
          final offline = result == ConnectivityResult.none;
          add(ConnectivityChangedEvent(offline));
        });
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }


  Future<void> _onLoadMessages(
      LoadMessagesEvent event,
      Emitter<ChatState> emit,
      ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    // Show cache immediately while network loads
    final cached = await _chatRepository.getCachedMessages(event.conversationId);
    if (cached.isNotEmpty) {
      emit(state.copyWith(messages: cached, isLoading: false));
    }

    try {
      final messages = await _chatRepository.getMessages(event.conversationId);
      emit(state.copyWith(messages: messages, isLoading: false));
      await _chatRepository.cacheMessages(event.conversationId, messages);
    } catch (e) {
      // If we already showed cached data, don't show a loading error
      if (cached.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to load messages.',
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> _onSendMessage(
      SendMessageEvent event,
      Emitter<ChatState> emit,
      ) async {
    // Optimistic user bubble immediately
    final userMsg = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: event.conversationId,
      content: event.message,
      role: 'user',
      createdAt: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      clearError: true,
    ));

    try {
      final aiMsg = await _chatRepository.sendMessage(
        event.conversationId,
        event.message,
      );
      final updatedMessages = [...state.messages, aiMsg];
      emit(state.copyWith(messages: updatedMessages, isTyping: false));
      await _chatRepository.cacheMessages(event.conversationId, updatedMessages);
    } catch (e) {
      // Remove optimistic message on failure
      final rollback = [...state.messages]..removeLast();
      emit(state.copyWith(
        messages: rollback,
        isTyping: false,
        error: 'Failed to send. Try again.',
      ));
    }
  }

  Future<void> _onDeleteConversation(
      DeleteConversationEvent event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await _chatRepository.deleteConversation(event.conversationId);
      await _chatRepository.clearCachedMessages(event.conversationId);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to delete conversation.'));
    }
  }
  Future<void> _onChangePersona(
      ChangePersonaEvent event,
      Emitter<ChatState> emit,
      ) async {
    try {
      await _chatRepository.updatePersona(event.conversationId, event.persona);
      emit(state.copyWith(currentPersona: event.persona));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to change persona.'));
    }
  }
}