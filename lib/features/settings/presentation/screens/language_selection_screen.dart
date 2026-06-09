import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/providers/language_provider.dart';

class LanguageData {

  LanguageData({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.flag,
  });
  final String code;
  final String nativeName;
  final String englishName;
  final String flag;
}

// Complete list of 45 supported languages
final supportedLanguages = [
  // Tier 1
  LanguageData(code: 'en', nativeName: 'English', englishName: 'English', flag: '🇬🇧'),
  LanguageData(code: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi', flag: '🇮🇳'),
  LanguageData(code: 'es', nativeName: 'Español', englishName: 'Spanish', flag: '🇪🇸'),
  LanguageData(code: 'pt', nativeName: 'Português', englishName: 'Portuguese', flag: '🇵🇹'),
  LanguageData(code: 'ar', nativeName: 'العربية', englishName: 'Arabic', flag: '🇸🇦'),
  LanguageData(code: 'fr', nativeName: 'Français', englishName: 'French', flag: '🇫🇷'),
  LanguageData(code: 'de', nativeName: 'Deutsch', englishName: 'German', flag: '🇩🇪'),
  LanguageData(code: 'ru', nativeName: 'Русский', englishName: 'Russian', flag: '🇷🇺'),
  LanguageData(code: 'ja', nativeName: '日本語', englishName: 'Japanese', flag: '🇯🇵'),
  LanguageData(code: 'ko', nativeName: '한국어', englishName: 'Korean', flag: '🇰🇷'),
  LanguageData(code: 'zh_CN', nativeName: '中文简体', englishName: 'Chinese Simplified', flag: '🇨🇳'),
  LanguageData(code: 'zh_TW', nativeName: '中文繁體', englishName: 'Chinese Traditional', flag: '🇹🇼'),
  LanguageData(code: 'tr', nativeName: 'Türkçe', englishName: 'Turkish', flag: '🇹🇷'),
  LanguageData(code: 'it', nativeName: 'Italiano', englishName: 'Italian', flag: '🇮🇹'),
  LanguageData(code: 'nl', nativeName: 'Nederlands', englishName: 'Dutch', flag: '🇳🇱'),
  
  // Tier 2
  LanguageData(code: 'bn', nativeName: 'বাংলা', englishName: 'Bengali', flag: '🇧🇩'),
  LanguageData(code: 'ur', nativeName: 'اردو', englishName: 'Urdu', flag: '🇵🇰'),
  LanguageData(code: 'fa', nativeName: 'فارسی', englishName: 'Persian/Farsi', flag: '🇮🇷'),
  LanguageData(code: 'id', nativeName: 'Bahasa Indonesia', englishName: 'Indonesian', flag: '🇮🇩'),
  LanguageData(code: 'ms', nativeName: 'Bahasa Melayu', englishName: 'Malay', flag: '🇲🇾'),
  LanguageData(code: 'th', nativeName: 'ภาษาไทย', englishName: 'Thai', flag: '🇹🇭'),
  LanguageData(code: 'vi', nativeName: 'Tiếng Việt', englishName: 'Vietnamese', flag: '🇻🇳'),
  LanguageData(code: 'pl', nativeName: 'Polski', englishName: 'Polish', flag: '🇵🇱'),
  LanguageData(code: 'uk', nativeName: 'Українська', englishName: 'Ukrainian', flag: '🇺🇦'),
  LanguageData(code: 'sv', nativeName: 'Svenska', englishName: 'Swedish', flag: '🇸🇪'),
  LanguageData(code: 'no', nativeName: 'Norsk', englishName: 'Norwegian', flag: '🇳🇴'),
  LanguageData(code: 'da', nativeName: 'Dansk', englishName: 'Danish', flag: '🇩🇰'),
  LanguageData(code: 'fi', nativeName: 'Suomi', englishName: 'Finnish', flag: '🇫🇮'),
  LanguageData(code: 'el', nativeName: 'Ελληνικά', englishName: 'Greek', flag: '🇬🇷'),
  LanguageData(code: 'he', nativeName: 'עברית', englishName: 'Hebrew', flag: '🇮🇱'),
  LanguageData(code: 'ro', nativeName: 'Română', englishName: 'Romanian', flag: '🇷🇴'),
  LanguageData(code: 'hu', nativeName: 'Magyar', englishName: 'Hungarian', flag: '🇭🇺'),
  LanguageData(code: 'cs', nativeName: 'Čeština', englishName: 'Czech', flag: '🇨🇿'),
  LanguageData(code: 'sk', nativeName: 'Slovenčina', englishName: 'Slovak', flag: '🇸🇰'),
  LanguageData(code: 'hr', nativeName: 'Hrvatski', englishName: 'Croatian', flag: '🇭🇷'),
  LanguageData(code: 'sw', nativeName: 'Kiswahili', englishName: 'Swahili', flag: '🇰🇪'),
  LanguageData(code: 'tl', nativeName: 'Filipino', englishName: 'Tagalog', flag: '🇵🇭'),
  LanguageData(code: 'ne', nativeName: 'नेपाली', englishName: 'Nepali', flag: '🇳🇵'),
  LanguageData(code: 'si', nativeName: 'සිංහල', englishName: 'Sinhala', flag: '🇱🇰'),
  LanguageData(code: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil', flag: '🇮🇳'), // Alternatively Sri Lanka
  LanguageData(code: 'te', nativeName: 'తెలుగు', englishName: 'Telugu', flag: '🇮🇳'),
  LanguageData(code: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada', flag: '🇮🇳'),
  LanguageData(code: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam', flag: '🇮🇳'),
  LanguageData(code: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi', flag: '🇮🇳'),
  LanguageData(code: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati', flag: '🇮🇳'),
  LanguageData(code: 'mr', nativeName: 'मराठी', englishName: 'Marathi', flag: '🇮🇳'),
];

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  String searchQuery = '';

  List<LanguageData> get filteredLanguages {
    if (searchQuery.isEmpty) return supportedLanguages;
    return supportedLanguages.where((lang) => lang.englishName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          lang.nativeName.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredLanguages.length,
              itemBuilder: (context, index) {
                final lang = filteredLanguages[index];
                final isSelected = currentLocale.languageCode == lang.code;

                return ListTile(
                  leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(lang.nativeName),
                  subtitle: Text(lang.englishName),
                  trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    ref.read(languageProvider.notifier).setLanguage(lang.code);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
