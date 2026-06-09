import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/theme/app_colors.dart';

class FloatingGeminiOverlay extends ConsumerStatefulWidget {
  const FloatingGeminiOverlay({super.key});

  @override
  ConsumerState<FloatingGeminiOverlay> createState() => _FloatingGeminiOverlayState();
}

class _FloatingGeminiOverlayState extends ConsumerState<FloatingGeminiOverlay> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late AnimationController _animationController;
  late Animation<double> _panelAnimation;
  late Animation<double> _fadeAnimation;

  // Gemini State
  GenerativeModel? _model;
  ChatSession? _chatSession;
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _initGemini();
  }

  void _initGemini() {
    const apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      _error = 'Gemini API Key is missing. Run with --dart-define=GEMINI_API_KEY=your_key';
      return;
    }
    
    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are the Gotchaa AI Assistant. You must ONLY answer questions related to the Gotchaa app. '
        'If a user asks about anything else, politely refuse by saying: "I can only help with Gotchaa questions."'
      ),
    );
    
    _chatSession = _model!.startChat();
    
    _messages.add({
      'isUser': false,
      'text': 'Hi! I am your Gotchaa AI Assistant. Ask me anything about the app!',
      'time': DateTime.now(),
    });
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
    if (text.isEmpty || _isLoading || _chatSession == null) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      final wrappedText = 'Only answer if this is about Gotchaa. Otherwise refuse.\n\nUser message: $text';
      final response = await _chatSession!.sendMessage(Content.text(wrappedText));
      final responseText = response.text;
      
      if (responseText != null) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': responseText,
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        _handleError('Empty response from Gemini');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String errorMsg) {
    if (!mounted) return;
    setState(() {
      _messages.add({
        'isUser': false,
        'text': 'Error: $errorMsg',
        'isError': true,
        'time': DateTime.now(),
      });
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    // Hide if not logged in
    if (authState.asData?.value == null) return const SizedBox.shrink();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Darkened background when open
          if (_isOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeOverlay,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            ),

          // The Overlay Panel
          if (_isOpen)
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_panelAnimation),
                child: _buildGeminiPanel(),
              ),
            ),

          // The Floating Bubble
          Positioned(
            bottom: 110, // Moved up to avoid covering Profile button (WhatsApp Meta AI style)
            right: 20,
            child: _isOpen 
                ? const SizedBox.shrink() 
                : FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: _buildBubble(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble() => GestureDetector(
      onTap: _toggleOverlay,
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.electricBlue, Color(0xFF9D50BB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );

  Widget _buildGeminiPanel() {
    final size = MediaQuery.of(context).size;
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! > 10) {
          _closeOverlay();
        }
      },
      child: Container(
        height: size.height * 0.7,
        width: size.width,
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 50,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.electricBlue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gotchaa Assistant',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: _closeOverlay,
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),

            // Chat View
            Expanded(
              child: _error != null 
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                : _buildConversation(),
            ),

            // Input
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation() => ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['isUser'] as bool;
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? AppColors.electricBlue : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomRight: isUser ? Radius.zero : null,
                bottomLeft: isUser ? null : Radius.zero,
              ),
            ),
            child: Text(
              msg['text'] as String,
              style: GoogleFonts.outfit(
                color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                fontSize: 15,
              ),
            ),
          ),
        );
      },
    );

  Widget _buildInput() => Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ask about Gotchaa...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.electricBlue,
                shape: BoxShape.circle,
              ),
              child: _isLoading 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
}

// Extension to help with Colors in the overlay if context properties are hard to reach
extension on BuildContext {
  // Not strictly needed but helpful for consistency
}
