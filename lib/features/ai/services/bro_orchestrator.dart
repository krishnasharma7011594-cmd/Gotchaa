import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/config/app_config.dart';
import 'tools/bro_tool.dart';
import 'tools/cab_tool.dart';
import 'tools/food_tool.dart';

class BroOrchestrator {
  static final BroOrchestrator _instance = BroOrchestrator._internal();
  factory BroOrchestrator() => _instance;
  BroOrchestrator._internal();

  GenerativeModel? _model;
  ChatSession? _session;
  final List<BroTool> _tools = [
    CabTool(),
    FoodTool(),
    // Add more tools here
  ];

  void init() {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) return;

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      tools: _tools.map((t) => t.toGeminiTool()).toList(),
      systemInstruction: Content.system(
        'You are BRO, the Jarvis-style action assistant for the Gotchaa super-app. '
        'Your goal is to BE PROACTIVE and help users get things done with minimal taps. '
        'You speak English and Hinglish fluently. Your tone is street-smart, direct, and reliable. '
        'When a user wants to book something or buy something, use the appropriate tool. '
        'Always maintain session context. If the user mentions a past task, resume it.'
      ),
    );

    _session = _model!.startChat();
  }

  Future<BroResponse> processMessage(String message) async {
    if (_session == null) init();
    if (_session == null) return BroResponse(text: 'BRO is offline. Check API key.');

    try {
      var response = await _session!.sendMessage(Content.text(message));
      
      // Handle Tool Calls
      final functionCalls = response.functionCalls.toList();
      if (functionCalls.isNotEmpty) {
        final toolResponses = <FunctionResponse>[];
        bool biometricsRequired = false;
        BroTool? triggeredTool;
        Map<String, dynamic>? toolArgs;

        for (final call in functionCalls) {
          final tool = _tools.firstWhere((t) => t.name == call.name);
          if (tool.requiresBiometrics) {
            biometricsRequired = true;
            triggeredTool = tool;
            toolArgs = call.args;
            // For MVP, we only handle one biometric request at a time
            break; 
          }

          final result = await tool.execute(call.args);
          toolResponses.add(FunctionResponse(call.name, result));
        }

        if (biometricsRequired) {
          return BroResponse(
            text: 'I need your fingerprint/face ID to proceed with this booking.',
            requiresBiometrics: true,
            pendingTool: triggeredTool,
            pendingArgs: toolArgs,
          );
        }

        if (toolResponses.isNotEmpty) {
          // Send tool results back to model for final natural language response
          response = await _session!.sendMessage(Content.functionResponses(toolResponses));
        }
      }

      return BroResponse(text: response.text ?? 'I\'m not sure how to respond to that.');
    } catch (e) {
      return BroResponse(text: 'Phat gaya! (Error): $e');
    }
  }

  Future<BroResponse> continueWithTool(BroTool tool, Map<String, dynamic> args) async {
    final result = await tool.execute(args);
    final response = await _session!.sendMessage(Content.functionResponses([
      FunctionResponse(tool.name, result)
    ]));
    return BroResponse(text: response.text ?? 'Done!');
  }
}

class BroResponse {
  final String text;
  final bool requiresBiometrics;
  final BroTool? pendingTool;
  final Map<String, dynamic>? pendingArgs;

  BroResponse({
    required this.text,
    this.requiresBiometrics = false,
    this.pendingTool,
    this.pendingArgs,
  });
}
