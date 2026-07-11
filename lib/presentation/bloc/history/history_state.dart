part of 'history_bloc.dart';

class HistoryState {
  final List<ConversationModel> conversations;
  final bool isLoading;
  final String? error;
  final ConversationModel? newlyCreated;

  const HistoryState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.newlyCreated,
  });

  HistoryState copyWith({
    List<ConversationModel>? conversations,
    bool? isLoading,
    String? error,
    bool clearError = false,
    ConversationModel? newlyCreated,
    bool clearNewlyCreated = false,
  }) {
    return HistoryState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      newlyCreated: clearNewlyCreated ? null : (newlyCreated ?? this.newlyCreated),
    );
  }
}