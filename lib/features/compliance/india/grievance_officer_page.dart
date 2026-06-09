/// Firestore Collection Schema: grievances
///
/// Document ID: Auto-generated
/// Fields:
/// - userId: String (UID of the reporter)
/// - name: String (Name of the reporter)
/// - email: String (Email of the reporter)
/// - issueType: String (Category of grievance)
/// - description: String (Details)
/// - status: String ("open", "in_progress", "resolved")
/// - timestamp: Timestamp (When submitted)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GrievanceOfficerPage extends StatefulWidget {
  const GrievanceOfficerPage({super.key});

  @override
  State<GrievanceOfficerPage> createState() => _GrievanceOfficerPageState();
}

class _GrievanceOfficerPageState extends State<GrievanceOfficerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _issueType = 'Content Violation';
  bool _isSubmitting = false;

  final List<String> _issueTypes = [
    'Content Violation',
    'Privacy Breach',
    'Harassment',
    'Impersonation',
    'Intellectual Property',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitGrievance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('grievances').add({
        'userId': user?.uid ?? 'anonymous',
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'issueType': _issueType,
        'description': _descriptionController.text.trim(),
        'status': 'open',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grievance submitted successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit grievance: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Grievance Officer'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOfficerInfo(),
              const SizedBox(height: 24),
              const Text(
                'Submit a Grievance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Your Name'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          const InputDecoration(labelText: 'Your Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (!value.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _issueType,
                      decoration:
                          const InputDecoration(labelText: 'Issue Type'),
                      items: _issueTypes
                          .map((type) =>
                              DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _issueType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 4,
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitGrievance,
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text('Submit Grievance'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildOfficerInfo() => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grievance Redressal Mechanism',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Officer Name: Placeholder Officer'),
              Text('Email: grievance@gotchaa.app'),
              SizedBox(height: 8),
              Text(
                'Response Time:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                  'We acknowledge receipt within 24 hours. Most issues are resolved within 15 days as per India IT Rules 2021.'),
            ],
          ),
        ),
      );
}
