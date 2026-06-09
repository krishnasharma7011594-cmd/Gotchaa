import 'package:flutter/material.dart';

import '../../../../core/legal/legal_documents.dart';
import 'legal_document_reader_screen.dart';

/// Opens Privacy Policy v3.0 in the legal document reader.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = LegalDocuments.byId('privacy')!;
    return LegalDocumentReaderScreen(document: doc);
  }
}
