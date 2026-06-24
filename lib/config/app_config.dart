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
      case 'development':
      default:
        return 'http://localhost:8000';
    }
  }
}
