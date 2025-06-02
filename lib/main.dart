import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Complete Branch REST API Service with Campaign Support
class BranchRestAPI {
  static const String _branchKey = 'key_test_lAtlnXscF14uqMzLwtlYpljgBCdVZzCS';

  // Public getter for branch key (for logging purposes)
  static String get branchKey => _branchKey;

  // Your campaign options
  static const Map<String, String> campaigns = {
    'test_flutter_demo': 'flutter_demo_rest',
    'test_campaign': 'test_campaign',
    'test_campaign_2024': 'test_campaign_2024',
    'live_campaign': 'flutter_demo_campaign', // For when you switch to live key
  };

  // Create a Branch link using REST API with campaign association
  static Future<String?> createBranchLink({
    required String title,
    required String description,
    String? imageUrl,
    Map<String, dynamic>? customData,
    String campaignKey = 'test_flutter_demo', // Default to flutter_demo_rest
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api2.branch.io/v1/url'),
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
            // Let Branch dashboard handle ALL redirects - no URL overrides
            'custom_string': 'Hello from Flutter REST API!',
            'custom_number': 12345,
            'platform': 'flutter_rest_api',
            'created_timestamp': DateTime.now().toIso8601String(),
            ...?customData,
          },
          'tags': ['flutter', 'rest_api', 'mobile'],
          'channel': 'mobile_app',
          'feature': 'sharing',
          'campaign': campaigns[campaignKey] ?? 'flutter_demo_rest',  // Use your actual campaigns
          'stage': 'mobile_test',
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

  // Track standard events using correct v2 API
  static Future<bool> trackStandardEvent({
    required String eventName,
    Map<String, dynamic>? eventData,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api2.branch.io/v2/event/standard'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': eventName,
          'branch_key': _branchKey,
          'user_data': {
            'os': Platform.operatingSystem,
            'os_version': Platform.operatingSystemVersion,
            'environment': 'FULL_APP',
            'developer_identity': 'flutter_user_12345',
            'country': 'US',
            'language': 'en',
            'app_version': '1.0.0',
            'limit_ad_tracking': false,
          },
          'custom_data': {
            'platform': 'flutter_rest_api',
            'timestamp': DateTime.now().toIso8601String(),
            'event_source': 'mobile_app',
            ...?customData,
          },
          'event_data': {
            'description': 'Event tracked via Flutter REST API',
            ...?eventData,
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        print('Branch standard event tracked successfully: $eventName');
        return true;
      } else {
        print('Branch Standard Event API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Branch Standard Event Tracking Error: $e');
      return false;
    }
  }

  // Track custom events using v2 API
  static Future<bool> trackCustomEvent({
    required String eventName,
    Map<String, dynamic>? customData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api2.branch.io/v2/event/custom'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': eventName,
          'branch_key': _branchKey,
          'user_data': {
            'os': Platform.operatingSystem,
            'os_version': Platform.operatingSystemVersion,
            'environment': 'FULL_APP',
            'developer_identity': 'flutter_user_12345',
            'country': 'US',
            'language': 'en',
            'app_version': '1.0.0',
            'limit_ad_tracking': false,
          },
          'custom_data': {
            'platform': 'flutter_rest_api',
            'timestamp': DateTime.now().toIso8601String(),
            'event_source': 'mobile_app',
            ...?customData,
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        print('Branch custom event tracked successfully: $eventName');
        return true;
      } else {
        print('Branch Custom Event API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Branch Custom Event Tracking Error: $e');
      return false;
    }
  }

  // Set user identity using standard event
  static Future<bool> setUserIdentity(String userId) async {
    try {
      bool success = await trackStandardEvent(
        eventName: 'COMPLETE_REGISTRATION',
        eventData: {
          'description': 'User identity set',
        },
        customData: {
          'user_id': userId,
          'action': 'set_identity',
          'registration_method': 'flutter_app',
        },
      );

      if (success) {
        print('User identity set via REST API: $userId');
      }
      return success;
    } catch (e) {
      print('Branch Set Identity Error: $e');
      return false;
    }
  }
}

// Platform Service for checking Branch SDK support
class BranchService {
  static bool get isSupportedPlatform {
    // Since we're using REST API, it works on all platforms!
    return true;
  }

  static String get platformStatus {
    return 'Branch REST API (works on all platforms)';
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Branch REST API Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Branch REST API Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _message = 'Initializing Branch REST API...';
  String? _deepLinkData;
  String? _generatedLink;
  StreamSubscription<Map>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBranch();
  }

  void _initializeBranch() async {
    try {
      setState(() {
        _message = 'Branch REST API initialized successfully!';
      });
      print('Branch REST API: Ready for link creation and event tracking');
      print('Using Branch Key: ${BranchRestAPI.branchKey}');
      print('App Bundle ID: com.example.untitled2');
      print('Expected App ID: 1455926457980179158');

      // Test with app launch event to verify app integration
      bool eventSuccess = await BranchRestAPI.trackStandardEvent(
        eventName: 'COMPLETE_REGISTRATION',
        eventData: {
          'description': 'App launched - testing app integration',
        },
        customData: {
          'session_start': true,
          'platform': Platform.operatingSystem,
          'app_id': '1455926457980179158',
          'bundle_id': 'com.example.untitled2',
        },
      );

      if (eventSuccess) {
        setState(() {
          _message = 'Branch REST API connected and ready! ✅ App integrated';
        });
      } else {
        setState(() {
          _message = 'Branch REST API connected! ✅ Links working, check app integration';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Branch REST API initialization completed: $e';
      });
      print('Branch REST API initialization note: $e');
    }
  }

  void _createBranchLink() async {
    try {
      setState(() {
        _message = 'Creating Branch link via REST API...';
      });

      String? shortUrl = await BranchRestAPI.createBranchLink(
        title: 'JoinFloor App - Pricing Table',  // Real title for your campaign
        description: 'Check out JoinFloor pricing and sign up today!',  // Real description
        imageUrl: 'https://www.joinfloor.app/assets/images/logo.png',  // Your actual logo
        campaignKey: 'test_flutter_demo', // This maps to your flutter_demo_rest campaign
        customData: {
          'user_id': '12345',
          'page': 'pricing',
          'source': 'flutter_mobile_app',
          'campaign_name': 'flutter_demo_rest',  // Your actual campaign
          'referral_source': 'mobile_app',
          'deep_link_path': '/#pricing-table',
          'action': 'view_pricing',
        },
      );

      if (shortUrl != null) {
        setState(() {
          _generatedLink = shortUrl;
          _message = 'Branch link created successfully via REST API!';
        });
        print('Generated Branch Link: $shortUrl');

        // Track link creation event for your campaign
        await BranchRestAPI.trackCustomEvent(
          eventName: 'joinfloor_link_created',
          customData: {
            'link_url': shortUrl,
            'creation_method': 'mobile_app',
            'campaign': 'flutter_demo_rest',
            'link_type': 'pricing_link',
            'source': 'joinfloor_app',
          },
        );
      } else {
        setState(() {
          _message = 'Failed to create Branch link. Check console for details.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error creating Branch link: $e';
      });
      print('Exception creating Branch link: $e');
    }
  }

  void _trackBranchEvent() async {
    try {
      setState(() {
        _message = 'Tracking events via Branch REST API...';
      });

      // Track a standard event for your campaign
      bool standardSuccess = await BranchRestAPI.trackStandardEvent(
        eventName: 'ADD_TO_CART',
        eventData: {
          'currency': 'USD',
          'revenue': 29.99,  // Your actual pricing
          'transaction_id': 'joinfloor_${DateTime.now().millisecondsSinceEpoch}',
          'description': 'JoinFloor pricing interest',
        },
        customData: {
          'campaign': 'flutter_demo_rest',
          'user_action': 'pricing_engagement',
          'page': 'mobile_app',
          'product': 'joinfloor_subscription',
        },
      );

      // Track a custom event for your campaign
      bool customSuccess = await BranchRestAPI.trackCustomEvent(
        eventName: 'joinfloor_app_engagement',
        customData: {
          'campaign': 'flutter_demo_rest',
          'button_name': 'track_events',
          'user_action': 'engagement',
          'page': 'mobile_app',
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'product_interest': 'pricing',
        },
      );

      if (standardSuccess && customSuccess) {
        setState(() {
          _message = 'Events tracked successfully via Branch REST API! ✅';
        });
        print('All events tracked successfully!');
      } else {
        setState(() {
          _message = 'Some events may have failed. Check console for details.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error tracking events: $e';
      });
      print('Exception tracking events: $e');
    }
  }

  void _setBranchIdentity() async {
    try {
      setState(() {
        _message = 'Setting Branch user identity via REST API...';
      });

      bool success = await BranchRestAPI.setUserIdentity('joinfloor_user_12345');

      if (success) {
        setState(() {
          _message = 'Branch user identity set successfully via REST API! ✅';
        });
        print('Branch user identity set successfully');
      } else {
        setState(() {
          _message = 'Failed to set Branch identity. Check console for details.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error setting Branch identity: $e';
      });
      print('Exception setting Branch identity: $e');
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Branch REST API Integration',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),

              // Platform Info
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    Text('Platform: ${Platform.operatingSystem}'),
                    Text(
                      'Branch Implementation: ${BranchService.platformStatus}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '✅ Fully Functional with Fixed APIs',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 20),

              if (_generatedLink != null) ...[
                Text('Generated Branch Link:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.green.shade50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real Branch Link (click to test):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      SelectableText(
                        _generatedLink!,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: _createBranchLink,
                child: Text('Create Real Branch Link'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                ),
              ),
              SizedBox(height: 15),

              ElevatedButton(
                onPressed: _trackBranchEvent,
                child: Text('Track Events via Branch API'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.green,
                ),
              ),
              SizedBox(height: 15),

              ElevatedButton(
                onPressed: _setBranchIdentity,
                child: Text('Set Branch User Identity'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.orange,
                ),
              ),
              SizedBox(height: 30),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '🎉 Complete Branch REST API Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✅ Create real Branch links with custom domains\n✅ Track standard events (PURCHASE, ADD_TO_CART, etc.)\n✅ Track custom events\n✅ Set user identity\n✅ Works on all platforms\n✅ Fixed API endpoints\n✅ No SDK compatibility issues',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}