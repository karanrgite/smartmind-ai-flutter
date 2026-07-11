import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/repositories/chat_repository.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ChatRepository chatRepository;

  HistoryBloc({required this.chatRepository}) : super(const HistoryState()) {
    on<LoadConversationsEvent>(_onLoad);
    on<DeleteConversationFromHistoryEvent>(_onDelete);
    on<CreateNewConversationEvent>(_onCreate);
  }

  Future<void> _onLoad(
      LoadConversationsEvent event,
      Emitter<HistoryState> emit,
      ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final conversations = await chatRepository.getConversations();
      // Most recently updated first
      conversations.sort((a, b) {
        final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      emit(state.copyWith(conversations: conversations, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Failed to load conversations. Pull down to retry.',
      ));
    }
  }

  Future<void> _onDelete(
      DeleteConversationFromHistoryEvent event,
      Emitter<HistoryState> emit,
      ) async {
    final previous = state.conversations;
    final updated = previous.where((c) => c.id != event.conversationId).toList();
    emit(state.copyWith(conversations: updated));

    try {
      await chatRepository.deleteConversation(event.conversationId);
    } catch (e) {
      emit(state.copyWith(
        conversations: previous,
        error: 'Failed to delete conversation.',
      ));
    }
  }

  Future<void> _onCreate(
      CreateNewConversationEvent event,
      Emitter<HistoryState> emit,
      ) async {
    try {
      final newConv = await chatRepository.createConversation('New Chat');
      emit(state.copyWith(
        conversations: [newConv, ...state.conversations],
        newlyCreated: newConv,
      ));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to create new conversation.'));
    }
  }
}