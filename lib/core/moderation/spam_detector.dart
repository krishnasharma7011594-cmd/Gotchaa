class SpamDetector {
  static final SpamDetector _instance = SpamDetector._internal();
  factory SpamDetector() => _instance;
  SpamDetector._internal();

  // Track messages for repeated message detection
  // Key: message text, Value: list of timestamps when it was sent
  final Map<String, List<DateTime>> _messageHistory = {};

  /// Checks if a message is spam
  bool isSpam(String text) {
    if (text.isEmpty) return false;

    // 1. Detect all-caps abuse
    if (_isAllCapsAbuse(text)) {
      return true;
    }

    // 2. Detect link spam patterns
    if (_isLinkSpam(text)) {
      return true;
    }

    // 3. Detect repeated messages (same text sent 3+ times in 60 seconds)
    if (_isRepeatedMessage(text)) {
      return true;
    }

    return false;
  }

  bool _isAllCapsAbuse(String text) {
    // Only check if text is long enough
    if (text.length < 10) return false;
    
    // Count uppercase letters
    int upperCount = 0;
    int letterCount = 0;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (RegExp(r'[a-zA-Z]').hasMatch(char)) {
        letterCount++;
        if (char == char.toUpperCase()) {
          upperCount++;
        }
      }
    }
    
    // If more than 80% of letters are uppercase, consider it abuse
    if (letterCount > 0 && (upperCount / letterCount) > 0.8) {
      return true;
    }
    
    return false;
  }

  bool _isLinkSpam(String text) {
    // Detect multiple links or suspicious link patterns
    final urlRegex = RegExp(
      r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})'
    );
    
    final matches = urlRegex.allMatches(text);
    
    // If more than 2 links in a short message, or any link in a very short message
    if (matches.length > 2) {
      return true;
    }
    
    if (matches.isNotEmpty && text.length < 20) {
      return true;
    }
    
    return false;
  }

  bool _isRepeatedMessage(String text) {
    final now = DateTime.now();
    final cleanText = text.trim().toLowerCase();
    
    // Clean up old messages (older than 60 seconds)
    _messageHistory.forEach((key, timestamps) {
      timestamps.removeWhere((t) => now.difference(t).inSeconds > 60);
    });
    _messageHistory.removeWhere((key, timestamps) => timestamps.isEmpty);
    
    // Add current message
    if (!_messageHistory.containsKey(cleanText)) {
      _messageHistory[cleanText] = [];
    }
    _messageHistory[cleanText]!.add(now);
    
    // Check if count >= 3
    if (_messageHistory[cleanText]!.length >= 3) {
      return true;
    }
    
    return false;
  }

  /// Clear history (useful for tests or logout)
  void clearHistory() {
    _messageHistory.clear();
  }
}
