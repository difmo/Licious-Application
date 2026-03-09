import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class VoiceSearchDialog extends StatefulWidget {
  const VoiceSearchDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const VoiceSearchDialog(),
    );
  }

  @override
  State<VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends State<VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "Initializing...";
  Timer? _stopListeningTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          setState(() => _isListening = false);
          _pulseController.stop();
          // Auto close when done
          if (_recognizedText.isNotEmpty &&
              _recognizedText != "Listening..." &&
              _recognizedText != "Couldn't hear anything.") {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) Navigator.pop(context, _recognizedText);
            });
          }
        }
      },
      onError: (val) {
        setState(() {
          _isListening = false;
          _recognizedText = "Couldn't hear anything.";
          _pulseController.stop();
        });
      },
    );

    if (available) {
      _startListening();
    } else {
      setState(() {
        _isListening = false;
        _recognizedText = "Speech recognition denied.";
      });
    }
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _recognizedText = "Listening...";
      _pulseController.repeat(reverse: true);
    });

    _speech.listen(
      onResult: (val) {
        setState(() {
          _recognizedText = val.recognizedWords;
        });

        // Reset a timer to automatically stop if user stops talking
        _stopListeningTimer?.cancel();
        _stopListeningTimer = Timer(const Duration(seconds: 2), () {
          _speech.stop();
        });
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
    _pulseController.stop();
  }

  @override
  void dispose() {
    _stopListeningTimer?.cancel();
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.only(top: 30, bottom: 50, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 28),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _recognizedText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color:
                  _isListening ? Colors.grey.shade600 : const Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ).animate(target: _isListening ? 0 : 1).fadeIn(duration: 300.ms),
          const SizedBox(height: 60),
          // Pulsing Mic Button container
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple
                  Container(
                    width: 120 + (_pulseController.value * 50),
                    height: 120 + (_pulseController.value * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE54141).withValues(
                          alpha: 0.1 * (1.0 - _pulseController.value)),
                    ),
                  ),
                  // Inner ripple
                  Container(
                    width: 90 + (_pulseController.value * 30),
                    height: 90 + (_pulseController.value * 30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE54141).withValues(
                          alpha: 0.15 * (1.0 - _pulseController.value)),
                    ),
                  ),
                  // Center Mic button
                  GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFFE54141)
                            : Colors.grey.shade300,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE54141)
                                .withValues(alpha: _isListening ? 0.4 : 0.0),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 60),
          Text(
            _isListening ? 'English (India)' : 'Tap microphone to try again',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          )
        ],
      ),
    );
  }
}
