import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/l10n/language_meta.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/theme/app_colors.dart';

// ──────────────────────────────────────────────────────────
//  ML Kit chat-language list (unchanged)
// ──────────────────────────────────────────────────────────
const Map<String, TranslateLanguage> _chatLanguages = {
  'English': TranslateLanguage.english,
  'Hindi (हिन्दी)': TranslateLanguage.hindi,
  'Spanish (Español)': TranslateLanguage.spanish,
  'French (Français)': TranslateLanguage.french,
  'Arabic (العربية)': TranslateLanguage.arabic,
  'Portuguese (Português)': TranslateLanguage.portuguese,
  'Indonesian (Bahasa Indonesia)': TranslateLanguage.indonesian,
  'Russian (Русский)': TranslateLanguage.russian,
  'German (Deutsch)': TranslateLanguage.german,
  'Chinese (中文)': TranslateLanguage.chinese,
  'Japanese (日本語)': TranslateLanguage.japanese,
  'Korean (한국어)': TranslateLanguage.korean,
};

// ──────────────────────────────────────────────────────────
//  LanguageSettingsScreen
// ──────────────────────────────────────────────────────────
class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends ConsumerState<LanguageSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _isDownloading = false;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── UI locale change (instant, no download) ────────────
  Future<void> _selectUiLanguage(LanguageMeta lang) async {
    final oldLang = ref.read(languageProvider).languageCode;
    await ref.read(languageProvider.notifier).setLanguage(lang.code);

    if (oldLang != lang.code) {
      AnalyticsService.logLanguageSwitched(
        fromLanguage: oldLang,
        toLanguage: lang.code,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${context.tr("language_changed")} ${lang.nameNative}',
          style: GoogleFonts.outfit(),
        ),
        backgroundColor: AppColors.electricBlue,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  // ── ML Kit chat model download ─────────────────────────
  Future<void> _selectChatLanguage(TranslateLanguage language) async {
    setState(() {
      _isDownloading = true;
      _downloadError = null;
    });
    try {
      final svc = ref.read(translationServiceProvider);
      final isDownloaded = await svc.isModelDownloaded(language);
      if (!isDownloaded) {
        final noInternetMsg = context.tr('no_internet'); // cache before async
        final c = await Connectivity().checkConnectivity();
        if (c.contains(ConnectivityResult.none) ||
            (c.length == 1 && c.first == ConnectivityResult.none)) {
          throw Exception(noInternetMsg);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Downloading ${language.name} model…',
                style: GoogleFonts.outfit(),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        final ok = await svc.downloadModel(language).timeout(
              const Duration(minutes: 5),
              onTimeout: () => throw Exception('Download timed out.'),
            );
        if (!ok) throw Exception('Model download failed.');
      }
      await svc.setPreferredLanguage(language);
      // ref.read(localeProvider.notifier).updateLocale();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat language → ${language.name}',
              style: GoogleFonts.outfit()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _downloadError = msg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.outfit()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: context.tr('btn_retry'),
            textColor: Colors.white,
            onPressed: () {
              if (mounted) _selectChatLanguage(language);
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = ref.watch(languageProvider).languageCode;
    final svc = ref.watch(translationServiceProvider);
    final currentChat = svc.preferredLanguage;
    final autoTranslate = svc.autoTranslateEnabled;

    // Filter UI languages by search query
    const allUiLangs = AppLocalizationsConfig.languages;

    final filteredUi = _query.isEmpty
        ? allUiLangs
        : allUiLangs.where((l) {
            final q = _query.toLowerCase();
            return l.nameEn.toLowerCase().contains(q) ||
                l.nameNative.toLowerCase().contains(q) ||
                l.code.toLowerCase().contains(q);
          }).toList();

    // Filter chat languages by search query
    final filteredChat = _query.isEmpty
        ? _chatLanguages.entries.toList()
        : _chatLanguages.entries
            .where((e) => e.key.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FB),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
        ),
        title: Text(
          context.tr('language_settings_title'),
          style: GoogleFonts.outfit(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.electricBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.electricBlue,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: context.tr('language_tab_app')),
            Tab(text: context.tr('language_tab_chat')),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Search bar ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: context.tr('language_search_hint'),
                      hintStyle: GoogleFonts.outfit(
                          color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _searchCtrl.clear,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              // ── Tabs ─────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Tab 0: App UI Language ──────────────
                    _buildUiLanguageTab(filteredUi, currentCode),
                    // ── Tab 1: Chat Translation ─────────────
                    _buildChatLanguageTab(
                        filteredChat, currentChat, autoTranslate, svc),
                  ],
                ),
              ),
            ],
          ),
          // ── Download overlay ──────────────────────────────
          if (_isDownloading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('downloading_model'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          if (_downloadError != null && !_isDownloading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(_downloadError!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.electricBlue),
                      onPressed: () => setState(() => _downloadError = null),
                      child: Text(context.tr('btn_close'),
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── UI Language tab ──────────────────────────────────────
  Widget _buildUiLanguageTab(List<LanguageMeta> langs, String currentCode) =>
      ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              context.tr('language_section_ui'),
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: langs.asMap().entries.map((entry) {
                final idx = entry.key;
                final lang = entry.value;
                final isSelected = lang.code == currentCode;
                return Column(
                  children: [
                    InkWell(
                      onTap: () => _selectUiLanguage(lang),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Text(lang.flag,
                                style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lang.nameNative,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.electricBlue
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    lang.nameEn,
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded,
                                  color: AppColors.electricBlue, size: 22)
                            else
                              const SizedBox(width: 22),
                          ],
                        ),
                      ),
                    ),
                    if (idx < langs.length - 1)
                      Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 58,
                          color: Colors.grey.shade200),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      );

  // ── Chat Translation tab ─────────────────────────────────
  Widget _buildChatLanguageTab(
          List<MapEntry<String, TranslateLanguage>> langs,
          TranslateLanguage currentChat,
          bool autoTranslate,
          TranslationService svc) =>
      ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              context.tr('language_section_chat'),
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.8),
            ),
          ),
          // Auto-translate toggle
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.g_translate_rounded,
                      color: AppColors.electricBlue, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('language_auto_translate'),
                            style: GoogleFonts.outfit(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                        Text(context.tr('language_auto_translate_sub'),
                            style: GoogleFonts.outfit(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Switch(
                    value: autoTranslate,
                    onChanged: (v) async {
                      await svc.setAutoTranslate(v);
                      setState(() {});
                    },
                    activeThumbColor: AppColors.electricBlue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('language_select'),
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade500,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: langs.asMap().entries.map((entry) {
                final idx = entry.key;
                final e = entry.value;
                final isSelected = e.value == currentChat;
                return Column(
                  children: [
                    ListTile(
                      title: Text(
                        e.key,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.electricBlue
                              : Colors.black,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.electricBlue)
                          : null,
                      onTap: () => _selectChatLanguage(e.value),
                    ),
                    if (idx < langs.length - 1)
                      Divider(
                          height: 1,
                          thickness: 0.5,
                          indent: 16,
                          color: Colors.grey.shade200),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 80),
        ],
      );
}
