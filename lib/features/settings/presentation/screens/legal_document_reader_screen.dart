import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/legal/legal_documents.dart';
import '../../../../core/theme/app_colors.dart';

class LegalDocumentReaderScreen extends StatefulWidget {
  const LegalDocumentReaderScreen({
    required this.document,
    super.key,
    this.showChangeBanner = false,
    this.previousAcceptedVersion,
  });

  final LegalDocument document;
  final bool showChangeBanner;
  final String? previousAcceptedVersion;

  @override
  State<LegalDocumentReaderScreen> createState() =>
      _LegalDocumentReaderScreenState();
}

class _LegalDocumentReaderScreenState extends State<LegalDocumentReaderScreen> {
  String _content = '';
  String _query = '';
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final text = await rootBundle.loadString(widget.document.assetPath);
      if (mounted) {
        setState(() {
          _content = text;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String get _displayContent {
    if (_query.isEmpty) return _content;
    final lower = _query.toLowerCase();
    final lines = _content.split('\n');
    final matches =
        lines.where((l) => l.toLowerCase().contains(lower)).toList();
    if (matches.isEmpty) return 'No matches for "$_query" in this document.';
    return matches.map((l) => '• $l').join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D1A) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.document.title,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: textPrimary),
            onPressed: () => Share.share(
              '${widget.document.title}\n${widget.document.shareUrl}\nVersion ${widget.document.version}',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: GoogleFonts.outfit(color: textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search in document…',
                hintStyle: GoogleFonts.outfit(color: textSecondary),
                prefixIcon:
                    Icon(Icons.search_rounded, color: textSecondary, size: 20),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          if (widget.showChangeBanner && widget.document.changeSummary != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What changed in ${widget.document.version}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  if (widget.previousAcceptedVersion != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'You previously accepted ${widget.previousAcceptedVersion}.',
                      style: GoogleFonts.outfit(
                          fontSize: 11, color: textSecondary),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    widget.document.changeSummary!,
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: textPrimary, height: 1.35),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Version ${widget.document.version} · ${DateFormat.yMMMd().format(widget.document.lastUpdated)}',
                  style: GoogleFonts.outfit(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: GoogleFonts.outfit(color: textSecondary)))
                    : Markdown(
                        data: _displayContent,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.outfit(
                            color: textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          h1: GoogleFonts.outfit(
                            color: textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: GoogleFonts.outfit(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: GoogleFonts.outfit(
                            color: textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          listBullet: GoogleFonts.outfit(color: textSecondary),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
