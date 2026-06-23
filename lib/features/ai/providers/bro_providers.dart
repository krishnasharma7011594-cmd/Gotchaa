import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bro_orchestrator.dart';

final broMessagesProvider = StateProvider<List<Map<String, dynamic>>>((ref) => [
  {
    'isUser': false,
    'text': 'Yo! I am BRO. Kya haal chaal? How can I help you today?',
    'time': DateTime.now(),
  }
]);

final broLoadingProvider = StateProvider<bool>((ref) => false);

final broOrchestratorProvider = Provider((ref) => BroOrchestrator());
