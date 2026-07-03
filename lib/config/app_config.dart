class AppConfig {
  AppConfig._internal();
  static final AppConfig instance = AppConfig._internal();

  static const String backendEnv = String.fromEnvironment(
    'BACKEND_ENV',
    defaultValue: 'development',
  );

  String get backendUrl {
    switch (backendEnv) {
      case 'production':
        return 'https://gotchaa.railway.app';
      case 'staging':
        return 'https://gotchaa-staging.railway.app';
      case 'emulator':
        // Android Studio emulator — maps to host machine localhost
        return 'http://10.0.2.2:8000';
      case 'development':
      default:
        // Real Android device on same Wi-Fi — use your PC's local IP
        // Run: ipconfig (Windows) or ifconfig (Mac/Linux) to find it
        // Current PC IP: 10.157.231.2
        return 'http://10.157.231.2:8000';
    }
  }
}
