import 'dart:developer' as developer;
import '../models/bro_tool_call.dart';

/// Metadata for internal screens supported by the Navigation Tool
class ScreenMetadata {
  const ScreenMetadata({
    required this.id,
    required this.name,
    required this.aliases,
    required this.description,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final String description;
}

/// Metadata for Mini Apps supported by the Deep Link Tool
class AppMetadata {
  const AppMetadata({
    required this.id,
    required this.name,
    required this.aliases,
    required this.deepLinkUrl,
    required this.description,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final String deepLinkUrl;
  final String description;
}

/// Screen Registry for all 17 screens supported in Gotchaa
class ScreenRegistry {
  ScreenRegistry._();

  static final List<ScreenMetadata> screens = [
    const ScreenMetadata(
        id: 'home',
        name: 'Home',
        aliases: ['feed', 'main', 'home page'],
        description: 'The main explorer feed screen'),
    const ScreenMetadata(
        id: 'chat',
        name: 'Chat',
        aliases: ['messages', 'inbox', 'dms', 'chats'],
        description: 'Gotchaa direct messages and conversations'),
    const ScreenMetadata(
        id: 'profile',
        name: 'Profile',
        aliases: ['my profile', 'me', 'account'],
        description: 'User profile and stats'),
    const ScreenMetadata(
        id: 'search',
        name: 'Search',
        aliases: ['find', 'explore search', 'lookup'],
        description: 'Global search screen'),
    const ScreenMetadata(
        id: 'wallet',
        name: 'Wallet',
        aliases: ['money', 'balance', 'my wallet', 'tokens'],
        description: 'User wallet and transaction history'),
    const ScreenMetadata(
        id: 'notifications',
        name: 'Notifications',
        aliases: ['alerts', 'notifications hub', 'activity'],
        description: 'Recent likes, replies, and notifications'),
    const ScreenMetadata(
        id: 'settings',
        name: 'Settings',
        aliases: ['preferences', 'app settings', 'config'],
        description: 'App and privacy configuration settings'),
    const ScreenMetadata(
        id: 'camera',
        name: 'Camera',
        aliases: ['ar camera', 'lens', 'filters'],
        description: 'AR Camera and filter creator stream'),
    const ScreenMetadata(
        id: 'stories',
        name: 'Stories',
        aliases: ['my stories', 'moments'],
        description: 'Active stories of friends'),
    const ScreenMetadata(
        id: 'reels',
        name: 'Reels',
        aliases: ['shorts', 'clips'],
        description: 'Short-form looping video feed'),
    const ScreenMetadata(
        id: 'upload',
        name: 'Upload',
        aliases: ['post upload', 'create post', 'publish'],
        description: 'Create and publish a new post or story'),
    const ScreenMetadata(
        id: 'friends',
        name: 'Friends',
        aliases: ['following', 'followers', 'connections'],
        description: 'Friends and following list'),
    const ScreenMetadata(
        id: 'calls',
        name: 'Calls',
        aliases: ['audio calls', 'video calls', 'history'],
        description: 'Voice and video call history'),
    const ScreenMetadata(
        id: 'ai_assistant',
        name: 'AI Assistant',
        aliases: ['bro', 'chat with bro', 'gemini'],
        description: 'BRO assistant chat panel'),
    const ScreenMetadata(
        id: 'saved',
        name: 'Saved Posts',
        aliases: ['bookmarks', 'saved items', 'favorites'],
        description: 'Saved posts and bookmarked reels'),
    const ScreenMetadata(
        id: 'marketplace',
        name: 'Marketplace',
        aliases: ['shop', 'store', 'buy'],
        description: 'Gotchaa marketplace catalog'),
    const ScreenMetadata(
        id: 'mini_apps',
        name: 'Mini Apps Hub',
        aliases: ['apps', 'hub', 'services'],
        description: 'Vibrant local Mini Apps hub'),
  ];

  static ScreenMetadata? match(String target) {
    final clean = target.trim().toLowerCase();
    for (final s in screens) {
      if (s.id == clean ||
          s.name.toLowerCase() == clean ||
          s.aliases.any((a) => a.toLowerCase() == clean)) {
        return s;
      }
    }
    return null;
  }
}

/// App Registry for deep-linked Mini Apps
class AppRegistry {
  AppRegistry._();

  static final List<AppMetadata> apps = [
    const AppMetadata(
        id: 'uber',
        name: 'Uber',
        aliases: ['taxi', 'cab', 'ride'],
        deepLinkUrl: 'uber://',
        description: 'Uber ride hailing'),
    const AppMetadata(
        id: 'ola',
        name: 'Ola',
        aliases: ['ola cabs', 'ola taxi'],
        deepLinkUrl: 'olacabs://',
        description: 'Ola ride hailing'),
    const AppMetadata(
        id: 'google_maps',
        name: 'Google Maps',
        aliases: ['maps', 'navigation', 'gmaps'],
        deepLinkUrl: 'comgooglemaps://',
        description: 'Google Maps navigation'),
    const AppMetadata(
        id: 'spotify',
        name: 'Spotify',
        aliases: ['music', 'songs', 'spotify app'],
        deepLinkUrl: 'spotify://',
        description: 'Spotify music player'),
    const AppMetadata(
        id: 'phonepe',
        name: 'PhonePe',
        aliases: ['pe', 'phone pay'],
        deepLinkUrl: 'phonepe://',
        description: 'PhonePe payment UPI'),
    const AppMetadata(
        id: 'paytm',
        name: 'Paytm',
        aliases: ['paytm wallet'],
        deepLinkUrl: 'paytm://',
        description: 'Paytm UPI and payments'),
    const AppMetadata(
        id: 'whatsapp',
        name: 'WhatsApp',
        aliases: ['wa', 'chat app'],
        deepLinkUrl: 'whatsapp://',
        description: 'WhatsApp messenger'),
    const AppMetadata(
        id: 'blinkit',
        name: 'Blinkit',
        aliases: ['groceries', 'quick commerce', 'grofers'],
        deepLinkUrl: 'blinkit://',
        description: 'Blinkit delivery'),
    const AppMetadata(
        id: 'swiggy',
        name: 'Swiggy',
        aliases: ['food delivery', 'swigy'],
        deepLinkUrl: 'swiggy://',
        description: 'Swiggy food ordering'),
    const AppMetadata(
        id: 'zomato',
        name: 'Zomato',
        aliases: ['restaurant order', 'food'],
        deepLinkUrl: 'zomato://',
        description: 'Zomato food ordering'),
    const AppMetadata(
        id: 'amazon',
        name: 'Amazon',
        aliases: ['shopping', 'retail'],
        deepLinkUrl: 'amazon://',
        description: 'Amazon shopping'),
    const AppMetadata(
        id: 'myntra',
        name: 'Myntra',
        aliases: ['clothing', 'fashion'],
        deepLinkUrl: 'myntra://',
        description: 'Myntra fashion store'),
  ];

  static AppMetadata? match(String target) {
    final clean = target.trim().toLowerCase();
    for (final a in apps) {
      if (a.id == clean ||
          a.name.toLowerCase() == clean ||
          a.aliases.any((alias) => alias.toLowerCase() == clean)) {
        return a;
      }
    }
    return null;
  }
}

/// Navigation History Tracker (Pure Dart)
class NavigationHistory {
  NavigationHistory._();

  static final List<String> _history = [];

  static void record(String screen) {
    _history.add(screen);
    if (_history.length > 50) {
      _history.removeAt(0);
    }
    developer.log(
        'Navigation event recorded: "$screen". Current History: $_history',
        name: 'BRO.NavigationHistory');
  }

  static List<String> get history => List.unmodifiable(_history);
}

/// Fast Deterministic Rule Engine for local intent mapping.
/// Handles commands like "Open Wallet", "Go to Chat", "Launch Uber" instantly.
class FastRuleEngine {
  FastRuleEngine._();

  static final RegExp _commandPrefixes = RegExp(
    r'^(?:open|go\s+to|navigate\s+to|launch|start|take\s+me\s+to|run|show\s+me|show|view)\s+(.+)$',
    caseSensitive: false,
  );

  /// Evaluates query deterministically. Returns [BroToolCall] if matched, otherwise null.
  static BroToolCall? evaluate(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return null;

    // Direct registry checks first (e.g. user just said "wallet" or "uber")
    final directScreen = ScreenRegistry.match(cleanQuery);
    if (directScreen != null) {
      developer.log(
          'RuleEngine match: Direct screen found "${directScreen.id}"',
          name: 'BRO.RuleEngine');
      return BroNavigateCall(
          screen: directScreen.id, confidence: 1.0, rawQuery: query);
    }

    final directApp = AppRegistry.match(cleanQuery);
    if (directApp != null) {
      developer.log('RuleEngine match: Direct app found "${directApp.id}"',
          name: 'BRO.RuleEngine');
      return BroDeepLinkCall(
          app: directApp.name,
          url: directApp.deepLinkUrl,
          confidence: 1.0,
          rawQuery: query);
    }

    // Prefix-based matches (e.g. "open my wallet" or "go to chat")
    final match = _commandPrefixes.firstMatch(cleanQuery);
    if (match != null) {
      final target = match.group(1)?.trim();
      if (target != null && target.isNotEmpty) {
        // Strip common filler words like "my", "our", "the"
        final cleanTarget =
            target.replaceAll(RegExp(r'\b(my|our|the|app)\b'), '').trim();

        // 1. Try matching screens
        final screenMatch = ScreenRegistry.match(cleanTarget);
        if (screenMatch != null) {
          developer.log(
              'RuleEngine match: Prefix matched screen "${screenMatch.id}" from target "$target"',
              name: 'BRO.RuleEngine');
          return BroNavigateCall(
              screen: screenMatch.id, confidence: 1.0, rawQuery: query);
        }

        // 2. Try matching apps
        final appMatch = AppRegistry.match(cleanTarget);
        if (appMatch != null) {
          developer.log(
              'RuleEngine match: Prefix matched app "${appMatch.id}" from target "$target"',
              name: 'BRO.RuleEngine');
          return BroDeepLinkCall(
              app: appMatch.name,
              url: appMatch.deepLinkUrl,
              confidence: 1.0,
              rawQuery: query);
        }
      }
    }

    return null;
  }
}

/// Extensible tool pattern for future-proofing.
abstract class BroTool {
  String get name;
  String get description;
  BroToolCall execute(Map<String, dynamic> args);
}

class BroToolRegistry {
  final Map<String, BroTool> _tools = {};

  void register(BroTool tool) {
    _tools[tool.name] = tool;
    developer.log('Registered tool: "${tool.name}"', name: 'BRO.ToolRegistry');
  }

  BroTool? find(String name) => _tools[name];
  List<BroTool> get all => _tools.values.toList();
}
