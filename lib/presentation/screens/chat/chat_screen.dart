import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../presentation/bloc/chat/chat_bloc.dart';
import 'chat_bubble.dart';
import './voice_input_widgets.dart';
import '../../../core/services/voice_service.dart';
import '../history/history_screen.dart';

const _bgColor   = Color(0xFF0B0B0D);
const _cardBg    = Color(0xFF1A1A1D);
const _inputFill = Color(0xFF1F1F22);
const _accent    = Color(0xFFFF6A2B);
const _hintColor = Color(0xFF8A8A8E);

class ChatScreen extends StatelessWidget {
  final String conversationId;
  final String conversationTitle;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.conversationTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatBloc(chatRepository: ChatRepository())
        ..add(LoadMessagesEvent(conversationId)),
      child: _ChatView(
        conversationId: conversationId,
        conversationTitle: conversationTitle,
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const _ChatView({
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastSpokenMessageId;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    context.read<ChatBloc>().add(SendMessageEvent(
      conversationId: widget.conversationId,
      message: text,
    ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatBloc, ChatState>(
      listenWhen: (prev, curr) =>
      prev.messages.length != curr.messages.length ||
          prev.isTyping != curr.isTyping,
      listener: (context, state) {
        _scrollToBottom();
        if (state.messages.isNotEmpty && !state.isTyping) {
          final last = state.messages.last;
          if (last.role == 'assistant' &&
              state.autoSpeakEnabled &&
              last.id != _lastSpokenMessageId) {
            _lastSpokenMessageId = last.id;
            VoiceService().speak(last.content);
          }
        }
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        resizeToAvoidBottomInset: true, // Scaffold handles keyboard, we don't add extra SizedBox
        appBar: AppBar(
          backgroundColor: _bgColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          title: Text(
            widget.conversationTitle,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: false,
          actions: [
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (prev, curr) =>
              prev.autoSpeakEnabled != curr.autoSpeakEnabled,
              builder: (context, state) => IconButton(
                icon: Icon(
                  state.autoSpeakEnabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white70,
                ),
                onPressed: () =>
                    context.read<ChatBloc>().add(ToggleAutoSpeakEvent()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _showOptionsMenu(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cardBg,
                    border: Border.all(color: _accent.withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.sentiment_satisfied_alt_rounded,
                      color: _accent, size: 18),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Error banner
              BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (prev, curr) => prev.error != curr.error,
                builder: (context, state) {
                  if (state.error == null) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: Colors.red[700],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(state.error!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                        onPressed: () =>
                            context.read<ChatBloc>().add(ClearErrorEvent()),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ]),
                  );
                },
              ),

              // Offline banner
              BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (prev, curr) => prev.isOffline != curr.isOffline,
                builder: (context, state) {
                  if (!state.isOffline) return const SizedBox.shrink();
                  return Container(
                    width: double.infinity,
                    color: Colors.grey[800],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Row(children: const [
                      Icon(Icons.wifi_off, color: Colors.white70, size: 14),
                      SizedBox(width: 8),
                      Text('You are offline — showing cached messages',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  );
                },
              ),

              // Messages list
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    if (state.isLoading && state.messages.isEmpty) {
                      return const Center(
                          child: CircularProgressIndicator(color: _accent));
                    }
                    if (state.messages.isEmpty) return _buildEmptyState();
                    return RefreshIndicator(
                      color: _accent,
                      backgroundColor: _cardBg,
                      onRefresh: () async => context
                          .read<ChatBloc>()
                          .add(LoadMessagesEvent(widget.conversationId)),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                        state.messages.length + (state.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length &&
                              state.isTyping) {
                            return _buildTypingIndicator();
                          }
                          return ChatBubble(message: state.messages[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Input bar
              BlocBuilder<ChatBloc, ChatState>(
                buildWhen: (prev, curr) => prev.isTyping != curr.isTyping,
                builder: (context, state) => _buildInputBar(state.isTyping),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.5),
                    blurRadius: 70,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withOpacity(0.15),
                      const Color(0xFF111113),
                    ],
                  ),
                  border: Border.all(
                      color: _accent.withOpacity(0.9), width: 2.5),
                ),
                child: const Icon(Icons.sentiment_satisfied_alt_rounded,
                    color: Colors.white, size: 62),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isTyping) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: _bgColor,
        border: const Border(
          top: BorderSide(color: Color(0xFF1F1F22), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Pill-shaped input container: mic + text field together
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 48, maxHeight: 140),
                decoration: BoxDecoration(
                  color: _inputFill,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: const Color(0xFF2E2E32),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 4),
                    _MicButton(
                      onTranscriptFinal: (text) {
                        _messageController.text = text;
                        _sendMessage();
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4, top: 4, right: 8),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 6,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            height: 1.35,
                          ),
                          cursorColor: _accent,
                          decoration: const InputDecoration(
                            hintText: 'Message SmartMind…',
                            hintStyle: TextStyle(
                              color: _hintColor,
                              fontSize: 15.5,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              isTyping: isTyping,
              isEnabled: _messageController.text.trim().isNotEmpty,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_dot(0), _dot(200), _dot(400)],
        ),
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delayMs),
      builder: (_, double value, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.4 + 0.6 * value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final bloc = context.read<ChatBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.face_rounded, color: Colors.white),
            title: const Text('Change Persona',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              _showPersonaPicker(context, bloc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete Conversation',
                style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              bloc.add(DeleteConversationEvent(widget.conversationId));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh_rounded, color: Colors.white),
            title: const Text('Reload Messages',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              bloc.add(LoadMessagesEvent(widget.conversationId));
            },
          ),
          ListTile(
            leading:
            const Icon(Icons.settings_outlined, color: Colors.white),
            title:
            const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ]),
      ),
    );
  }


  void _showPersonaPicker(BuildContext context, ChatBloc bloc) {
    final personas = {
      'assistant': 'Assistant',
      'teacher': 'Teacher',
      'coder': 'Coder',
      'friend': 'Friend',
      'analyst': 'Analyst',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: BlocBuilder<ChatBloc, ChatState>(
          bloc: bloc,
          buildWhen: (prev, curr) =>
          prev.currentPersona != curr.currentPersona,
          builder: (context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            children: personas.entries.map((entry) {
              final isSelected = state.currentPersona == entry.key;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? _accent : Colors.white,
                ),
                title: Text(entry.value,
                    style: TextStyle(
                        color: isSelected ? _accent : Colors.white,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal)),
                onTap: () {
                  bloc.add(ChangePersonaEvent(
                    conversationId: widget.conversationId,
                    persona: entry.key,
                  ));
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final ValueChanged<String> onTranscriptFinal;
  const _MicButton({required this.onTranscriptFinal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: VoiceInputWidget(
        onTranscriptFinal: onTranscriptFinal,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isTyping;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SendButton({
    required this.isTyping,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = isEnabled && !isTyping;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: canSend
            ? const LinearGradient(
          colors: [Color(0xFFFF6A2B), Color(0xFFFF8A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: canSend ? null : const Color(0xFF2A2A2D),
        boxShadow: canSend
            ? [
          BoxShadow(
            color: const Color(0xFFFF6A2B).withOpacity(0.35),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: canSend ? onPressed : null,
          child: Center(
            child: isTyping
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Icon(
              Icons.arrow_upward_rounded,
              color: canSend ? Colors.white : Colors.white30,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}