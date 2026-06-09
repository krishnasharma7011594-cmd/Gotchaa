import 'package:flutter/material.dart';

enum MiniAppCategory { all, games, utility, social }

class MiniApp {
  const MiniApp({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.icon,
    required this.category,
    required this.accentColor,
    this.features = const [],
  });
  final String id;
  final String name;
  final String tagline;
  final String description;
  final IconData icon;
  final MiniAppCategory category;
  final Color accentColor;
  final List<String> features;

  String get categoryLabel {
    switch (category) {
      case MiniAppCategory.games:
        return 'Games';
      case MiniAppCategory.utility:
        return 'Utility';
      case MiniAppCategory.social:
        return 'Social';
      case MiniAppCategory.all:
        return 'All';
    }
  }
}

/// The curated ecosystem of Gotchaa mini-apps.
const List<MiniApp> gotchaMiniApps = [
  MiniApp(
    id: 'cabgo',
    name: 'CabGo',
    tagline: 'Ride anywhere, anytime',
    description: 'Book rides seamlessly inside Gotchaa. Earn Karma for every'
        ' trip and tip your driver directly through the app.',
    icon: Icons.local_taxi_rounded,
    category: MiniAppCategory.utility,
    accentColor: Color(0xFFFFA726),
    features: [
      'Real-time ride tracking',
      'Tip drivers with Gotchaa',
      'Earn 5 Karma per ride',
    ],
  ),
  MiniApp(
    id: 'paywave',
    name: 'PayWave',
    tagline: 'Instant UPI payments',
    description: 'Send and receive payments in a flash. Integrated with your'
        ' Gotchaa for a seamless experience.',
    icon: Icons.contactless_rounded,
    category: MiniAppCategory.utility,
    accentColor: Color(0xFF66BB6A),
    features: [
      'Scan & pay in under a second',
      'Split bills with Hommies',
      'Karma cashback on every payment',
    ],
  ),
  MiniApp(
    id: 'quizbattle',
    name: 'QuizBattle',
    tagline: 'Challenge your Hommies',
    description: 'Go head-to-head in real-time trivia. Win Karma, climb'
        ' leaderboards, and flaunt your brainpower.',
    icon: Icons.quiz_rounded,
    category: MiniAppCategory.games,
    accentColor: Color(0xFFAB47BC),
    features: [
      'Live 1v1 quiz duels',
      'Daily Karma jackpot',
      'Global leaderboard',
    ],
  ),
  MiniApp(
    id: 'pollarena',
    name: 'PollArena',
    tagline: 'Create & vote on polls',
    description: 'Gauge the vibe — create polls on anything, share them'
        ' with friends, and watch the results roll in live.',
    icon: Icons.poll_rounded,
    category: MiniAppCategory.social,
    accentColor: Color(0xFF42A5F5),
    features: [
      'Animated live results',
      'Share polls to chat',
      'Earn Karma for participation',
    ],
  ),
  MiniApp(
    id: 'quickmap',
    name: 'QuickMap',
    tagline: 'Find places, fast',
    description: 'Lightweight maps built into Gotchaa. Find restaurants,'
        ' events, and friends nearby in one tap.',
    icon: Icons.map_rounded,
    category: MiniAppCategory.utility,
    accentColor: Color(0xFF26A69A),
    features: [
      'Discover nearby hotspots',
      'Share live location with Hommies',
      'Directions without leaving the app',
    ],
  ),
  MiniApp(
    id: 'taskmate',
    name: 'TaskMate',
    tagline: 'Shared to-dos with friends',
    description: 'Plan events, trips, and projects with your crew. Assign'
        ' tasks, set reminders, and earn Karma for completing them.',
    icon: Icons.task_alt_rounded,
    category: MiniAppCategory.social,
    accentColor: Color(0xFFEF5350),
    features: [
      'Collaborative task boards',
      'Push reminders',
      'Karma rewards for completions',
    ],
  ),
];
