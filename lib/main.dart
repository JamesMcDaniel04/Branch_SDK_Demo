// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Branch REST API service
class BranchRestAPI {
  static const String _branchKey = 'key_test_lAtlnXscF14uqMzLwtlYpljgBCdVZzCS';

  static String get branchKey => _branchKey;

  static const Map<String, String> campaigns = {
    'creature_creator': 'creature_creator_campaign',
    'creature_sharing': 'creature_sharing_campaign',
    'creature_battle': 'creature_battle_campaign',
    'referral_rewards': 'referral_rewards_campaign',
  };

  static Future<String?> createBranchLink({
    required String title,
    required String description,
    String? imageUrl,
    Map<String, dynamic>? customData,
    String campaignKey = 'creature_creator',
  }) async {
    try {
      final requestBody = {
        'branch_key': _branchKey,
        'data': {
          '\$og_title': title,
          '\$og_description': description,
          if (imageUrl != null) '\$og_image_url': imageUrl,
          'custom_string': 'Hello from Creature Creator!',
          'custom_number': 12345,
          'platform': 'flutter_creature_app',
          'created_timestamp': DateTime.now().toIso8601String(),
          if (customData != null) ...customData,
        },
        'tags': ['creature', 'mobile_app', 'sharing'],
        'channel': 'mobile_app',
        'feature': 'creature_sharing',
        'campaign': campaigns[campaignKey] ?? 'creature_creator_campaign',
        'stage': 'production',
      };

      print('Branch API Request: ${jsonEncode(requestBody)}'); // Debug log

      final response = await http.post(
        Uri.parse('https://api2.branch.io/v1/url'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Branch API Response Status: ${response.statusCode}'); // Debug log
      print('Branch API Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url = data['url'];
        print('Generated Branch URL: $url'); // Debug log
        return url;
      } else {
        print('Branch API Error: ${response.statusCode} - ${response.body}');
        // Return a fallback URL when Branch API fails
        return _generateFallbackLink(title, description, customData);
      }
    } catch (e) {
      print('Branch REST API Error: $e');
      // Return a fallback URL when Branch API fails
      return _generateFallbackLink(title, description, customData);
    }
  }

  // Fallback link generator for when Branch API is unavailable
  static String _generateFallbackLink(String title, String description, Map<String, dynamic>? customData) {
    final encodedTitle = Uri.encodeComponent(title);
    final encodedDescription = Uri.encodeComponent(description);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Create a simple fallback link (you could replace this with your own URL structure)
    return 'https://creaturecreator.app/share?title=$encodedTitle&desc=$encodedDescription&id=$timestamp';
  }

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
            'developer_identity': 'creature_user_${DateTime.now().millisecondsSinceEpoch}',
            'country': 'US',
            'language': 'en',
            'app_version': '1.0.0',
            'limit_ad_tracking': false,
          },
          'custom_data': {
            'platform': 'flutter_creature_app',
            'timestamp': DateTime.now().toIso8601String(),
            'event_source': 'creature_creator',
            ...?customData,
          },
          'event_data': {
            'description': 'Event tracked via Creature Creator App',
            ...?eventData,
          },
        }),
      );

      return response.statusCode == 200 || response.statusCode == 202;
    } catch (e) {
      print('Branch Standard Event Tracking Error: $e');
      return false;
    }
  }

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
            'developer_identity': 'creature_user_${DateTime.now().millisecondsSinceEpoch}',
            'country': 'US',
            'language': 'en',
            'app_version': '1.0.0',
            'limit_ad_tracking': false,
          },
          'custom_data': {
            'platform': 'flutter_creature_app',
            'timestamp': DateTime.now().toIso8601String(),
            'event_source': 'creature_creator',
            ...?customData,
          },
        }),
      );

      return response.statusCode == 200 || response.statusCode == 202;
    } catch (e) {
      print('Branch Custom Event Tracking Error: $e');
      return false;
    }
  }
}

