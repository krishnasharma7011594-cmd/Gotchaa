import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../core/config/app_config.dart' as secure_config;

import '../domain/models/bro_intent.dart';
import '../domain/models/bro_tool_call.dart';
import '../domain/tools/bro_tool_registry.dart';

class BroIntentClassifier {
  BroIntentClassifier(this._dio);

  final Dio _dio;

  static const String _modelName = 'gemini-1.5-flash';

  /// Classifies a query into a structured [BroToolCall] using local rules first,
  /// then Gemini on-device function calling, and finally the backend API fallback.
  Future<BroToolCall> classify(String query, BroContext context) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return const BroUnknownCall(
          reply: 'Say something, bro!', confidence: 1.0);
    }

    developer.log(
        'Classifying query: "$cleanQuery" with context: ${context.toJson()}',
        name: 'BRO.IntentClassifier');

    // ── Phase 1: Fast Rule Engine (Deterministic local bypass) ───────────────
    final localMatch = FastRuleEngine.evaluate(cleanQuery);
    if (localMatch != null) {
      developer.log('Fast Rule Engine matched successfully: $localMatch',
          name: 'BRO.IntentClassifier');
      return localMatch;
    }

    // ── Phase 2: Gemini On-Device Function Calling (If API Key Present) ──────
    const apiKey = secure_config.AppConfig.geminiApiKey;
    if (apiKey.isNotEmpty) {
      try {
        developer.log('Invoking Gemini API for classification',
            name: 'BRO.IntentClassifier');
        return await _classifyWithGemini(cleanQuery, context, apiKey);
      } catch (e) {
        developer.log(
            'Gemini classification failed: $e. Falling back to backend.',
            name: 'BRO.IntentClassifier');
      }
    } else {
      developer.log('Gemini API key is empty. Falling back to backend.',
          name: 'BRO.IntentClassifier');
    }

    // ── Phase 3: Legacy Backend API Fallback ────────────────────────────────
    try {
      developer.log('Invoking backend /bro/chat endpoint',
          name: 'BRO.IntentClassifier');
      return await _classifyWithBackend(cleanQuery);
    } on DioException catch (e) {
      // Backend is unreachable (expected in dev/staging) — give a friendly
      // conversational response rather than a dead-end error.
      developer.log(
          'Backend unavailable (${e.type.name}): responding conversationally.',
          name: 'BRO.IntentClassifier');
      return BroConversationCall(
        reply: _getOfflineReply(cleanQuery),
        confidence: 0.5,
        rawQuery: query,
      );
    } catch (e) {
      developer.log('Backend fallback failed: $e',
          name: 'BRO.IntentClassifier');
      return BroConversationCall(
        reply: _getOfflineReply(cleanQuery),
        confidence: 0.5,
        rawQuery: query,
      );
    }
  }

  /// Generates a graceful conversational reply when no AI service is reachable.
  String _getOfflineReply(String query) {
    final q = query.toLowerCase();
    if (q.contains('how') ||
        q.contains('what') ||
        q.contains('kya') ||
        q.contains('kaisa') ||
        q.contains('kaise')) {
      return "Yaar, abhi mera AI brain thoda busy hai — try karo thodi der mein! 🤖";
    }
    if (q.contains('help') || q.contains('bata') || q.contains('batao')) {
      return "Main yahan hoon bro! Abhi network slow lag raha hai, ek second mein back aaonga. Kuch screen open karni ho toh bol! 🚀";
    }
    return "Hey bro! Main sun raha hoon — bas AI engine warm up ho rahi hai. Koi screen kholni ho? Bol do! 😎";
  }

  Future<BroToolCall> _classifyWithGemini(
      String query, BroContext context, String apiKey) async {
    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are BRO, the intelligent, cool, and helpful Hinglish-speaking AI assistant of the Gotchaa social app.\n'
        'Your goal is to understand what the user wants and output the correct tool call.\n'
        'Current context of the app is:\n'
        '${jsonEncode(context.toJson())}\n\n'
        'You have access to two tools:\n'
        '1. navigate_to_screen(screen_id): Call this when the user wants to navigate/open/go to a screen. Screen IDs list:\n'
        '${ScreenRegistry.screens.map((s) => '  - "${s.id}" (Aliases: ${s.aliases.join(', ')}) : ${s.description}').join('\n')}\n\n'
        '2. open_app(app_id): Call this when the user wants to open/launch a mini app. App IDs list:\n'
        '${AppRegistry.apps.map((a) => '  - "${a.id}" (Aliases: ${a.aliases.join(', ')}) : ${a.description}').join('\n')}\n\n'
        'Rules:\n'
        '- If the user asks for a screen that is already open (see currentScreen in context), let them know they are already there in a conversational reply.\n'
        '- If the request does not match navigating or launching an app, just answer the question conversationally in your cool Hinglish style.\n'
        '- Keep responses short and friendly.',
      ),
      tools: [
        Tool(functionDeclarations: [
          FunctionDeclaration(
            'navigate_to_screen',
            'Navigates the user to a specific internal screen of Gotchaa.',
            Schema(
              SchemaType.object,
              properties: {
                'screen_id': Schema(
                  SchemaType.string,
                  description:
                      'The exact ID of the target screen from the allowed screens list.',
                ),
              },
              requiredProperties: ['screen_id'],
            ),
          ),
          FunctionDeclaration(
            'open_app',
            'Opens or launches a third-party mini app via deep linking.',
            Schema(
              SchemaType.object,
              properties: {
                'app_id': Schema(
                  SchemaType.string,
                  description:
                      'The exact ID of the app from the allowed apps list.',
                ),
              },
              requiredProperties: ['app_id'],
            ),
          ),
        ]),
      ],
    );

    final response = await model.generateContent([Content.text(query)]);
    final functionCalls = response.functionCalls.toList();

    if (functionCalls.isNotEmpty) {
      final call = functionCalls.first;
      if (call.name == 'navigate_to_screen') {
        final screenId = call.args['screen_id'] as String?;
        if (screenId != null) {
          final matched = ScreenRegistry.match(screenId);
          if (matched != null) {
            return BroNavigateCall(
                screen: matched.id, confidence: 0.95, rawQuery: query);
          }
        }
      } else if (call.name == 'open_app') {
        final appId = call.args['app_id'] as String?;
        if (appId != null) {
          final matched = AppRegistry.match(appId);
          if (matched != null) {
            return BroDeepLinkCall(
                app: matched.name,
                url: matched.deepLinkUrl,
                confidence: 0.95,
                rawQuery: query);
          }
        }
      }
    }

    final text = response.text ?? 'I got you, bro!';
    return BroConversationCall(reply: text, confidence: 0.9, rawQuery: query);
  }

  Future<BroToolCall> _classifyWithBackend(String query) async {
    final response = await _dio.post('/bro/chat', data: {'query': query});
    final responseData = response.data as Map<String, dynamic>;
    final text = responseData['text'] as String? ?? 'Done!';
    final action = responseData['action'] as String? ?? 'none';
    final data = responseData['data'] as Map<String, dynamic>?;

    if (action == 'navigation' && data != null && data['target'] != null) {
      final target = data['target'].toString();
      final matched = ScreenRegistry.match(target);
      if (matched != null) {
        return BroNavigateCall(
            screen: matched.id, confidence: 0.8, rawQuery: query);
      }
    } else if ((action == 'cab_booking' ||
            action == 'food_order' ||
            action == 'shopping') &&
        data != null) {
      final provider = data['suggested_provider']?.toString() ??
          data['restaurant']?.toString() ??
          data['store']?.toString() ??
          'uber';
      final matched = AppRegistry.match(provider);
      if (matched != null) {
        return BroDeepLinkCall(
            app: matched.name,
            url: matched.deepLinkUrl,
            confidence: 0.8,
            rawQuery: query);
      }
    }

    return BroConversationCall(reply: text, confidence: 0.8, rawQuery: query);
  }
}
