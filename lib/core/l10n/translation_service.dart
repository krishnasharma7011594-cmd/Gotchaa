import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AutoTranslationService {
  static const String _libreTranslateUrl = 'https://translate.terraprint.co/translate'; // Replace with your instance or official API

  static Future<String?> translateText(String text, String sourceLang, String targetLang) async {
    if (sourceLang == targetLang) return text;
    
    try {
      final response = await http.post(
        Uri.parse(_libreTranslateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'q': text,
          'source': sourceLang,
          'target': targetLang,
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'];
      }
    } catch (e) {
      
    }
    return null; // Fallback to original text if error
  }
}

class LocaleDateFormatter {
  static String formatDate(DateTime date, String locale) => DateFormat.yMMMMd(locale).format(date);
  
  static String formatTime(DateTime date, String locale) => DateFormat.jm(locale).format(date);
}

class LocaleNumberFormatter {
  static String formatNumber(num number, String locale) {
    // This will correctly output Arabic numerals (٠١٢٣٤٥٦٧٨٩) when the locale is 'ar'
    return NumberFormat.decimalPattern(locale).format(number);
  }
}
