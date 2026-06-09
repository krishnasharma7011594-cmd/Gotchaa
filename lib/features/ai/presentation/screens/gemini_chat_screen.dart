import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class GeminiChatScreen extends ConsumerStatefulWidget {
  const GeminiChatScreen({super.key});

  @override
  ConsumerState<GeminiChatScreen> createState() => _GeminiChatScreenState();
}

class _GeminiChatScreenState extends ConsumerState<GeminiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  void _initGemini() {
    const apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      setState(() => _error =
          'Gemini API Key missing. Build with --dart-define=GEMINI_API_KEY=your_key');
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are the Gotchaa AI Assistant. You must ONLY answer questions related to the Gotchaa app. '
        'If a user asks about anything else, politely refuse by saying: "I can only help with Gotchaa questions."',
      ),
    );

    _chatSession = _model.startChat();

    _messages.add({
      'isUser': false,
      'text':
          'Hi there! I am your Gotchaa AI Assistant. How can I help you today?',
      'time': DateTime.now(),
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final textLower = text.toLowerCase();
      if (textLower.contains('open swiggy') ||
          textLower.contains('i want food')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Food Services for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        GotchaaRouter.openService(ServiceType.food);
        return;
      }
      if (textLower.contains('open blinkit') ||
          textLower.contains('groceries')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Grocery Services for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        GotchaaRouter.openService(ServiceType.grocery);
        return;
      }
      if (textLower.contains('book a ride') ||
          textLower.contains('i need a cab') ||
          textLower.contains('open uber') ||
          textLower.contains('open rapido') ||
          textLower.contains('rapido') ||
          textLower.contains('bike taxi')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Transport Services for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();

        if (textLower.contains('rapido')) {
          GotchaaRouter.openServiceById('rapido');
        } else {
          GotchaaRouter.openService(ServiceType.transport);
        }
        return;
      }

      // New Intents
      if (textLower.contains('i want wraps') || textLower.contains('fassos')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Fassos for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        GotchaaRouter.openServiceById('fassos');
        return;
      }
      if (textLower.contains('i need a doctor') ||
          textLower.contains('practo')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Practo for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        GotchaaRouter.openServiceById('practo');
        return;
      }
      if (textLower.contains('book a stay') ||
          textLower.contains('oyo') ||
          textLower.contains('airbnb')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Accommodation Services for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        // Open OYO by default as a representative, or we could open the Hotels category
        GotchaaRouter.openService(ServiceType.hotels);
        return;
      }
      if (textLower.contains('zepto')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Zepto for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        GotchaaRouter.openServiceById('zepto');
        return;
      }
      if (textLower.contains('flipkart')) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': 'Opening Flipkart for you!',
            'time': DateTime.now(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
        GotchaaRouter.openServiceById('flipkart');
        return;
      }

      final wrappedText =
          'Only answer if this is about Gotchaa. Otherwise refuse.\n\nUser message: $text';
      final response =
          await _chatSession.sendMessage(Content.text(wrappedText));
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
    final themeState = ref.watch(themeProvider);
    final customTheme = AppTheme.fromGotchaaTheme(themeState.currentTheme);

    return Theme(
      data: customTheme,
      child: Builder(builder: (chatContext) {
        if (_error != null) {
          return Scaffold(
            backgroundColor: chatContext.bg,
            appBar: AppBar(
              backgroundColor: chatContext.bg,
              title: Text('Gotchaa Assistant',
                  style: GoogleFonts.outfit(
                      color: chatContext.textPrimary,
                      fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: chatContext.bg,
          appBar: AppBar(
            backgroundColor: chatContext.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: chatContext.iconPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.electricBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gotchaa Assistant',
                  style: GoogleFonts.outfit(
                    color: chatContext.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['isUser'] as bool;
                    final text = message['text'] as String;
                    final isError = message['isError'] == true;

                    return _buildMessageBubble(
                        chatContext, isUser, text, isError);
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.electricBlue),
                      ),
                      const SizedBox(width: 8),
                      Text('Assistant is thinking...',
                          style: GoogleFonts.outfit(
                              color: chatContext.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              _buildMessageInput(chatContext),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, bool isUser, String text, bool isError) {
    final themeState = ref.read(themeProvider);
    final radius = themeState.messageCornerRadius;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.electricBlue
              : isError
                  ? Colors.red.withValues(alpha: 0.1)
                  : context.inputFill,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: isUser ? Radius.circular(radius) : Radius.zero,
            bottomRight: isUser ? Radius.zero : Radius.circular(radius),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            color: isUser
                ? Colors.white
                : isError
                    ? Colors.red
                    : context.textPrimary,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.bg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.inputFill,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: context.textPrimary),
                    maxLines: 5,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Message Assistant...',
                      hintStyle: TextStyle(color: context.textHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isLoading ? null : _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.electricBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
}
