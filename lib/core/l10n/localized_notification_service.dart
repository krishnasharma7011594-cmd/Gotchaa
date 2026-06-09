import 'package:shared_preferences/shared_preferences.dart';

class NotificationLocaleCache {
  static const String _localeKey = 'background_notification_locale';

  static Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey) ?? 'en';
  }
}

class LocalizedNotificationService {
  // Simulates handling a background push message in the requested locale
  static Future<String> getLocalizedTitle(
      Map<String, dynamic> dataPayload) async {
    final String locale = await NotificationLocaleCache.getLocale();

    // In a real app, you would load the specific ARB file string or use intl messages mapped by type
    // Since we don't have BuildContext in the background isolate, we would need to manually read the ARB
    // or register messages in `intl`.

    final String type = dataPayload['type'] ?? '';

    // Minimal fallback resolution logic for background without BuildContext
    if (type == 'newConnection') {
      if (locale == 'hi') return 'आपका एक नया कनेक्शन इंतज़ार कर रहा है! 💬';
      if (locale == 'ar') return 'لديك اتصال جديد في انتظارك! 💬';
      return 'You have a new connection waiting! 💬';
    }

    return 'New Notification';
  }
}
