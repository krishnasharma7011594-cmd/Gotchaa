import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../config/app_config.dart';
import '../../../core/providers/shell_navigation_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/audio_focus_manager.dart';
import '../domain/models/bro_intent.dart';
import '../domain/models/bro_message.dart';
import '../domain/models/bro_response.dart';
import '../domain/models/bro_tool_call.dart';
import '../domain/tools/bro_tool_registry.dart';
import '../presentation/providers/bro_providers.dart';
import 'bro_intent_classifier.dart';

class BroOrchestrator {
  BroOrchestrator(this._ref) {
    _setupAudioPlayerListeners();
  }

  final Ref _ref;
  final String _baseUrl = AppConfig.instance.backendUrl;

  late final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _uuid = const Uuid();

  void _setupAudioPlayerListeners() {
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed || state == ProcessingState.idle) {
        _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_output');
      }
    });
  }

  // ── Voice Lifecycle ────────────────────────────────────────────────────────

  Future<void> startListening() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _ref
            .read(audioFocusManagerProvider)
            .requestAudioFocus('bro_input', AudioRequester.broInput);

        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/bro_input_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
      }
    } catch (e) {
      developer.log('BRO Listening Error: $e', name: 'BRO.Orchestrator');
      await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');
    }
  }

  Future<BroResponse> stopListeningAndProcess() async {
    try {
      final path = await _audioRecorder.stop();
      await _ref.read(audioFocusManagerProvider).releaseAudioFocus('bro_input');

      if (path == null) return BroResponse.failed('No audio detected');
      return await _processVoiceInput(File(path));
    } catch (e) {
      return BroResponse.failed('Failed to stop recording: $e');
    }
  }

  // ── Processing ─────────────────────────────────────────────────────────────

  Future<BroResponse> _processVoiceInput(File audioFile) async {
    final startTime = DateTime.now();
    _ref.read(broLoadingProvider.notifier).state = true;

    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'input.m4a',
        ),
      });

      final response = await _dio.post('/bro/voice-chat', data: formData);
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final broResponse = _parseFastApiResponse(response.data, executionTime);

      if (broResponse.data != null && broResponse.data!['audio_url'] != null) {
        await _ref
            .read(audioFocusManagerProvider)
            .requestAudioFocus('bro_output', AudioRequester.broOutput);
        await _audioPlayer.setUrl(broResponse.data!['audio_url'] as String);
        _audioPlayer.play();
      }

      await _handlePostProcessing(broResponse);
      return broResponse;
    } catch (e) {
      final broResponse = BroResponse.failed('Voice processing failed: $e');
      await _handlePostProcessing(broResponse);
      return broResponse;
    } finally {
      _ref.read(broLoadingProvider.notifier).state = false;
    }
  }

  /// The main text query processing entry point refactored to use [BroIntentClassifier].
  Future<BroResponse> processTextQuery(String query) async {
    final startTime = DateTime.now();
    _ref.read(broLoadingProvider.notifier).state = true;

    try {
      // 1. Build current BroContext dynamically from Riverpod providers
      final pageIndex = _ref.read(shellPageIndexProvider);
      final currentScreen = pageIndex == 0
          ? 'camera'
          : pageIndex == 1
              ? 'chat'
              : pageIndex == 2
                  ? 'home'
                  : pageIndex == 3
                      ? 'mini_apps'
                      : pageIndex == 4
                          ? 'reels'
                          : pageIndex == 5
                              ? 'profile'
                              : 'home';

      final themeState = _ref.read(themeProvider);
      final isDark = themeState.themeMode == ThemeMode.dark;
      final settings = _ref.read(broSettingsProvider);

      final context = BroContext(
        currentScreen: currentScreen,
        isInMiniApp: false,
        isMicActive: false,
        isRecording: false,
        language: settings.language,
        theme: isDark ? 'dark' : 'light',
      );

      // 2. Classify the user query using local-first rules & Gemini function calling
      final classifier = BroIntentClassifier(_dio);
      final toolCall = await classifier.classify(query, context);

      developer.log('Routing tool call: ${jsonEncode(toolCall.toJson())}',
          name: 'BRO.Orchestrator');

      // 3. Execute the tool call and capture response
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;

      final broResponse = await _executeToolCall(toolCall, executionTime);
      return broResponse;
    } catch (e) {
      developer.log('Query routing error: $e', name: 'BRO.Orchestrator');
      return BroResponse.failed('Query routing failed: $e');
    } finally {
      _ref.read(broLoadingProvider.notifier).state = false;
    }
  }

  // ── Tool Routing & Execution ──────────────────────────────────────────────

  Future<BroResponse> _executeToolCall(
      BroToolCall toolCall, double executionTime) async {
    final context = rootNavigatorKey.currentContext;
    String verbalResponse = 'Action completed!';

    switch (toolCall) {
      case BroNavigateCall(:final screen):
        verbalResponse = 'Opening $screen screen, bro!';
        if (context != null && context.mounted) {
          NavigationHistory.record(screen);
          _executeNavigation(context, screen);
        }
        break;

      case BroDeepLinkCall(:final app, :final url):
        verbalResponse = 'Launching $app for you!';
        if (context != null && context.mounted) {
          final uri = Uri.parse(url);
          final messenger = ScaffoldMessenger.of(context);
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              verbalResponse =
                  'Bro, $app is not installed. Let me know if you want to try something else!';
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Could not open deep link: $url'),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
          } catch (e) {
            verbalResponse = 'Sorry, launching $app failed.';
            messenger.showSnackBar(
              SnackBar(
                content: Text('Deep link error: $e'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
        break;

      case BroConversationCall(:final reply):
        verbalResponse = reply;
        break;

      case BroUnknownCall(:final reply):
        verbalResponse = reply;
        break;
    }

    // Always log the message to the chat UI
    final msg = BroMessage(
      id: _uuid.v4(),
      role: BroRole.assistant,
      content: verbalResponse,
      timestamp: DateTime.now(),
      type: BroMessageType.text,
    );
    _ref.read(broMessagesProvider.notifier).addMessage(msg);

    // Map new tool call results to the legacy BroResponse format to preserve UI compatibility
    return BroResponse(
      actionType: toolCall is BroNavigateCall
          ? BroActionType.navigation
          : toolCall is BroDeepLinkCall
              ? BroActionType
                  .none // UI handles deep links locally in orchestrator now
              : BroActionType.none,
      status: BroStatus.success,
      text: verbalResponse,
      executionTime: executionTime,
      data: toolCall.toJson(),
    );
  }

  void _executeNavigation(BuildContext context, String target) {
    // Named route push for legal/settings pages
    if (target == 'privacy') {
      context.push('/privacy');
      return;
    }
    if (target == 'terms') {
      context.push('/terms');
      return;
    }

    // Shell page index mapping
    final pageMap = {
      'camera': 0,
      'chat': 1,
      'home': 2,
      'mini_apps': 3,
      'reels': 4,
      'profile': 5,
    };

    final targetIndex = pageMap[target];
    if (targetIndex != null) {
      final container = ProviderScope.containerOf(context);
      final controller = container.read(shellPageControllerProvider);
      if (controller.hasClients) {
        controller.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        container.read(shellPageIndexProvider.notifier).state = targetIndex;
      }
    } else {
      // Screen target exists in metadata registry but not directly bound to GoRouter or App Shell
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Navigating to $target...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Legacy Compatibility Parsers ──────────────────────────────────────────

  Future<void> _handlePostProcessing(BroResponse response) async {
    final msg = BroMessage(
      id: _uuid.v4(),
      role: BroRole.assistant,
      content: response.text,
      timestamp: DateTime.now(),
      type: BroMessageType.text,
    );
    _ref.read(broMessagesProvider.notifier).addMessage(msg);

    if (response.status == BroStatus.failed) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    switch (response.actionType) {
      case BroActionType.navigation:
        final target = response.data?['target']?.toString();
        if (target != null && context.mounted) {
          _executeNavigation(context, target);
        }
        break;
      default:
        break;
    }
  }

  BroResponse _parseFastApiResponse(
      dynamic responseData, double executionTime) {
    final actionStr = responseData['action'] as String? ?? 'none';
    final actionType = BroActionType.values.firstWhere(
      (e) => e.name == actionStr,
      orElse: () => BroActionType.none,
    );

    return BroResponse(
      actionType: actionType,
      status: responseData['status'] == 'success'
          ? BroStatus.success
          : BroStatus.failed,
      text: responseData['text'] as String? ?? 'Done!',
      data: responseData['data'] as Map<String, dynamic>?,
      executionTime: executionTime,
      error: responseData['error'] as String?,
    );
  }

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
