/**
 * Firestore Collection Schema: deletion_requests
 * 
 * Document ID: uid (User ID)
 * Fields:
 * - status: String ("pending", "processed")
 * - requestedAt: Timestamp
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'consent_manager.dart';
import '../india/grievance_officer_page.dart';

class DataPrincipalRightsPage extends StatefulWidget {
  const DataPrincipalRightsPage({super.key});

  @override
  State<DataPrincipalRightsPage> createState() => _DataPrincipalRightsPageState();
}

class _DataPrincipalRightsPageState extends State<DataPrincipalRightsPage> {
  final ConsentManager _consentManager = ConsentManager();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, bool> _consents = {
    'dataProcessing': false,
    'marketing': false,
    'locationTracking': false,
    'analyticsTracking': false,
  };

  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Load Consents
    final dataProcessing = await _consentManager.hasConsent('dataProcessing');
    final marketing = await _consentManager.hasConsent('marketing');
    final locationTracking = await _consentManager.hasConsent('locationTracking');
    final analyticsTracking = await _consentManager.hasConsent('analyticsTracking');

    // Load User Data summary
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (mounted) {
      setState(() {
        _consents = {
          'dataProcessing': dataProcessing,
          'marketing': marketing,
          'locationTracking': locationTracking,
          'analyticsTracking': analyticsTracking,
        };
        _userData = userDoc.data();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleConsent(String type, bool value) async {
    try {
      if (value) {
        await _consentManager.grantConsent(type);
      } else {
        await _consentManager.revokeConsent(type);
      }
      setState(() {
        _consents[type] = value;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update consent: $e')),
      );
    }
  }

  Future<void> _requestAccountDeletion() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to request account deletion? This action cannot be undone and will take up to 30 days to process.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _firestore.collection('deletion_requests').doc(uid).set({
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deletion request submitted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Data Rights')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Data Rights')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAccessSection(),
          const Divider(),
          _buildConsentSection(),
          const Divider(),
          _buildActionSection(),
        ],
      ),
    );
  }

  Widget _buildAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Access My Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Summary of data we hold:'),
        const SizedBox(height: 8),
        if (_userData != null) ...[
          Text('Username: ${_userData!['username'] ?? 'N/A'}'),
          Text('Email: ${_userData!['email'] ?? 'N/A'}'),
          Text('Phone: ${_userData!['phone'] ?? 'N/A'}'),
          Text('Bio: ${_userData!['bio'] ?? 'N/A'}'),
        ] else
          const Text('No data found.'),
      ],
    );
  }

  Widget _buildConsentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manage Consents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Data Processing'),
          subtitle: const Text('Allow processing of your personal data for app functionality.'),
          value: _consents['dataProcessing']!,
          onChanged: (val) => _toggleConsent('dataProcessing', val),
        ),
        SwitchListTile(
          title: const Text('Marketing'),
          subtitle: const Text('Receive promotional offers and updates.'),
          value: _consents['marketing']!,
          onChanged: (val) => _toggleConsent('marketing', val),
        ),
        SwitchListTile(
          title: const Text('Location Tracking'),
          subtitle: const Text('Allow app to use your precise location.'),
          value: _consents['locationTracking']!,
          onChanged: (val) => _toggleConsent('locationTracking', val),
        ),
        SwitchListTile(
          title: const Text('Analytics Tracking'),
          subtitle: const Text('Help us improve the app by sharing usage data.'),
          value: _consents['analyticsTracking']!,
          onChanged: (val) => _toggleConsent('analyticsTracking', val),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Correct My Data'),
          subtitle: const Text('Update your profile information.'),
          onTap: () {
            // Navigate to Edit Profile (assuming route name or just push back)
            Navigator.pop(context); // Go back or to edit profile
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Delete My Account'),
          subtitle: const Text('Submit a request to permanently delete your account.'),
          onTap: _requestAccountDeletion,
        ),
        ListTile(
          leading: const Icon(Icons.gavel),
          title: const Text('File a Grievance'),
          subtitle: const Text('Contact our Grievance Officer.'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GrievanceOfficerPage()),
            );
          },
        ),
      ],
    );
  }
}
