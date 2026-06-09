import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/legal/legal_documents.dart';
import '../../../../core/theme/app_colors.dart';
import 'legal_document_reader_screen.dart';

class LegalHubScreen extends StatefulWidget {
  const LegalHubScreen({super.key});

  @override
  State<LegalHubScreen> createState() => _LegalHubScreenState();
}

class _LegalHubScreenState extends State<LegalHubScreen> {
  String? _acceptedPrivacy;
  String? _acceptedTerms;

  @override
  void initState() {
    super.initState();
    _loadAcceptedVersions();
  }

  Future<void> _loadAcceptedVersions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _acceptedPrivacy = prefs.getString(StorageKeys.privacyAcceptedVersion);
      _acceptedTerms = prefs.getString(StorageKeys.termsAcceptedVersion);
    });
  }

  bool _showBannerFor(LegalDocument doc) {
    if (doc.id == 'privacy') {
      return _acceptedPrivacy != null &&
          _acceptedPrivacy != doc.version &&
          doc.changeSummary != null;
    }
    if (doc.id == 'terms') {
      return _acceptedTerms != null &&
          _acceptedTerms != doc.version &&
          doc.changeSummary != null;
    }
    return false;
  }

  String? _previousVersionFor(LegalDocument doc) {
    if (doc.id == 'privacy') return _acceptedPrivacy;
    if (doc.id == 'terms') return _acceptedTerms;
    return doc.previousVersion;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8F9FB);
    final card = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF0D0D0D);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    final needsReaccept = (_acceptedPrivacy != LegalConfig.privacyVersion) ||
        (_acceptedTerms != LegalConfig.termsVersion);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text('Legal',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 18, color: textPrimary)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (needsReaccept)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
              ),
              child: Text(
                'Our legal documents were updated to Version ${LegalDocuments.bundleVersion} (${LegalConfig.effectiveLabel}). '
                'Please review and accept the Privacy Policy and Terms of Service.',
                style: GoogleFonts.outfit(fontSize: 13, color: textPrimary, height: 1.4),
              ),
            ),
          Text(
            'All documents are stored on your device and available offline.',
            style: GoogleFonts.outfit(fontSize: 12, color: textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          ...LegalDocuments.all.map((doc) {
            final banner = _showBannerFor(doc);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: card,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LegalDocumentReaderScreen(
                        document: doc,
                        showChangeBanner: banner,
                        previousAcceptedVersion: _previousVersionFor(doc),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          _iconFor(doc.id),
                          color: AppColors.electricBlue,
                          size: 22,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(doc.title,
                                        style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary)),
                                  ),
                                  if (banner)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Updated',
                                          style: GoogleFonts.outfit(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryBlue)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version ${doc.version} · Updated ${DateFormat.yMMMd().format(doc.lastUpdated)}',
                                style: GoogleFonts.outfit(
                                    fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconFor(String id) {
    switch (id) {
      case 'privacy':
        return Icons.privacy_tip_rounded;
      case 'terms':
        return Icons.gavel_rounded;
      case 'community':
        return Icons.groups_rounded;
      case 'cookies':
        return Icons.cookie_rounded;
      case 'aup':
        return Icons.rule_rounded;
      case 'dmca':
        return Icons.copyright_rounded;
      case 'law_enforcement':
        return Icons.balance_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.description_rounded;
    }
  }
}
