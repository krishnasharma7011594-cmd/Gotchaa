import 'dart:convert';

import 'package:http/http.dart' as http;

// Configuration
const String projectRegion = 'us-central1';
const String projectId = 'studio-1284397718-50704';
const String baseUrl = 'https://$projectRegion-$projectId.cloudfunctions.net';

Future<void> main() async {
  print('🧪 Starting Cloud Functions Smoke Test...');
  
  final List<String> endpoints = [
    'geminiProxy',
    'findVibeMatch',
    'seedDemoData',
    'deleteUserAccount'
  ];

  for (final endpoint in endpoints) {
    await testEndpoint(endpoint);
  }
}

Future<void> testEndpoint(String name) async {
  final url = Uri.parse('$baseUrl/$name');
  
  try {
    print('Checking $name...');
    // Callable functions expect a POST with data: {}
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'data': {}}),
    );

    // We expect a 401 Unauthenticated or 403 Forbidden because we aren't passing a token,
    // but a 404 would mean the function is missing.
    if (response.statusCode == 401 || response.statusCode == 403 || response.statusCode == 400) {
      print('✅ $name: Reachable (Status ${response.statusCode})');
    } else if (response.statusCode == 404) {
      print('❌ $name: NOT FOUND (404)');
    } else {
      print('⚠️ $name: Unexpected Status ${response.statusCode}');
    }
  } catch (e) {
    print('❌ $name: Error - $e');
  }
}
