import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/consent_gate_service.dart';
import '../../../../core/services/data_export_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'delete_account_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _analytics = false;
  bool _performance = false;
  bool _personalization = false;
  bool _doNotSell = false;
  String? _analyticsTs;
  String? _performanceTs;
  String? _personalizationTs;
  String? _doNotSellTs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ConsentGateService.hasAnalyticsConsent(),
      ConsentGateService.hasPerformanceConsent(),
      ConsentGateService.hasPersonalizationConsent(),
      ConsentGateService.isDoNotSellEnabled(),
      ConsentGateService.getAnalyticsTimestamp(),
      ConsentGateService.getPerformanceTimestamp(),
      ConsentGateService.getPersonalizationTimestamp(),
      ConsentGateService.getDoNotSellTimestamp(),
    ]);
    if (mounted) {
      setState(() {
        _analytics = results[0]! as bool;
        _performance = results[1]! as bool;
        _personalization = results[2]! as bool;
        _doNotSell = results[3]! as bool;
        _analyticsTs = results[4] as String?;
        _performanceTs = results[5] as String?;
        _personalizationTs = results[6] as String?;
        _doNotSellTs = results[7] as String?;
        _loading = false;
      });
    }
  }

  String _formatTs(String? iso) {
    if (iso == null) return 'Not set';
    try {
      return DateFormat.yMMMd().add_jm().format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  Future<void> _exportData() async {
    final result = await DataExportService.instance.requestExport();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.ok
            ? (result.message ?? 'Export requested')
            : (result.message ?? 'Export failed')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8F9FB);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0D0D0D);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text('Privacy & Data',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 18, color: textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section('Data Collection', textSecondary),
                _toggle('Anonymous usage analytics', _analytics, _analyticsTs,
                    (v) async {
                  await ConsentGateService.setAnalyticsConsent(v);
                  setState(() {
                    _analytics = v;
                    _analyticsTs = DateTime.now().toIso8601String();
                  });
                }, textPrimary, textSecondary),
                _toggle('Performance monitoring', _performance, _performanceTs,
                    (v) async {
                  await ConsentGateService.setPerformanceConsent(v);
                  setState(() {
                    _performance = v;
                    _performanceTs = DateTime.now().toIso8601String();
                  });
                }, textPrimary, textSecondary),
                _toggle('Personalization', _personalization, _personalizationTs,
                    (v) async {
                  await ConsentGateService.setPersonalizationConsent(v);
                  setState(() {
                    _personalization = v;
                    _personalizationTs = DateTime.now().toIso8601String();
                  });
                }, textPrimary, textSecondary),
                const SizedBox(height: 16),
                _section('Your Data', textSecondary),
                ListTile(
                  leading: const Icon(Icons.download_rounded,
                      color: AppColors.electricBlue),
                  title: Text('Download my data',
                      style: GoogleFonts.outfit(color: textPrimary)),
                  subtitle: Text('Export a copy of your profile data',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: textSecondary)),
                  onTap: _exportData,
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded,
                      color: AppColors.error),
                  title: Text('Delete my data',
                      style: GoogleFonts.outfit(color: textPrimary)),
                  subtitle: Text('Permanently delete your account and data',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: textSecondary)),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DeleteAccountScreen())),
                ),
                const SizedBox(height: 16),
                _section('California Privacy (CCPA)', textSecondary),
                SwitchListTile(
                  title: Text('Do Not Sell My Personal Information',
                      style:
                          GoogleFonts.outfit(fontSize: 15, color: textPrimary)),
                  subtitle: Text(
                    'We do not sell your personal information',
                    style:
                        GoogleFonts.outfit(fontSize: 12, color: textSecondary),
                  ),
                  value: _doNotSell,
                  onChanged: (v) async {
                    await ConsentGateService.setDoNotSell(v);
                    setState(() {
                      _doNotSell = v;
                      _doNotSellTs = DateTime.now().toIso8601String();
                    });
                  },
                  activeThumbColor: AppColors.electricBlue,
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Text('Last updated: ${_formatTs(_doNotSellTs)}',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: textSecondary)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('California Privacy Rights',
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary)),
                      const SizedBox(height: 6),
                      ...[
                        'Right to know what personal information is collected',
                        'Right to know whether personal information is sold or disclosed',
                        'Right to opt out of the sale of personal information',
                        'Right to access personal information',
                        'Right to request deletion of personal information',
                        'Right to correct inaccurate personal information',
                        'Right to limit use of sensitive personal information',
                        'Right to non-discrimination for exercising privacy rights',
                      ].map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $r',
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: textSecondary,
                                    height: 1.35)),
                          )),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _section(String title, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8)),
      );

  Widget _toggle(
          String title,
          bool value,
          String? ts,
          ValueChanged<bool> onChanged,
          Color textPrimary,
          Color textSecondary) =>
      Column(
        children: [
          SwitchListTile(
            title: Text(title,
                style: GoogleFonts.outfit(fontSize: 15, color: textPrimary)),
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.electricBlue,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Last updated: ${_formatTs(ts)}',
                  style:
                      GoogleFonts.outfit(fontSize: 11, color: textSecondary)),
            ),
          ),
        ],
      );
}
