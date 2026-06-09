import 'package:flutter/material.dart';

import '../../../../core/legal/legal_documents.dart';
import 'legal_document_reader_screen.dart';

/// Opens Terms of Service v3.0 in the legal document reader.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final doc = LegalDocuments.byId('terms')!;
    return LegalDocumentReaderScreen(document: doc);
  }
}
