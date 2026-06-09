import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/consent_gate_service.dart';
import '../../../core/theme/app_colors.dart';

/// GDPR analytics consent modal — shown once after legal acceptance.
class GotchaaConsentModal extends StatefulWidget {
  const GotchaaConsentModal({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const GotchaaConsentModal(),
      );

  @override
  State<GotchaaConsentModal> createState() => _GotchaaConsentModalState();
}

class _GotchaaConsentModalState extends State<GotchaaConsentModal> {
  bool _manageMode = false;
  bool _analytics = false;
  bool _performance = false;
  bool _personalization = false;

  Future<void> _close() async {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Help Improve GOTCHAA',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We use analytics to understand how you use GOTCHAA and fix issues faster. This data is anonymous and never sold.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'What we collect:',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _bullet('✓',
                    'App crashes and errors (always on — helps keep app stable)',
                    locked: true),
                _bullet('○',
                    'Anonymous usage analytics (optional — helps us improve features)',
                    value: _manageMode ? _analytics : null,
                    onChanged: _manageMode
                        ? (v) => setState(() => _analytics = v)
                        : null),
                _bullet('○',
                    'Performance monitoring (optional — helps us make app faster)',
                    value: _manageMode ? _performance : null,
                    onChanged: _manageMode
                        ? (v) => setState(() => _performance = v)
                        : null),
                if (_manageMode) ...[
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Personalization',
                        style: GoogleFonts.outfit(fontSize: 14)),
                    subtitle: Text('Tailored recommendations',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey)),
                    value: _personalization,
                    onChanged: (v) => setState(() => _personalization = v),
                    activeThumbColor: AppColors.primaryBlue,
                  ),
                ],
                const SizedBox(height: 20),
                if (!_manageMode) ...[
                  _btn('Accept All', true, () async {
                    await ConsentGateService.grantAllConsents();
                    await _close();
                  }),
                  const SizedBox(height: 8),
                  _btn('Essential Only', false, () async {
                    await ConsentGateService.grantEssentialOnly();
                    await _close();
                  }),
                  const SizedBox(height: 8),
                  _btn(
                      'Manage',
                      false,
                      () => setState(() {
                            _manageMode = true;
                            _analytics = false;
                            _performance = false;
                            _personalization = false;
                          }),
                      outlined: true),
                ] else ...[
                  _btn('Save Preferences', true, () async {
                    await ConsentGateService.setPromptedForConsent(true);
                    await ConsentGateService.setAnalyticsConsent(_analytics);
                    await ConsentGateService.setPerformanceConsent(
                        _performance);
                    await ConsentGateService.setPersonalizationConsent(
                        _personalization);
                    await _close();
                  }),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _bullet(String marker, String text,
      {bool locked = false, bool? value, ValueChanged<bool>? onChanged}) {
    if (onChanged != null && value != null) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text('$marker $text', style: GoogleFonts.outfit(fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primaryBlue,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$marker $text',
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: locked ? Colors.black87 : Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _btn(String label, bool primary, VoidCallback onPressed,
          {bool outlined = false}) =>
      SizedBox(
        width: double.infinity,
        height: 48,
        child: outlined
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(label,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              )
            : ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(label,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
      );
}
