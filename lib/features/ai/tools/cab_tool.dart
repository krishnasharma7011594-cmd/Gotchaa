import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import 'bro_tool.dart';

class CabTool extends BroTool {
  @override
  String get name => 'book_cab';

  @override
  String get description => 
    'Prepares a cab booking to a specified destination. Supports location names and landmarks.';

  @override
  Map<String, dynamic> get parameters => {
    'destination': 'The destination address or landmark (e.g., Cyber Hub, New Delhi)',
    'suggested_provider': 'Optional: uber, ola, or blusmart',
  };

  @override
  bool get requiresBiometrics => true; // High-risk action

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments) async {
    final destination = arguments['destination'] as String;
    final provider = arguments['suggested_provider']?.toString().toLowerCase() ?? 'uber';

    // In a real app, we would use geocoding here
    // For MVP, we pre-fill a deep link
    
    String url = '';
    if (provider == 'uber') {
      // Basic Uber Deep Link format
      // uber://?action=setPickup&pickup=my_location&dropoff[formatted_address]=DESTINATION
      final encodedDest = Uri.encodeComponent(destination);
      url = 'uber://?action=setPickup&pickup=my_location&dropoff[formatted_address]=$encodedDest';
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      // In BRO's logic, the actual launch would happen after biometric confirmation
      return {
        'status': 'ready',
        'provider': provider,
        'destination': destination,
        'action_url': url,
        'message': 'I have prepared an $provider to $destination. Ready for your confirmation.',
      };
    } else {
      // Fallback to web or error
      return {
        'status': 'error',
        'message': 'I couldn\'t find the $provider app on your device. Would you like me to search for alternatives?',
      };
    }
  }
}
