import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../domain/models/bro_message.dart';
import '../../domain/models/bro_response.dart';
import '../../services/bro_voice_command_handler.dart';
import '../providers/bro_providers.dart';

class BroAssistantOverlay extends ConsumerStatefulWidget {
  const BroAssistantOverlay({super.key});

  @override
  ConsumerState<BroAssistantOverlay> createState() =>
      _BroAssistantOverlayState();
}

class _BroAssistantOverlayState extends ConsumerState<BroAssistantOverlay>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _uuid = const Uuid();

  late AnimationController _animationController;
  late Animation<double> _panelAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _panelAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _closeOverlay();
    } else {
      setState(() {
        _isOpen = true;
      });
      _animationController.forward();
      HapticFeedback.mediumImpact();
    }
  }

  void _closeOverlay() {
    if (_isOpen) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isOpen = false;
          });
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || ref.read(broLoadingProvider)) return;

    final orchestrator = ref.read(broOrchestratorProvider);
    final messagesNotifier = ref.read(broMessagesProvider.notifier);

    // Add User Message
    messagesNotifier.addMessage(BroMessage(
      id: _uuid.v4(),
      role: BroRole.user,
      content: text,
      timestamp: DateTime.now(),
      type: BroMessageType.text,
    ));

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await orchestrator.processTextQuery(text);

      if (response.status == BroStatus.failed) {
        _handleError(response.error ?? 'Unknown error');
      }
      _scrollToBottom();
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String errorMsg) {
    ref.read(broMessagesProvider.notifier).addMessage(BroMessage(
          id: _uuid.v4(),
          role: BroRole.assistant,
          content: errorMsg,
          timestamp: DateTime.now(),
          type: BroMessageType.text,
        ));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Offset _offset = const Offset(20, 100);

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (authState.asData?.value == null) return const SizedBox.shrink();
    final screenSize = MediaQuery.of(context).size;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeOverlay,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(color: Colors.black.withOpacity(0.7)),
                ),
              ),
            ),
          if (_isOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_panelAnimation),
                child: _buildBroPanel(),
              ),
            ),
          if (!_isOpen)
            Positioned(
              right: _offset.dx,
              bottom: _offset.dy,
              child: Draggable(
                feedback: _buildBroBubble(isDragging: true),
                childWhenDragging: const SizedBox.shrink(),
                onDragEnd: (details) {
                  setState(() {
                    final double newBottom =
                        screenSize.height - details.offset.dy - 60;
                    final double newRight =
                        screenSize.width - details.offset.dx - 60;

                    _offset = Offset(
                      newRight.clamp(10, screenSize.width - 70),
                      newBottom.clamp(10, screenSize.height - 70),
                    );
                  });
                },
                child: ZoomIn(
                  child: _buildBroBubble(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBroBubble({bool isDragging = false}) => GestureDetector(
        onTap: isDragging ? null : _toggleOverlay,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(isDragging ? 0.8 : 0.5),
                blurRadius: isDragging ? 30 : 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isDragging) _PulseCircle(),
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
            ],
          ),
        ),
      );

  Widget _buildBroPanel() {
    final size = MediaQuery.of(context).size;
    final voiceState = ref.watch(broVoiceCommandProvider);

    return Container(
      height: size.height * 0.75,
      width: size.width,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (voiceState != BroVoiceStateV2.idle)
            Expanded(child: _buildVoiceVisualizer(voiceState))
          else
            Expanded(child: _buildChatList()),
          _buildInputArea(voiceState),
        ],
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BRO',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Gotchaa Navigator Agent',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white, size: 32),
              onPressed: _closeOverlay,
            ),
          ],
        ),
      );

  Widget _buildChatList() {
    final messages = ref.watch(broMessagesProvider);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _ChatMessage(
          text: msg.content,
          isUser: msg.role == BroRole.user,
        );
      },
    );
  }

  Widget _buildVoiceVisualizer(BroVoiceStateV2 state) {
    final liveTranscript = ref.watch(broLiveTranscriptProvider);
    String statusText = 'Listening...';
    Widget animation = const SizedBox.shrink();

    switch (state) {
      case BroVoiceStateV2.permission:
        statusText = 'Requesting Microphone Permission...';
        animation =
            const Icon(Icons.lock_rounded, color: Colors.blueAccent, size: 80);
        break;
      case BroVoiceStateV2.starting:
        statusText = 'Starting speech engine...';
        animation = const CircularProgressIndicator(color: Colors.blueAccent);
        break;
      case BroVoiceStateV2.listening:
        statusText = 'Speak now, Bro!';
        animation = _VoiceWaves(isWaveActive: false);
        break;
      case BroVoiceStateV2.transcribing:
        statusText = 'Listening...';
        animation = _VoiceWaves(isWaveActive: true);
        break;
      case BroVoiceStateV2.thinking:
        statusText = 'Thinking...';
        animation = const CircularProgressIndicator(color: Colors.cyanAccent);
        break;
      case BroVoiceStateV2.speaking:
        statusText = 'Speaking...';
        animation = _VoiceWaves(isWaveActive: true, color: Colors.greenAccent);
        break;
      case BroVoiceStateV2.error:
        statusText = 'Something went wrong';
        animation = const Icon(Icons.warning_amber_rounded,
            color: Colors.orangeAccent, size: 80);
        break;
      case BroVoiceStateV2.stopped:
        statusText = 'Stopped';
        animation =
            const Icon(Icons.mic_off_rounded, color: Colors.white24, size: 80);
        break;
      default:
        break;
    }

    return FadeIn(
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusText,
                style: GoogleFonts.outfit(
                  color: Colors.blueAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(height: 120, child: Center(child: animation)),
              const SizedBox(height: 40),
              Text(
                liveTranscript.isEmpty
                    ? 'Say: "Open Wallet" or "Launch Spotify"'
                    : '"$liveTranscript"',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 20,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BroVoiceStateV2 voiceState) {
    final isListening = voiceState == BroVoiceStateV2.listening ||
        voiceState == BroVoiceStateV2.transcribing;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 15, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: const Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ask BRO to do anything...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 15),
          _buildSendButton(isListening),
        ],
      ),
    );
  }

  Widget _buildSendButton(bool isListening) {
    final isLoading = ref.watch(broLoadingProvider);
    final voiceHandler = ref.read(broVoiceCommandProvider.notifier);

    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.heavyImpact();
        voiceHandler.startListening();
      },
      onLongPressEnd: (_) async {
        HapticFeedback.mediumImpact();
        await voiceHandler.stopListeningAndProcess();
        _scrollToBottom();
      },
      onTap: isListening ? () => voiceHandler.cancelListening() : _sendMessage,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening ? Colors.redAccent : Colors.blueAccent,
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(15),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Icon(
                isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 28,
              ),
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Container(
          width: 70 + (40 * _controller.value),
          height: 70 + (40 * _controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.withOpacity(1 - _controller.value),
              width: 2,
            ),
          ),
        ),
      );
}

class _VoiceWaves extends StatefulWidget {
  const _VoiceWaves({this.isWaveActive = true, this.color = Colors.blueAccent});
  final bool isWaveActive;
  final Color color;

  @override
  State<_VoiceWaves> createState() => _VoiceWavesState();
}

class _VoiceWavesState extends State<_VoiceWaves>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isWaveActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _VoiceWaves oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWaveActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isWaveActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.isWaveActive ? _controller.value : 0.1;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final double height =
                30 + (40 * scale * ((index - 2).abs() == 0 ? 1 : 0.6));
            return Container(
              width: 8,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ChatMessage extends StatelessWidget {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) => Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: FadeInUp(
          duration: const Duration(milliseconds: 300),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF3B82F6)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22).copyWith(
                bottomRight: isUser ? Radius.zero : null,
                bottomLeft: isUser ? null : Radius.zero,
              ),
            ),
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
}
