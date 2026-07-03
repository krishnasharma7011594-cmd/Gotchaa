import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../config/app_config.dart';
import '../../../core/providers/shell_navigation_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/audio_focus_manager.dart';
import '../domain/models/bro_message.dart';
import '../domain/models/bro_response.dart';
import '../presentation/providers/bro_providers.dart';

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
  final _localAuth = LocalAuthentication();
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
      debugPrint('BRO Listening Error: $e');
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
      final broResponse =
          BroResponse.failed('Voice processing failed: $e');
      await _handlePostProcessing(broResponse);
      return broResponse;
    } finally {
      _ref.read(broLoadingProvider.notifier).state = false;
    }
  }

  Future<BroResponse> processTextQuery(String query) async {
    final startTime = DateTime.now();
    _ref.read(broLoadingProvider.notifier).state = true;

    try {
      final response = await _dio.post('/bro/chat', data: {'query': query});
      final executionTime =
          DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      final broResponse = _parseFastApiResponse(response.data, executionTime);
      await _handlePostProcessing(broResponse);
      return broResponse;
    } catch (e) {
      final broResponse = BroResponse.failed(
        'Backend unavailable. Check your connection and try again.',
      );
      await _handlePostProcessing(broResponse);
      return broResponse;
    } finally {
      _ref.read(broLoadingProvider.notifier).state = false;
    }
  }

  // ── Post-Processing & Action Execution ────────────────────────────────────

  Future<void> _handlePostProcessing(BroResponse response) async {
    // Always log the message to the chat UI
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
      // ── Cab Booking: biometric gate before opening service ─────────────
      case BroActionType.cab_booking:
        final authenticated = await _authenticateUser();
        if (authenticated) {
          final provider =
              response.data?['suggested_provider']?.toString().toLowerCase() ??
                  'uber';
          GotchaaRouter.openServiceById(
              provider == 'rapido' ? 'rapido' : 'uber');
        }

      // ── Food Order: open service in-app ───────────────────────────────
      case BroActionType.food_order:
        final restaurant =
            response.data?['restaurant']?.toString().toLowerCase() ?? 'swiggy';
        String serviceId = 'swiggy';
        if (restaurant.contains('eatsure')) serviceId = 'eatsure';
        if (restaurant.contains('fassos')) serviceId = 'fassos';
        if (restaurant.contains('zepto')) serviceId = 'zepto';
        GotchaaRouter.openServiceById(serviceId);

      // ── Shopping: open service in-app ─────────────────────────────────
      case BroActionType.shopping:
        final store =
            response.data?['store']?.toString().toLowerCase() ?? 'amazon';
        String serviceId = 'amazon';
        if (store.contains('flipkart')) serviceId = 'flipkart';
        if (store.contains('myntra')) serviceId = 'myntra';
        if (store.contains('ajio')) serviceId = 'ajio';
        if (store.contains('nykaa')) serviceId = 'nykaa';
        GotchaaRouter.openServiceById(serviceId);

      // ── Payment: always BLOCKED by legal gate ─────────────────────────
      case BroActionType.payment:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⛔ Payments are restricted due to security regulations.',
              ),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }

      // ── Navigation: switch shell page or push route ───────────────────
      case BroActionType.navigation:
        final target = response.data?['target']?.toString();
        if (target != null && context.mounted) {
          _executeNavigation(context, target);
        }

      // ── UI Control: toggle dark/light theme ───────────────────────────
      case BroActionType.ui_control:
        final theme = response.data?['theme']?.toString();
        if (theme != null) {
          final container = ProviderScope.containerOf(context);
          if (theme == 'dark') {
            await container
                .read(themeProvider.notifier)
                .setThemeMode(ThemeMode.dark);
          } else {
            await container
                .read(themeProvider.notifier)
                .setThemeMode(ThemeMode.light);
          }
        }

      default:
        break;
    }
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
      'explore': 2,
      'mini_apps': 3,
      'vybz': 4,
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
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  Future<bool> _authenticateUser() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return true;
      return await _localAuth.authenticate(
        localizedReason: 'Verify your identity to book a ride',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
