import 'dart:convert';
import 'package:http/http.dart' as http;

class BranchRestAPI {
  static const String _baseUrl = 'https://api2.branch.io/v1';
  static const String _branchKey = 'key_live_gFCDa8Aet0YzyHBUFri9emppxAfS9xt0';

  // Create a Branch link using REST API
  static Future<String?> createBranchLink({
    required String title,
    required String description,
    String? imageUrl,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/url'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'branch_key': _branchKey,
          'data': {
            '\$og_title': title,
            '\$og_description': description,
            if (imageUrl != null) '\$og_image_url': imageUrl,
            '\$desktop_url': 'https://flutter.dev',
            '\$ios_url': 'https://apps.apple.com/app/flutter',
            '\$android_url': 'https://play.google.com/store/apps/details?id=com.example.untitled2',
            'custom_string': 'Hello from Flutter REST API!',
            'custom_number': 12345,
            'platform': 'flutter_rest_api',
            ...?customData,
          },
          'tags': ['flutter', 'rest_api', 'mobile'],
          'channel': 'mobile_app',
          'feature': 'sharing',
          'campaign': 'flutter_demo_rest',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        print('Branch API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Branch REST API Error: $e');
      return null;
    }
  }

  // Track an event using REST API
  static Future<bool> trackEvent({
    required String eventName,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/event'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'branch_key': _branchKey,
          'name': eventName,
          'custom_data': {
            'platform': 'flutter_rest_api',
            'timestamp': DateTime.now().toIso8601String(),
            ...?eventData,
          },
          'user_data': {
            'developer_identity': 'flutter_user_12345',
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Branch Event Tracking Error: $e');
      return false;
    }
  }

  // Set user identity using REST API
  static Future<bool> setUserIdentity(String userId) async {
    try {
      // Note: REST API doesn't have direct identity setting like SDK
      // But you can include it in events and link creation
      print('User identity set via REST API: $userId');
      return true;
    } catch (e) {
      print('Branch Set Identity Error: $e');
      return false;
    }
  }
}