// Monster Save Page - Dedicated page for saving and sharing monsters
class MonsterSavePage extends StatefulWidget {
  final Creature creature;

  const MonsterSavePage({Key? key, required this.creature}) : super(key: key);

  @override
  _MonsterSavePageState createState() => _MonsterSavePageState();
}

class _MonsterSavePageState extends State<MonsterSavePage>
    with TickerProviderStateMixin {
  String? _shareUrl;
  bool _isGeneratingLink = false;
  bool _isSaved = false;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _fadeController.forward();
    _saveMonster();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _saveMonster() async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate save time

    setState(() {
      _isSaved = true;
    });

    // Track save event
    await BranchRestAPI.trackCustomEvent(
      eventName: 'monster_saved',
      customData: {
        'monster_id': widget.creature.id,
        'monster_name': widget.creature.name,
        'save_timestamp': DateTime.now().toIso8601String(),
      },
    );

    // Auto-generate share URL once monster is saved
    await _generateShareUrl();
  }

  Future<void> _generateShareUrl() async {
    setState(() {
      _isGeneratingLink = true;
    });

    try {
      // Create a deep link that directs to this specific monster page
      final shareUrl = await BranchRestAPI.createBranchLink(
        title: 'Check out my monster: ${widget.creature.name}!',
        description: 'I just created ${widget.creature.name} in Monster Factory! '
            'This creature has ${widget.creature.powerLevel} power. Create your own monster!',
        campaignKey: 'creature_sharing',
        customData: {
          // Deep link data to open this specific monster
          'monster_id': widget.creature.id,
          'monster_name': widget.creature.name,
          'monster_data': jsonEncode(widget.creature.toJson()),
          'share_type': 'monster_sharing',
          'creator_id': widget.creature.creatorId,
          'power_level': widget.creature.powerLevel,
          'created_at': widget.creature.createdAt.toIso8601String(),
          // Route information for deep linking
          'route': '/monster/${widget.creature.id}',
          'action': 'view_monster',
          // Open graph data for social sharing
          'og_title': 'Meet ${widget.creature.name}!',
          'og_description': 'A powerful monster with ${widget.creature.powerLevel} power points',
          'og_image_url': 'https://monster-factory.app/monsters/${widget.creature.id}/image',
          // Fallback URL for web
          'fallback_url': 'https://monster-factory.app/monsters/${widget.creature.id}',
          'desktop_url': 'https://monster-factory.app/monsters/${widget.creature.id}',
        },
      );

      setState(() {
        _shareUrl = shareUrl;
        _isGeneratingLink = false;
      });

      if (shareUrl != null) {
        // Track link generation
        await BranchRestAPI.trackStandardEvent(
          eventName: 'SHARE',
          eventData: {
            'description': 'Monster share link generated',
          },
          customData: {
            'monster_id': widget.creature.id,
            'share_url': shareUrl,
            'share_method': 'branch_link',
          },
        );

        print('Generated share URL: $shareUrl'); // Debug log
      } else {
        print('Failed to generate Branch URL - using fallback');
      }

    } catch (e) {
      print('Error in _generateShareUrl: $e');
      setState(() {
        _shareUrl = null;
        _isGeneratingLink = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating share link: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _shareMonster() async {
    // If no URL exists yet, generate one first
    if (_shareUrl == null) {
      await _generateShareUrl();
    }

    if (_shareUrl != null) {
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: _shareUrl!));

      // Update app state
      SimpleProvider.of<CreatureAppState>(context).incrementShares();

      // Track share event
      await BranchRestAPI.trackStandardEvent(
        eventName: 'SHARE',
        eventData: {
          'description': 'Monster shared successfully',
        },
        customData: {
          'monster_id': widget.creature.id,
          'share_url': _shareUrl!,
          'share_method': 'clipboard',
        },
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Monster link copied! Share it with friends to show off ${widget.creature.name}!'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Got it!',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      // Show error if no URL could be generated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create share link. Please try again.'),
          backgroundColor: Colors.red.shade600,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _generateShareUrl(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                            (route) => false,
                      ),
                      icon: Icon(Icons.home, color: Colors.white, size: 28),
                    ),
                    Expanded(
                      child: Text(
                        _isSaved ? 'Monster Saved!' : 'Saving Monster...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the home button
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 20),

                      // Monster Display with Animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    widget.creature.primaryColor.withOpacity(0.3),
                                    Colors.purple.shade800.withOpacity(0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.creature.primaryColor.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(25),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.95),
                                    border: Border.all(
                                      color: widget.creature.primaryColor,
                                      width: 4,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.creature.body} ${widget.creature.eyes} ${widget.creature.mouth} ${widget.creature.accessory}',
                                    style: TextStyle(fontSize: 45),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 25),

                      // Monster Info
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.creature.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.flash_on, color: Colors.amber, size: 18),
                                SizedBox(width: 5),
                                Text(
                                  'Power Level: ${widget.creature.powerLevel}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            if (_isSaved) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  SizedBox(width: 5),
                                  Text(
                                    'Saved to your collection!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Saving...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 25),

                      // Share URL Display (if generated or being generated)
                      if (_shareUrl != null || _isGeneratingLink) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.link, color: Colors.white70, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Share Link:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              if (_isGeneratingLink) ...[
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Generating share link...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (_shareUrl != null) ...[
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _shareUrl!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Link copied to clipboard!'),
                                        backgroundColor: Colors.green.shade600,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _shareUrl!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontFamily: 'monospace',
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.copy, color: Colors.white70, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],

                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Share Button Section
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Main Share Button
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaved ? _shareMonster : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSaved ? Colors.pink.shade600 : Colors.grey.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 8,
                          shadowColor: Colors.pink.shade600.withOpacity(0.4),
                        ),
                        child: _isGeneratingLink
                            ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Creating Share Link...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 8),
                            Text(
                              _shareUrl != null ? 'Copy & Share Monster' : 'Share Your Monster',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // Secondary Actions
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/creator'),
                            icon: Icon(Icons.add_circle_outline, color: Colors.white70, size: 18),
                            label: Text(
                              'Create Another',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/gallery'),
                            icon: Icon(Icons.photo_library_outlined, color: Colors.white70, size: 18),
                            label: Text(
                              'View Collection',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
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

// Monster View Page - For viewing shared monsters via deep links
class MonsterViewPage extends StatelessWidget {
  final Creature creature;

  const MonsterViewPage({Key? key, required this.creature}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                          (route) => false,
                    ),
                    icon: Icon(Icons.home, color: Colors.white, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      'Shared Monster',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Monster Display
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          creature.primaryColor.withOpacity(0.3),
                          Colors.purple.shade800.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: creature.primaryColor.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.95),
                          border: Border.all(
                            color: creature.primaryColor,
                            width: 4,
                          ),
                        ),
                        child: Text(
                          '${creature.body} ${creature.eyes} ${creature.mouth} ${creature.accessory}',
                          style: TextStyle(fontSize: 60),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Monster Info
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 40),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          creature.name,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flash_on, color: Colors.amber, size: 20),
                            SizedBox(width: 5),
                            Text(
                              'Power Level: ${creature.powerLevel}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Created by a Monster Factory user',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/creator'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.create, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Create Your Own Monster',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/gallery'),
                    icon: Icon(Icons.photo_library_outlined, color: Colors.white70),
                    label: Text(
                      'View More Monsters',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Gallery Screen
class CreatureGalleryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = SimpleProvider.of<CreatureAppState>(context);

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('Creature Gallery'),
        backgroundColor: Colors.purple.shade600,
      ),
      body: state.myCreatures.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 80, color: Colors.grey.shade400),
            SizedBox(height: 20),
            Text(
              'No creatures created yet',
              style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/creator'),
              child: Text('Create Your First Creature'),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: state.myCreatures.length,
        itemBuilder: (context, index) {
          final creature = state.myCreatures[index];
          return Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${creature.body} ${creature.eyes} ${creature.mouth} ${creature.accessory}',
                    style: TextStyle(fontSize: 40),
                  ),
                  SizedBox(height: 8),
                  Text(
                    creature.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text('Power: ${creature.powerLevel}'),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/creator'),
        child: Icon(Icons.add),
      ),
    );
  }
}

// Battle Screen
class CreatureBattleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: Text('Battle Arena'),
        backgroundColor: Colors.red.shade600,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_mma, size: 100, color: Colors.red.shade400),
            SizedBox(height: 20),
            Text(
              'Battle Arena',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Battle feature coming soon!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// Analytics Screen
class AnalyticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = SimpleProvider.of<CreatureAppState>(context);

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Analytics'),
        backgroundColor: Colors.indigo.shade600,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.analytics, size: 60, color: Colors.indigo),
                    SizedBox(height: 10),
                    Text(
                      'Branch SDK Analytics',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${state.myCreatures.length}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text('Creatures Created'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${state.totalShares}',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text('Total Shares'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Rewards Screen
class RewardsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = SimpleProvider.of<CreatureAppState>(context);

    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        title: Text('Rewards Center'),
        backgroundColor: Colors.amber.shade600,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.monetization_on, size: 60, color: Colors.amber),
                    SizedBox(height: 10),
                    Text(
                      '${state.rewardPoints}',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text('Reward Points'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Earn Points:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('• Create creatures: +10 points'),
                    Text('• Share creatures: +5 points'),
                    Text('• Invite friends: +50 points'),
                    Text('• Win battles: +15 points'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String? referralLink = await BranchRestAPI.createBranchLink(
                  title: 'Join me in Creature Creator!',
                  description: 'Create amazing creatures and battle with friends!',
                  campaignKey: 'referral_rewards',
                  customData: {
                    'referral_type': 'friend_invite',
                    'referrer_id': state.currentUserId,
                    'bonus_points': 50,
                  },
                );

                if (referralLink != null) {
                  await Clipboard.setData(ClipboardData(text: referralLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Referral link copied! Share to earn 50 points per friend!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  state.incrementReferrals();

                  await BranchRestAPI.trackStandardEvent(
                    eventName: 'INVITE',
                    eventData: {
                      'description': 'Referral link shared',
                    },
                    customData: {
                      'referral_link': referralLink,
                      'expected_reward': 50,
                    },
                  );
                }
              },
              child: Text('Generate Referral Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Monster Not Found Page - For when deep link monster doesn't exist locally
class MonsterNotFoundPage extends StatelessWidget {
  final String monsterId;

  const MonsterNotFoundPage({Key? key, required this.monsterId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                          (route) => false,
                    ),
                    icon: Icon(Icons.home, color: Colors.white, size: 28),
                  ),
                  Expanded(
                    child: Text(
                      'Monster Factory',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mystery Monster Icon
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.purple.shade800.withOpacity(0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.95),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 4,
                          ),
                        ),
                        child: Text(
                          '👻❓🎭❔',
                          style: TextStyle(fontSize: 50),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Message
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 40),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Monster Not Found',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'The monster you\'re looking for isn\'t available right now. But don\'t worry - you can create your own amazing monster!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Monster ID: $monsterId',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        // Track deep link conversion
                        BranchRestAPI.trackStandardEvent(
                          eventName: 'VIEW_ITEM',
                          eventData: {
                            'description': 'Deep link converted to monster creation',
                          },
                          customData: {
                            'source_monster_id': monsterId,
                            'conversion_type': 'create_new_monster',
                          },
                        );
                        Navigator.pushNamed(context, '/creator');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.create, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Create Your Own Monster',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pushNamed(context, '/gallery'),
                          icon: Icon(Icons.photo_library_outlined, color: Colors.white70),
                          label: Text(
                            'Browse Gallery',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                                (route) => false,
                          ),
                          icon: Icon(Icons.home_outlined, color: Colors.white70),
                          label: Text(
                            'Go Home',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Creature Model
class Creature {
  final String id;
  final String name;
  final String body;
  final String eyes;
  final String mouth;
  final String accessory;
  final Color primaryColor;
  final Color secondaryColor;
  final DateTime createdAt;
  final int powerLevel;
  final String creatorId;

  Creature({
    required this.id,
    required this.name,
    required this.body,
    required this.eyes,
    required this.mouth,
    required this.accessory,
    required this.primaryColor,
    required this.secondaryColor,
    required this.createdAt,
    required this.powerLevel,
    required this.creatorId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'body': body,
      'eyes': eyes,
      'mouth': mouth,
      'accessory': accessory,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'createdAt': createdAt.toIso8601String(),
      'powerLevel': powerLevel,
      'creatorId': creatorId,
    };
  }
}

// App State Management
class CreatureAppState extends ChangeNotifier {
  List<Creature> _myCreatures = [];
  String _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  int _totalShares = 0;
  int _totalReferrals = 0;
  int _rewardPoints = 0;

  List<Creature> get myCreatures => _myCreatures;
  String get currentUserId => _currentUserId;
  int get totalShares => _totalShares;
  int get totalReferrals => _totalReferrals;
  int get rewardPoints => _rewardPoints;

  void addCreature(Creature creature) {
    _myCreatures.add(creature);
    _rewardPoints += 10;
    notifyListeners();
  }

  void incrementShares() {
    _totalShares++;
    _rewardPoints += 5;
    notifyListeners();
  }

  void incrementReferrals() {
    _totalReferrals++;
    _rewardPoints += 50;
    notifyListeners();
  }
}

// Simple Provider Implementation
class SimpleProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function() create;
  final Widget child;

  const SimpleProvider({
    Key? key,
    required this.create,
    required this.child,
  }) : super(key: key);

  @override
  _SimpleProviderState<T> createState() => _SimpleProviderState<T>();

  static T of<T>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_InheritedProvider<T>>();
    if (provider == null) {
      throw Exception('Provider<$T> not found in context');
    }
    return provider.notifier;
  }
}

class _SimpleProviderState<T extends ChangeNotifier> extends State<SimpleProvider<T>> {
  late T _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = widget.create();
    _notifier.addListener(_listener);
  }

  void _listener() {
    setState(() {});
  }

  @override
  void dispose() {
    _notifier.removeListener(_listener);
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedProvider<T>(
      notifier: _notifier,
      child: widget.child,
    );
  }
}

class _InheritedProvider<T> extends InheritedWidget {
  final T notifier;

  const _InheritedProvider({
    Key? key,
    required this.notifier,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

void main() {
  runApp(CreatureCreatorApp());
}

class CreatureCreatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SimpleProvider<CreatureAppState>(
      create: () => CreatureAppState(),
      child: MaterialApp(
        title: 'Creature Creator',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
        routes: {
          '/home': (context) => HomeScreen(),
          '/creator': (context) => CreatureCreatorScreen(),
          '/gallery': (context) => CreatureGalleryScreen(),
          '/battle': (context) => CreatureBattleScreen(),
          '/rewards': (context) => RewardsScreen(),
          '/analytics': (context) => AnalyticsScreen(),
        },
        // Handle deep link routing for monster sharing
        onGenerateRoute: (settings) {
          // Handle monster view routes from deep links
          if (settings.name?.startsWith('/monster/') == true) {
            final monsterId = settings.name?.split('/')[2];
            if (monsterId != null) {
              // In a real app, you'd fetch the monster data from your backend
              // For now, we'll create a sample monster or redirect to creator
              return MaterialPageRoute(
                builder: (context) => MonsterNotFoundPage(monsterId: monsterId),
                settings: settings,
              );
            }
          }

          // Handle other dynamic routes
          return null;
        },
      ),
    );
  }
}

// Splash Screen
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize Branch and track app launch
    await BranchRestAPI.trackStandardEvent(
      eventName: 'COMPLETE_REGISTRATION',
      eventData: {
        'description': 'Creature Creator App Launched',
      },
      customData: {
        'app_launch': true,
        'platform': Platform.operatingSystem,
        'session_start': DateTime.now().toIso8601String(),
      },
    );

    // Navigate to home after 3 seconds
    await Future.delayed(Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.purple.shade300, Colors.pink.shade300],
                ),
              ),
              child: Icon(
                Icons.pets,
                size: 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            Text(
              'Creature Creator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Powered by Branch SDK',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = SimpleProvider.of<CreatureAppState>(context);

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('Creature Creator'),
        backgroundColor: Colors.purple.shade600,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () => Navigator.pushNamed(context, '/analytics'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.pink.shade400],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.pets, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      'Welcome to Creature Creator!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create, Share, and Battle amazing creatures with friends',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'My Creatures',
                    state.myCreatures.length.toString(),
                    Icons.pets,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Reward Points',
                    state.rewardPoints.toString(),
                    Icons.star,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Shares',
                    state.totalShares.toString(),
                    Icons.share,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    'Referrals',
                    state.totalReferrals.toString(),
                    Icons.people,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Action Buttons
            _buildActionButton(
              'Create New Creature',
              'Design your unique creature',
              Icons.add_circle,
              Colors.purple.shade600,
                  () => Navigator.pushNamed(context, '/creator'),
            ),
            SizedBox(height: 12),
            _buildActionButton(
              'Creature Gallery',
              'View and manage your creatures',
              Icons.photo_library,
              Colors.blue.shade600,
                  () => Navigator.pushNamed(context, '/gallery'),
            ),
            SizedBox(height: 12),
            _buildActionButton(
              'Battle Arena',
              'Challenge friends to creature battles',
              Icons.sports_mma,
              Colors.red.shade600,
                  () => Navigator.pushNamed(context, '/battle'),
            ),
            SizedBox(height: 12),
            _buildActionButton(
              'Rewards Center',
              'Claim your sharing rewards',
              Icons.card_giftcard,
              Colors.orange.shade600,
                  () => Navigator.pushNamed(context, '/rewards'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 40),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Creature Creator Screen
class CreatureCreatorScreen extends StatefulWidget {
  @override
  _CreatureCreatorScreenState createState() => _CreatureCreatorScreenState();
}

class _CreatureCreatorScreenState extends State<CreatureCreatorScreen> {
  final TextEditingController _nameController = TextEditingController();

  String _selectedBody = '🐸';
  String _selectedEyes = '👁️';
  String _selectedMouth = '😊';
  String _selectedAccessory = '🎩';
  Color _primaryColor = Colors.green;

  bool _isCreating = false;
  String? _shareLink;

  final List<String> _bodies = ['🐸', '🐱', '🐶', '🐰', '🦊', '🐨', '🐻', '🐼'];
  final List<String> _eyes = ['👁️', '👀', '😊', '😎', '🤔', '😴', '🤯', '🥴'];
  final List<String> _mouths = ['😊', '😄', '😆', '🤣', '😂', '🙃', '😋', '🤪'];
  final List<String> _accessories = ['🎩', '👑', '🎪', '🎭', '🎯', '🎲', '🎸', '🎺'];
  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.pink, Colors.cyan, Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    BranchRestAPI.trackCustomEvent(
      eventName: 'creature_creator_opened',
      customData: {
        'screen': 'creature_creator',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _randomizeCreature() {
    setState(() {
      _selectedBody = _bodies[math.Random().nextInt(_bodies.length)];
      _selectedEyes = _eyes[math.Random().nextInt(_eyes.length)];
      _selectedMouth = _mouths[math.Random().nextInt(_mouths.length)];
      _selectedAccessory = _accessories[math.Random().nextInt(_accessories.length)];
      _primaryColor = _colors[math.Random().nextInt(_colors.length)];
      _shareLink = null;
    });

    BranchRestAPI.trackCustomEvent(
      eventName: 'creature_randomized',
      customData: {
        'action': 'randomize_creature',
        'body': _selectedBody,
        'eyes': _selectedEyes,
        'mouth': _selectedMouth,
        'accessory': _selectedAccessory,
      },
    );
  }

  Future<void> _createCreature() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please give your creature a name!'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final creature = Creature(
        id: 'creature_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        body: _selectedBody,
        eyes: _selectedEyes,
        mouth: _selectedMouth,
        accessory: _selectedAccessory,
        primaryColor: _primaryColor,
        secondaryColor: Colors.blue,
        createdAt: DateTime.now(),
        powerLevel: math.Random().nextInt(100) + 1,
        creatorId: SimpleProvider.of<CreatureAppState>(context).currentUserId,
      );

      // Add creature to state
      SimpleProvider.of<CreatureAppState>(context).addCreature(creature);

      // Track creation event
      await BranchRestAPI.trackStandardEvent(
        eventName: 'ADD_TO_CART',
        eventData: {
          'description': 'Creature created successfully',
          'content_items': [
            {
              'name': creature.name,
              'sku': creature.id,
              'category': 'creatures',
              'quantity': 1,
              'price': 0.0,
            }
          ],
        },
        customData: {
          'creature_id': creature.id,
          'creature_name': creature.name,
          'power_level': creature.powerLevel,
          'creation_method': 'manual_design',
        },
      );

      setState(() {
        _isCreating = false;
      });

      // Navigate to the monster save page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MonsterSavePage(creature: creature),
        ),
      );

    } catch (e) {
      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating creature: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('Create Your Creature'),
        backgroundColor: Colors.purple.shade600,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _randomizeCreature,
            icon: Icon(Icons.shuffle),
            tooltip: 'Randomize',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Creature Preview
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade200,
                      _primaryColor.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      '$_selectedBody $_selectedEyes $_selectedMouth $_selectedAccessory',
                      style: TextStyle(fontSize: 50),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Creature Name Input
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creature Name',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Give your creature a magical name...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.edit, color: Colors.purple.shade400),
                      ),
                      maxLength: 20,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Body Selection
            _buildSelectionSection(
              'Body',
              _bodies,
              _selectedBody,
                  (value) => setState(() => _selectedBody = value),
              Colors.blue,
            ),
            SizedBox(height: 15),

            // Eyes Selection
            _buildSelectionSection(
              'Eyes',
              _eyes,
              _selectedEyes,
                  (value) => setState(() => _selectedEyes = value),
              Colors.green,
            ),
            SizedBox(height: 15),

            // Mouth Selection
            _buildSelectionSection(
              'Mouth',
              _mouths,
              _selectedMouth,
                  (value) => setState(() => _selectedMouth = value),
              Colors.orange,
            ),
            SizedBox(height: 15),

            // Accessory Selection
            _buildSelectionSection(
              'Accessory',
              _accessories,
              _selectedAccessory,
                  (value) => setState(() => _selectedAccessory = value),
              Colors.red,
            ),
            SizedBox(height: 15),

            // Color Selection
            _buildColorSection(),
            SizedBox(height: 30),

            // Create Button
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: InkWell(
                onTap: _isCreating ? null : _createCreature,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: _isCreating
                          ? [Colors.grey, Colors.grey.shade400]
                          : [Colors.purple.shade600, Colors.pink.shade600],
                    ),
                  ),
                  child: Center(
                    child: _isCreating
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 15),
                        Text(
                          'Creating Your Creature...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.create, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Create & Share Creature',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSection(
      String title,
      List<String> options,
      String selectedValue,
      Function(String) onSelected,
      Color accentColor,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((option) {
                bool isSelected = option == selectedValue;
                return GestureDetector(
                  onTap: () => onSelected(option),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? accentColor.withOpacity(0.2) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? accentColor : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Primary Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                bool isSelected = color == _primaryColor;
                return GestureDetector(
                  onTap: () => setState(() => _primaryColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}