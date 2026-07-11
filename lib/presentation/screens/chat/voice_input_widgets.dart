import 'package:flutter/material.dart';
import '../../../core/services/voice_service.dart';

const _accent = Color(0xFFFF6A2B);
const _listeningColor = Color(0xFFFF3B30);

class VoiceInputWidget extends StatefulWidget {
  final Function(String text) onTranscriptFinal;
  final Function(String text)? onTranscriptPartial;

  const VoiceInputWidget({
    super.key,
    required this.onTranscriptFinal,
    this.onTranscriptPartial,
  });

  @override
  State<VoiceInputWidget> createState() => _VoiceInputWidgetState();
}

class _VoiceInputWidgetState extends State<VoiceInputWidget>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;
  String _liveText = '';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isListening) _voiceService.stopListening();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
      return;
    }

    final hasPermission = await _voiceService.requestMicPermission();
    if (!hasPermission) {
      final permanentlyDenied =
      await _voiceService.checkMicPermissionPermanentlyDenied();
      if (mounted) {
        _showPermissionDialog(permanentlyDenied);
      }
      return;
    }

    final ready = await _voiceService.init();
    if (!ready) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Speech recognition not available on this device')),
        );
      }
      return;
    }

    setState(() {
      _isListening = true;
      _liveText = '';
    });

    await _voiceService.startListening(
      onResult: (text, isFinal) {
        setState(() => _liveText = text);
        widget.onTranscriptPartial?.call(text);

        if (isFinal && text.trim().isNotEmpty) {
          widget.onTranscriptFinal(text.trim());
          setState(() => _isListening = false);
        }
      },
      onListeningDone: () {
        setState(() => _isListening = false);
      },
    );
  }

  void _showPermissionDialog(bool permanentlyDenied) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1D),
        title: const Text('Microphone Access Needed',
            style: TextStyle(color: Colors.white)),
        content: Text(
          permanentlyDenied
              ? 'Please enable microphone access from app settings to use voice input.'
              : 'SmartMind needs microphone access to hear you.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (permanentlyDenied)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _voiceService.requestMicPermission();
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fixed-size tap target — never grows, so it can't overflow its parent.
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Live transcript floats ABOVE the button using negative positioning,
          // so it never affects the button's own layout size.
          if (_isListening && _liveText.isNotEmpty)
            Positioned(
              bottom: 46,
              left: -80,
              right: -80,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E2E32)),
                ),
                child: Text(
                  _liveText,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale =
              _isListening ? 1.0 + (_pulseController.value * 0.15) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening
                        ? _listeningColor.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _isListening ? _listeningColor : _accent,
                      size: 22,
                    ),
                    onPressed: _toggleListening,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}