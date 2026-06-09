import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'report_categories.dart';
import 'report_model.dart';
import 'report_repository.dart';

class ReportBottomSheet extends StatefulWidget {
  const ReportBottomSheet({
    required this.reportedUserId,
    required this.contentType,
    required this.contentId,
    super.key,
    this.contentPreview,
  });

  final String reportedUserId;
  final String contentType;
  final String contentId;
  final String? contentPreview;

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final _repo = ReportRepository();
  String? _category;
  String? _subReason;
  final _otherController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_category == null) return;
    if (_category == 'Other' && _otherController.text.trim().isEmpty) return;
    if (_subReason == null &&
        ReportCategories.categories[_category]!.length > 1) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final isChild = ReportCategories.isChildSafety(_category!);
      final report = ReportModel(
        reportedUserId: widget.reportedUserId,
        reportedByUserId: uid,
        contentType: widget.contentType,
        contentId: widget.contentId,
        category: _category!,
        subReason: _subReason,
        reason: _category == 'Other'
            ? _otherController.text.trim()
            : '$_category${_subReason != null ? ' — $_subReason' : ''}',
        status: 'pending',
        severity: isChild ? 'critical' : 'medium',
        timestamp: DateTime.now(),
        isCsamFlag: isChild,
        contentHidden: isChild,
        contentPreview: widget.contentPreview,
      );
      await _repo.submitReport(report);

      if (!mounted) return;
      Navigator.pop(context);
      final block = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thank you'),
          content: const Text(
            'Thank you for keeping GOTCHAA safe. Our trust team will review this report.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Done')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Block user'),
            ),
          ],
        ),
      );
      if (block == true) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('blocked_users')
            .doc(widget.reportedUserId)
            .set({'blockedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subs = _category != null
        ? ReportCategories.categories[_category]!
        : <String>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Report',
                style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Select a category',
                style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 12),
            ...ReportCategories.categories.keys.map(
              (cat) => RadioListTile<String>(
                title: Text(cat, style: const TextStyle(color: Colors.white)),
                value: cat,
                groupValue: _category,
                activeColor: AppColors.primaryBlue,
                onChanged: (v) => setState(() {
                  _category = v;
                  _subReason = null;
                }),
              ),
            ),
            if (_category != null && subs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Sub-reason',
                  style: GoogleFonts.outfit(
                      color: Colors.white70, fontWeight: FontWeight.w600)),
              ...subs.map(
                (s) => RadioListTile<String>(
                  title: Text(s, style: const TextStyle(color: Colors.white70)),
                  value: s,
                  groupValue: _subReason,
                  activeColor: AppColors.primaryBlue,
                  onChanged: (v) => setState(() => _subReason = v),
                ),
              ),
            ],
            if (_category == 'Other') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe the issue…',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Report',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showReportBottomSheet(
  BuildContext context, {
  required String reportedUserId,
  required String contentType,
  required String contentId,
  String? contentPreview,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReportBottomSheet(
      reportedUserId: reportedUserId,
      contentType: contentType,
      contentId: contentId,
      contentPreview: contentPreview,
    ),
  );
}
