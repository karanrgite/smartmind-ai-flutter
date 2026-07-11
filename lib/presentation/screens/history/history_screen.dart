import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/models/conversation_model.dart';
import '../../bloc/history/history_bloc.dart';
import '../chat/chat_screen.dart';

const _bgColor   = Color(0xFF0B0B0D);
const _cardBg    = Color(0xFF1A1A1D);
const _accent    = Color(0xFFFF6A2B);
const _hintColor = Color(0xFF8A8A8E);

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryBloc(chatRepository: ChatRepository())
        ..add(LoadConversationsEvent()),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoryBloc, HistoryState>(
      listenWhen: (prev, curr) => prev.newlyCreated != curr.newlyCreated && curr.newlyCreated != null,
      listener: (context, state) {
        final conv = state.newlyCreated!;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conv.id,
              conversationTitle: conv.title,
            ),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          title: const Text('Conversations',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _accent,
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => context.read<HistoryBloc>().add(CreateNewConversationEvent()),
        ),
        body: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state.isLoading && state.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: _accent));
            }

            if (state.error != null && state.conversations.isEmpty) {
              return _buildErrorState(context, state.error!);
            }

            if (state.conversations.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              color: _accent,
              onRefresh: () async => context.read<HistoryBloc>().add(LoadConversationsEvent()),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) => Divider(
                  color: Colors.white.withOpacity(0.05),
                  height: 1,
                  indent: 72,
                ),
                itemBuilder: (context, index) {
                  final conv = state.conversations[index];
                  return _ConversationTile(conversation: conv);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: _hintColor),
          const SizedBox(height: 16),
          const Text('No conversations yet',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Tap + to start chatting with SmartMind',
              style: TextStyle(color: _hintColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(error, style: TextStyle(color: _hintColor), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.read<HistoryBloc>().add(LoadConversationsEvent()),
            child: const Text('Retry', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  const _ConversationTile({required this.conversation});

  String _formatTimestamp(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0 && now.day == time.day) {
      return DateFormat.jm().format(time); // "3:45 PM"
    } else if (diff.inDays < 7) {
      return DateFormat.E().format(time); // "Mon"
    } else {
      return DateFormat.MMMd().format(time); // "Jul 4"
    }
  }

  IconData _personaIcon(String? persona) {
    switch (persona) {
      case 'teacher':
        return Icons.school_outlined;
      case 'coder':
        return Icons.code;
      case 'friend':
        return Icons.favorite_outline;
      case 'analyst':
        return Icons.bar_chart;
      default:
        return Icons.smart_toy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(conversation.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade700,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) {
        context.read<HistoryBloc>().add(
          DeleteConversationFromHistoryEvent(conversation.id),
        );
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: _cardBg,
          child: Icon(_personaIcon(conversation.persona), color: _accent, size: 20),
        ),
        title: Text(
          conversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          conversation.lastMessage ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _hintColor, fontSize: 13),
        ),
        trailing: Text(
          _formatTimestamp(conversation.updatedAt),
          style: TextStyle(color: _hintColor, fontSize: 12),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conversation.id,
                conversationTitle: conversation.title,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: const Text('Delete conversation?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently delete "${conversation.title}".',
          style: TextStyle(color: _hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;
  }
}