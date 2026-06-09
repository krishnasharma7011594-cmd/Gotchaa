import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';

/// A reusable in-app browser screen that opens URLs inside the app.
///
/// Accepts [url] and [title]. Displays a custom AppBar with a back button
/// and title only (no URL bar). Shows a LinearProgressIndicator while the
/// page is loading. On failure, shows a clean error state with a retry button.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => InAppWebViewScreen(
///       url: 'https://example.com',
///       title: 'Example',
///     ),
///   ),
/// );
/// ```
class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({
    required this.url,
    required this.title,
    super.key,
  });

  final String url;
  final String title;

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  late final WebViewController _controller;

  /// 0.0 – 1.0; null means fully loaded (hide bar).
  double? _loadProgress;

  /// Set to the error description when the main-frame load fails.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Disable JS message channels / addJavaScriptChannel to avoid arbitrary
      // injection — pages cannot call back into Dart unless explicitly wired.
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loadProgress = 0.0;
                _errorMessage = null;
              });
            }
          },
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _loadProgress = progress / 100.0;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _loadProgress = null; // hide bar
              });
            }
          },
          onWebResourceError: (error) {
            // Only surface main-frame errors to avoid false positives from
            // third-party sub-resources (ads, analytics, etc.).
            if (error.isForMainFrame != true) {
              return;
            }
            if (mounted) {
              setState(() {
                _loadProgress = null;
                _errorMessage = error.description;
              });
            }
          },
          // Keep all navigation inside the WebView — never open external
          // browser.
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _loadProgress = 0.0;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : Colors.white;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0D0D0D);
    final appBarBg = isDark ? AppColors.darkSurface : Colors.white;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          navigator.pop(result);
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textPrimary,
              size: 20,
            ),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          title: Text(
            widget.title,
            style: GoogleFonts.outfit(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          bottom: _loadProgress != null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _loadProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.electricBlue,
                    ),
                    minHeight: 2,
                  ),
                )
              : null,
        ),
        body: _errorMessage != null
            ? _ErrorView(
                message: _errorMessage!,
                onRetry: _retry,
                onBack: () => Navigator.of(context).pop(),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF0D0D0D);
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : Colors.grey.shade500;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: textSecondary,
            ),
            const SizedBox(height: 20),
            Text(
              'Page failed to load',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message.isNotEmpty ? message : 'Something went wrong.',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Back button
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                  label: Text(
                    'Go Back',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.electricBlue,
                    side: const BorderSide(color: AppColors.electricBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Retry button
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
