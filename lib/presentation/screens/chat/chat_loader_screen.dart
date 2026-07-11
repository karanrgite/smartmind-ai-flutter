import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/repositories/chat_repository.dart';
import 'chat_screen.dart';

class ChatLoaderScreen extends StatefulWidget {
  const ChatLoaderScreen({super.key});

  @override
  State<ChatLoaderScreen> createState() => _ChatLoaderScreenState();
}

class _ChatLoaderScreenState extends State<ChatLoaderScreen> {
  final ChatRepository _chatRepository = ChatRepository();
  String? _conversationId;
  String _title = 'New Chat';
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username != null && username.isNotEmpty) {
      _title = username;
    }
    await _createConversation();
  }

  Future<void> _createConversation() async {
    try {
      final conversation = await _chatRepository.createConversation(_title);
      if (!mounted) return;
      setState(() => _conversationId = conversation.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not start a new chat. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0B0D);
    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
            child:
            Text(_error!, style: const TextStyle(color: Colors.white))),
      );
    }
    if (_conversationId == null) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6A2B))),
      );
    }
    return ChatScreen(conversationId: _conversationId!, conversationTitle: _title);
  }
}