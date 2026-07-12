enum BroIntent {
  navigation,
  deepLink,
  conversation,
  search,
  help,
  settings,
  unknown
}

class BroContext {
  const BroContext({
    required this.currentScreen,
    required this.isInMiniApp,
    required this.isMicActive,
    required this.isRecording,
    required this.language,
    required this.theme,
  });

  final String currentScreen;
  final bool isInMiniApp;
  final bool isMicActive;
  final bool isRecording;
  final String language;
  final String theme;

  Map<String, dynamic> toJson() => {
        'currentScreen': currentScreen,
        'isInMiniApp': isInMiniApp,
        'isMicActive': isMicActive,
        'isRecording': isRecording,
        'language': language,
        'theme': theme,
      };

  @override
  String toString() =>
      'BroContext(currentScreen: $currentScreen, isInMiniApp: $isInMiniApp, isMicActive: $isMicActive, isRecording: $isRecording, language: $language, theme: $theme)';
}
