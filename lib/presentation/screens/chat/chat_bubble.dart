import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../data/models/message_model.dart';

const _bubbleColor = Color(0xFF1A1A1D);
const _accent = Color(0xFFFF6A2B);

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: message.content));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Message copied'),
              duration: Duration(seconds: 1)),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(
            bottom: 14, left: isUser ? 40 : 0, right: isUser ? 0 : 40),
        child: Row(
          mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              _avatar(icon: Icons.smart_toy_rounded),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                    isUser ? const Radius.circular(18) : const Radius.circular(4),
                    bottomRight:
                    isUser ? const Radius.circular(4) : const Radius.circular(18),
                  ),
                ),
                child: MarkdownBody(
                  data: message.content.isEmpty
                      ? '⚠️ (empty response)'
                      : message.content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    code: const TextStyle(
                      backgroundColor: Colors.black45,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              _avatar(icon: Icons.person_rounded),
            ],
          ],
        ),
      ),
    );
  }

  Widget _avatar({required IconData icon}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF2A2A2D),
        border: Border.all(color: _accent.withOpacity(0.5)),
      ),
      child: Icon(icon, size: 16, color: _accent),
    );
  }
}