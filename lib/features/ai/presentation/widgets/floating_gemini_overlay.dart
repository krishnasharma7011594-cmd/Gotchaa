import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/bro_message.dart';
import '../../domain/models/bro_response.dart';
import '../providers/bro_providers.dart';
import '../services/bro_orchestrator.dart';

class BroAssistantOverlay extends ConsumerStatefulWidget {
  const BroAssistantOverlay({super.key});

  @override
  ConsumerState<BroAssistantOverlay> createState() => _BroAssistantOverlayState();
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
      // Process through Orchestrator (handles FastAPI + Fallbacks + Biometrics)
      final response = await orchestrator.processTextQuery(text);
      
      if (response.status == BroStatus.failed) {
        _handleError(response.error ?? "Unknown error");
      }
      // Note: Response history is automatically updated by the Orchestrator
      _scrollToBottom();
      
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String errorMsg) {
    ref.read(broMessagesProvider.notifier).addMessage(BroMessage(
      id: _uuid.v4(),
      role: BroRole.assistant,
      content: 'Bhai, check set-up: $errorMsg',
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

  Offset _offset = const Offset(20, 100); // Bottom-right initial pos

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
                    // Calculate relative to bottom-right as before or just keep absolute
                    // Let's use simple absolute from bottom/right for consistency
                    double newBottom = screenSize.height - details.offset.dy - 60;
                    double newRight = screenSize.width - details.offset.dx - 60;
                    
                    // Clamp to screen bounds
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
          width: 60, // Smaller size
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
          Expanded(child: _buildChatList()),
          _buildInputArea(),
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
                  'Jarvis powered Action Agent',
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
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
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

  Widget _buildInputArea() {
    final orchestrator = ref.read(broOrchestratorProvider);
    return Container(
      padding: EdgeInsets.fromLTRB(20, 15, 20, MediaQuery.of(context).padding.bottom + 20),
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
          _buildSendButton(orchestrator),
        ],
      ),
    );
  }

  Widget _buildSendButton(BroOrchestrator orchestrator) {
    final isLoading = ref.watch(broLoadingProvider);
    return GestureDetector(
      onLongPressStart: (_) {
         HapticFeedback.heavyImpact();
         orchestrator.startListening();
      },
      onLongPressEnd: (_) async {
         HapticFeedback.mediumImpact();
         await orchestrator.stopListeningAndProcess();
         _scrollToBottom();
      },
      onTap: _sendMessage,
      child: Container(
        width: 55,
        height: 55,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent,
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(15),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.mic_none_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _PulseCircle extends StatefulWidget {
  @override
  State<_PulseCircle> createState() => _PulseCircleState();
}

class _PulseCircleState extends State<_PulseCircle> with SingleTickerProviderStateMixin {
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 70 + (40 * _controller.value),
          height: 70 + (40 * _controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.withOpacity(1 - _controller.value),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: FadeInUp(
        duration: const Duration(milliseconds: 300),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.08),
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
}
