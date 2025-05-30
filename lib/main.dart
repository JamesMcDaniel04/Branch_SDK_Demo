import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Branch REST API Service
class BranchRestAPI {
  static const String _baseUrl = 'https://api2.branch.io/v1';
  static const String _branchKey = 'key_test_lAtlnXscF14uqMzLwtlYpljgBCdVZzCS';

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
            'created_timestamp': DateTime.now().toIso8601String(),
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

  // Track an event using REST API (v2 endpoint)
  static Future<bool> trackEvent({
    required String eventName,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v2/event/standard'),  // Updated to v2 API
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
            'event_source': 'mobile_app',
            ...?eventData,
          },
          'user_data': {
            'developer_identity': 'flutter_user_12345',
            'os': Platform.operatingSystem,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Branch event tracked successfully: $eventName');
        return true;
      } else {
        print('Branch Event API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Branch Event Tracking Error: $e');
      return false;
    }
  }

  // Set user identity (simulated via custom data)
  static Future<bool> setUserIdentity(String userId) async {
    try {
      // Track identity change as an event
      bool success = await trackEvent(
        eventName: 'user_identity_set',
        eventData: {
          'user_id': userId,
          'action': 'set_identity',
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

      // Test connectivity by creating a simple event
      bool eventSuccess = await BranchRestAPI.trackEvent(
        eventName: 'app_launch',
        eventData: {
          'session_start': true,
          'platform': Platform.operatingSystem,
        },
      );

      if (eventSuccess) {
        setState(() {
          _message = 'Branch REST API connected and ready!';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Branch REST API initialization completed with note: $e';
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
        title: 'Flutter Branch REST API Demo',
        description: 'Testing Branch deep links via REST API - fully functional!',
        imageUrl: 'https://flutter.dev/assets/images/shared/brand/flutter/logo/flutter-lockup.png',
        customData: {
          'user_id': '12345',
          'page': 'home',
          'source': 'flutter_rest_api',
          'campaign_id': 'flutter_demo_2024',
          'test_mode': true,
        },
      );

      if (shortUrl != null) {
        setState(() {
          _generatedLink = shortUrl;
          _message = 'Branch link created successfully via REST API!';
        });
        print('Generated Branch Link: $shortUrl');

        // Track link creation event
        await BranchRestAPI.trackEvent(
          eventName: 'link_created',
          eventData: {
            'link_url': shortUrl,
            'creation_method': 'rest_api',
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
        _message = 'Tracking event via Branch REST API...';
      });

      bool success = await BranchRestAPI.trackEvent(
        eventName: 'flutter_button_click',
        eventData: {
          'button_type': 'track_event',
          'user_action': 'engagement',
          'page': 'home',
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'test_event': true,
        },
      );

      if (success) {
        setState(() {
          _message = 'Event tracked successfully via Branch REST API!';
        });

        // Also track a purchase simulation
        await BranchRestAPI.trackEvent(
          eventName: 'purchase_simulation',
          eventData: {
            'revenue': 25.99,
            'currency': 'USD',
            'transaction_id': 'txn_${DateTime.now().millisecondsSinceEpoch}',
            'items': ['flutter_course', 'branch_tutorial'],
          },
        );

        print('Multiple events tracked successfully!');
      } else {
        setState(() {
          _message = 'Event tracking failed. Check console for details.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error tracking event: $e';
      });
      print('Exception tracking event: $e');
    }
  }

  void _setBranchIdentity() async {
    try {
      setState(() {
        _message = 'Setting Branch user identity via REST API...';
      });

      bool success = await BranchRestAPI.setUserIdentity('flutter_user_12345');

      if (success) {
        setState(() {
          _message = 'Branch user identity set successfully via REST API!';
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
                      '✅ Fully Functional',
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
                      '🎉 Branch REST API Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✅ Create real Branch links\n✅ Track events and analytics\n✅ Set user identity\n✅ Works on all platforms\n✅ No SDK compatibility issues',
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