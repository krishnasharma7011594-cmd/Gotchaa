import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';
import 'blocked_words.dart';

enum FilterSeverity { low, medium, high }

enum FilterContext { username, bio, post, message, comment }

class BlockedTerm {
  const BlockedTerm(
    this.word,
    this.severity, {
    this.allowedContexts,
  });

  final String word;
  final FilterSeverity severity;
  final Set<FilterContext>? allowedContexts;
}

class ProfanityMatch {
  ProfanityMatch({
    required this.term,
    required this.severity,
    required this.matchedText,
  });

  final String term;
  final FilterSeverity severity;
  final String matchedText;
}

class ProfanityFilter {
  static final ProfanityFilter _instance = ProfanityFilter._internal();
  factory ProfanityFilter() => _instance;

  final List<BlockedTerm> _terms = [];

  ProfanityFilter._internal() {
    for (final line in BlockedWords.baselineLines) {
      _parseLine(line);
    }
  }

  Future<void> initialize() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await remoteConfig.setDefaults({'blocked_words_list': ''});
      await remoteConfig.fetchAndActivate();
      _parseRemote(remoteConfig.getString('blocked_words_list'));
    } catch (e) {
      AppLogger.e('ProfanityFilter remote config load failed', e);
    }
  }

  void _parseLine(String line) {
    final parts = line.trim().split('|');
    if (parts.isEmpty || parts[0].isEmpty) return;
    final word = parts[0].trim().toLowerCase();
    final severity = _parseSeverity(parts.length > 1 ? parts[1] : 'medium');
    Set<FilterContext>? contexts;
    if (parts.length > 2) {
      contexts = parts[2]
          .split(',')
          .map((c) => _parseContext(c.trim()))
          .whereType<FilterContext>()
          .toSet();
    }
    _terms.add(BlockedTerm(word, severity, allowedContexts: contexts));
  }

  void _parseRemote(String raw) {
    if (raw.isEmpty) return;
    for (final line in raw.split('\n')) {
      _parseLine(line);
    }
  }

  FilterSeverity _parseSeverity(String s) {
    switch (s.toLowerCase()) {
      case 'low':
        return FilterSeverity.low;
      case 'high':
        return FilterSeverity.high;
      case 'critical':
        return FilterSeverity.high;
      default:
        return FilterSeverity.medium;
    }
  }

  FilterContext? _parseContext(String s) {
    switch (s.toLowerCase()) {
      case 'username':
        return FilterContext.username;
      case 'bio':
        return FilterContext.bio;
      case 'post':
        return FilterContext.post;
      case 'message':
        return FilterContext.message;
      case 'comment':
        return FilterContext.comment;
      default:
        return null;
    }
  }

  List<ProfanityMatch> findMatches(String input, FilterContext context) {
    final matches = <ProfanityMatch>[];
    final lower = input.toLowerCase();
    for (final term in _terms) {
      if (term.allowedContexts != null && !term.allowedContexts!.contains(context)) {
        continue;
      }
      final pattern = RegExp(r'\b' + RegExp.escape(term.word) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(lower)) {
        matches.add(ProfanityMatch(
          term: term.word,
          severity: term.severity,
          matchedText: term.word,
        ));
      }
    }
    return matches;
  }

  FilterSeverity? highestSeverity(String input, FilterContext context) {
    final matches = findMatches(input, context);
    if (matches.isEmpty) return null;
    FilterSeverity highest = FilterSeverity.low;
    for (final m in matches) {
      if (_severityRank(m.severity) > _severityRank(highest)) highest = m.severity;
    }
    return highest;
  }

  int _severityRank(FilterSeverity s) {
    switch (s) {
      case FilterSeverity.low:
        return 1;
      case FilterSeverity.medium:
        return 2;
      case FilterSeverity.high:
        return 3;
    }
  }

  String maskText(String input, FilterContext context) {
    var result = input;
    for (final term in _terms) {
      if (term.severity != FilterSeverity.low) continue;
      if (term.allowedContexts != null && !term.allowedContexts!.contains(context)) continue;
      final pattern = RegExp(r'\b' + RegExp.escape(term.word) + r'\b', caseSensitive: false);
      result = result.replaceAllMapped(pattern, (m) => '●' * m.group(0)!.length);
    }
    return result;
  }

  bool containsViolation(String input, {FilterContext context = FilterContext.message}) {
    return findMatches(input, context).any((m) => m.severity != FilterSeverity.low);
  }
}
