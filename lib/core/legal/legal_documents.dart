/// Registry of in-app legal documents (bundled as assets, offline-readable).
class LegalDocument {
  const LegalDocument({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.version,
    required this.lastUpdated,
    this.shareSlug,
    this.changeSummary,
    this.previousVersion,
  });

  final String id;
  final String title;
  final String assetPath;
  final String version;
  final DateTime lastUpdated;
  final String? shareSlug;
  final String? changeSummary;
  final String? previousVersion;

  String get shareUrl =>
      'https://gotchaa.app/legal/${shareSlug ?? id}';
}

class LegalDocuments {
  LegalDocuments._();

  static const String bundleVersion = 'v3.0';

  static final List<LegalDocument> all = [
    LegalDocument(
      id: 'privacy',
      title: 'Privacy Policy',
      assetPath: 'PRIVACY_POLICY.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'privacy',
      previousVersion: 'v2.0',
      changeSummary:
          'Removed inaccurate E2EE claims; added accurate data collection, Gemini AI, ML Kit on-device processing, Karma virtual economy, 24h message retention, and external browser disclaimer.',
    ),
    LegalDocument(
      id: 'terms',
      title: 'Terms of Service',
      assetPath: 'TERMS_OF_SERVICE.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'terms',
      previousVersion: 'v2.0',
      changeSummary:
          'Added EU/India/Australia liability carve-outs, Karma non-monetary rules, VibeTalk safety, 14-day appeals, age certification, and WebView/external service disclaimer.',
    ),
    LegalDocument(
      id: 'community',
      title: 'Community Guidelines',
      assetPath: 'COMMUNITY_GUIDELINES.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'community-guidelines',
      changeSummary: 'New document: zero-tolerance policies, enforcement ladder, VibeTalk and Karma rules.',
    ),
    LegalDocument(
      id: 'cookies',
      title: 'Cookie Policy',
      assetPath: 'COOKIE_POLICY.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'cookies',
      changeSummary: 'New document: GOTCHAA cookies, third-party browser cookies, consent controls.',
    ),
    LegalDocument(
      id: 'aup',
      title: 'Acceptable Use Policy',
      assetPath: 'ACCEPTABLE_USE_POLICY.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'acceptable-use',
      changeSummary: 'New document: automation, API abuse, Karma abuse, impersonation.',
    ),
    LegalDocument(
      id: 'dmca',
      title: 'DMCA Copyright Policy',
      assetPath: 'DMCA_POLICY.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'dmca',
      changeSummary: 'New document: takedown, counter-notice, repeat infringer policy.',
    ),
    LegalDocument(
      id: 'law_enforcement',
      title: 'Law Enforcement Guidelines',
      assetPath: 'LAW_ENFORCEMENT_POLICY.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'law-enforcement',
      changeSummary: 'New document: legal process, emergency requests, transparency commitment.',
    ),
    LegalDocument(
      id: 'security',
      title: 'Vulnerability Disclosure',
      assetPath: 'VULNERABILITY_DISCLOSURE_POLICY.md',
      version: 'v3.0',
      lastUpdated: DateTime(2026, 5, 21),
      shareSlug: 'security-disclosure',
      changeSummary: 'New document: safe harbor, response timelines, bug bounty commitment.',
    ),
  ];

  static LegalDocument? byId(String id) {
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
