void _sharePost() async {
  if (postTitle.isEmpty || postContent.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please fill in both title and content!')),
    );
    return;
  }

  var theme = themes[selectedTheme];

  String? branchLink = await BranchRestAPI.createBranchLink(
    title: '${theme['emoji']} $postTitle',
    description: postContent,
    campaignKey: 'test_flutter_demo',
    customData: {
      'template_type': 'social_sharing',
      'post_title': postTitle,
      'post_content': postContent,
      'theme': selectedTheme,
      'theme_name': theme['name'],
      'theme_emoji': theme['emoji'],
      'social_post': true,
    },
  );

  if (branchLink != null) {
    await BranchRestAPI.trackCustomEvent(
      eventName: 'social_post_shared',
      customData: {
        'post_title': postTitle,
        'theme': theme['name'],
        'content_length': postContent.length,
        'sharing_method': 'social_template',
      },
    );

    Clipboard.setData(ClipboardData(text: branchLink));
    _showShareDialog(branchLink);
  }
}

void _showShareDialog(String link) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Post Shared! 📱'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your ${themes[selectedTheme]['name']} post is ready to share!'),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              link,
              style: TextStyle(fontSize: 12),
            ),
          ),
          SizedBox(height: 16),
          Text('Link copied to clipboard!', style: TextStyle(color: Colors.green)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Social Sharing Hub'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade300, Colors.purple.shade200],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Theme Selector
              Text(
                'Choose Your Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 15),
              Container(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: themes.length,
                  itemBuilder: (context, index) {
                    var theme = themes[index];
                    return GestureDetector(
                      onTap: () => setState(() => selectedTheme = index),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: selectedTheme == index ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 100,
                              margin: EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                color: selectedTheme == index ? theme['color'] : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: theme['color'],
                                  width: 3,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(theme['emoji'], style: TextStyle(fontSize: 24)),
                                  Text(
                                    theme['name'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selectedTheme == index ? Colors.white : theme['color'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 30),

              // Post Creation Form
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              themes[selectedTheme]['emoji'],
                              style: TextStyle(fontSize: 30),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Post Title',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) => setState(() => postTitle = value),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'What\'s on your mind?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignLabelWithHint: true,
                            ),
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            onChanged: (value) => setState(() => postContent = value),
                          ),
                        ),
                        SizedBox(height: 20),
                        if (postTitle.isNotEmpty && postContent.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: themes[selectedTheme]['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: themes[selectedTheme]['color']),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preview:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themes[selectedTheme]['color'],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '${themes[selectedTheme]['emoji']} $postTitle',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  postContent,
                                  style: TextStyle(fontSize: 14),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Share Button
              Container(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _sharePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themes[selectedTheme]['color'],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    '📱 Share My Post',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

@override
void dispose() {
  _pulseController.dispose();
  super.dispose();
}
}

// Referral System Template
class ReferralSystemTemplate extends StatefulWidget {
  final Map? deepLinkData;

  ReferralSystemTemplate({this.deepLinkData});

  @override
  _ReferralSystemTemplateState createState() => _ReferralSystemTemplateState();
}

class _ReferralSystemTemplateState extends State<ReferralSystemTemplate> with TickerProviderStateMixin {
  String referralCode = '';
  int referralCount = 0;
  double earnedCredits = 0.0;
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateReferralCode();
    _loadFromDeepLink();
  }

  void _setupAnimations() {
    _sparkleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut));
    _sparkleController.repeat();
  }

  void _generateReferralCode() {
    var random = Random();
    referralCode = 'BRANCH${random.nextInt(10000).toString().padLeft(4, '0')}';
  }

  void _loadFromDeepLink() {
    if (widget.deepLinkData != null) {
      // Simulate coming from a referral
      String? referrer = widget.deepLinkData!['referrer'];
      if (referrer != null) {
        _showReferralWelcome(referrer);
      }
    }
  }

  void _showReferralWelcome(String referrer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 Welcome!'),
        content: Text('You\'ve been referred by $referrer! You both get bonus credits!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _simulateReferralReward();
            },
            child: Text('Claim Bonus'),
          ),
        ],
      ),
    );
  }

  void _simulateReferralReward() {
    setState(() {
      earnedCredits += 10.0;
    });
    _sparkleController.forward().then((_) => _sparkleController.reset());
  }

  void _shareReferralLink() async {
    String? branchLink = await BranchRestAPI.createBranchLink(
      title: 'Join JoinFloor with my referral code!',
      description: 'Use my referral code $referralCode and we both get \$10 credit!',
      campaignKey: 'test_flutter_demo',
      customData: {
        'template_type': 'referral_system',
        'referral_code': referralCode,
        'referrer': 'current_user',
        'reward_amount': 10.0,
        'deep_link_path': '/#signup',
      },
    );

    if (branchLink != null) {
      await BranchRestAPI.trackCustomEvent(
        eventName: 'referral_link_shared',
        customData: {
          'referral_code': referralCode,
          'sharing_method': 'branch_link',
          'reward_amount': 10.0,
        },
      );

      Clipboard.setData(ClipboardData(text: branchLink));
      _showShareDialog(branchLink);
    }
  }

  void _showShareDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Referral Link Ready! 💎'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this link and earn \$10 for each friend who signs up!'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                link,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            Text('Link copied to clipboard!', style: TextStyle(color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Referral System'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade300, Colors.pink.shade200],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Referrals',
                        referralCount.toString(),
                        '👥',
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _sparkleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_sparkleAnimation.value * 0.1),
                            child: _buildStatCard(
                              'Earned',
                              '\${earnedCredits.toStringAsFixed(2)}',
                              '💰',
                              Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 30),

                // Referral Code Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: [
                        Text(
                          '💎 Your Referral Code',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.purple, width: 2),
                          ),
                          child: Text(
                            referralCode,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Share this code with friends and earn \$10 for each signup!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 30),

                // How It Works
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Text(
                          'How It Works',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildStep('1', 'Share your referral link', '📤'),
                        _buildStep('2', 'Friend signs up using your link', '👤'),
                        _buildStep('3', 'You both get \$10 credit!', '🎉'),
                      ],
                    ),
                  ),
                ),

                Spacer(),

                // Share Button
                Container(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _shareReferralLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      '🚀 Share Referral Link',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String emoji, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 30)),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String description, String emoji) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Text(emoji, style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }
}

// QR Code Template
class QRCodeTemplate extends StatefulWidget {
  @override
  _QRCodeTemplateState createState() => _QRCodeTemplateState();
}

class _QRCodeTemplateState extends State<QRCodeTemplate> {
  String? generatedLink;
  String qrTitle = '';
  String qrDescription = '';

  void _generateQRLink() async {
    if (qrTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title for your QR code!')),
      );
      return;
    }

    String? branchLink = await BranchRestAPI.createBranchLink(
      title: qrTitle,
      description: qrDescription.isEmpty ? 'Scan this QR code to access content!' : qrDescription,
      campaignKey: 'test_flutter_demo',
      customData: {
        'template_type': 'qr_code',
        'qr_title': qrTitle,
        'qr_description': qrDescription,
        'generated_via': 'qr_template',
      },
    );

    if (branchLink != null) {
      setState(() {
        generatedLink = branchLink;
      });

      await BranchRestAPI.trackCustomEvent(
        eventName: 'qr_code_generated',
        customData: {
          'qr_title': qrTitle,
          'link_url': branchLink,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Generator'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade300, Colors.cyan.shade200],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Text(
                          '📱 QR Code Generator',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'QR Code Title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) => setState(() => qrTitle = value),
                        ),
                        SizedBox(height: 15),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Description (Optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 3,
                          onChanged: (value) => setState(() => qrDescription = value),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _generateQRLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text('Generate QR Link'),
                        ),
                      ],
                    ),
                  ),
                ),

                if (generatedLink != null) ...[
                  SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Text(
                            '✅ QR Link Generated!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code, size: 100, color: Colors.grey),
                                  Text(
                                    'QR Code\n(Use QR library to generate)',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          SelectableText(
                            generatedLink!,
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                          SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: generatedLink!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Link copied to clipboard!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Copy Link'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Analytics Template
class AnalyticsTemplate extends StatefulWidget {
  @override
  _AnalyticsTemplateState createState() => _AnalyticsTemplateState();
}

class _AnalyticsTemplateState extends State<AnalyticsTemplate> with TickerProviderStateMixin {
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _chartController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _chartController, curve: Curves.easeInOut));
    _chartController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade300, Colors.blue.shade200],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Stats Overview
                Row(
                  children: [
                    Expanded(child: _buildAnalyticsCard('Links Created', '147', '🔗', Colors.blue)),
                    SizedBox(width: 15),
                    Expanded(child: _buildAnalyticsCard('Total Clicks', '1,234', '👆', Colors.green)),
                  ],
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildAnalyticsCard('Conversions', '89', '✅', Colors.orange)),
                    SizedBox(width: 15),
                    Expanded(child: _buildAnalyticsCard('Revenue', '\$2,567', '💰', Colors.purple)),
                  ],
                ),

                SizedBox(height: 30),

                // Chart Section
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: Column(
                        children: [
                          Text(
                            '📊 Performance Overview',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          SizedBox(height: 20),
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _chartAnimation,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ChartPainter(_chartAnimation.value),
                                  size: Size(double.infinity, double.infinity),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem('Links', Colors.blue),
                              _buildLegendItem('Clicks', Colors.green),
                              _buildLegendItem('Conversions', Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _chartController.reset();
                          _chartController.forward();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text('Refresh Data'),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await BranchRestAPI.trackCustomEvent(
                            eventName: 'analytics_viewed',
                            customData: {
                              'dashboard_section': 'main_analytics',
                              'view_duration': DateTime.now().millisecondsSinceEpoch,
                            },
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Analytics view tracked!')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text('Track View'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, String emoji, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 30)),
          SizedBox(height: 10),
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
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }
}

// Custom Chart Painter
class ChartPainter extends CustomPainter {
  final double animationValue;

  ChartPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Sample data points
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width, size.height * 0.2),
    ];

    // Draw animated lines
    for (int i = 0; i < 3; i++) {
      paint.color = [Colors.blue, Colors.green, Colors.orange][i];

      final path = Path();
      final adjustedPoints = points.map((point) {
        return Offset(
          point.dx,
          point.dy + (i * 20) - (size.height * 0.1 * i),
        );
      }).toList();

      path.moveTo(adjustedPoints[0].dx, adjustedPoints[0].dy);

      for (int j = 1; j < adjustedPoints.length; j++) {
        final animatedIndex = (adjustedPoints.length * animationValue).floor();
        if (j <= animatedIndex) {
          path.lineTo(adjustedPoints[j].dx, adjustedPoints[j].dy);
        } else if (j == animatedIndex + 1) {
          final progress = (adjustedPoints.length * animationValue) - animatedIndex;
          final currentPoint = adjustedPoints[j - 1];
          final nextPoint = adjustedPoints[j];
          final interpolatedPoint = Offset(
            currentPoint.dx + (nextPoint.dx - currentPoint.dx) * progress,
            currentPoint.dy + (nextPoint.dy - currentPoint.dy) * progress,
          );
          path.lineTo(interpolatedPoint.dx, interpolatedPoint.dy);
          break;
        }
      }

      canvas.drawPath(path, paint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i <= 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}// lib/branch_templates.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'main.dart'; // Import to access BranchRestAPI

// Template Navigator - Main hub for all templates
class TemplateNavigator extends StatefulWidget {
  @override
  _TemplateNavigatorState createState() => _TemplateNavigatorState();
}

class _TemplateNavigatorState extends State<TemplateNavigator> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Branch Demo Templates'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade400, Colors.blue.shade600],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '🚀 Branch SDK Demo Templates',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          children: [
                            _buildTemplateCard(
                              'Character Creator',
                              '🎭',
                              'Create & share characters like Monster Factory',
                              Colors.orange,
                                  () => Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => CharacterCreatorTemplate())),
                            ),
                            _buildTemplateCard(
                              'Product Showcase',
                              '🛍️',
                              'Showcase products with deep links',
                              Colors.green,
                                  () => Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => ProductShowcaseTemplate())),
                            ),
                            _buildTemplateCard(
                              'Social Sharing',
                              '📱',
                              'Advanced social sharing features',
                              Colors.blue,
                                  () => Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => SocialSharingTemplate())),
                            ),
                            _buildTemplateCard(
                              'Referral System',
                              '💎',
                              'Complete referral program',
                              Colors.purple,
                                  () => Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => ReferralSystemTemplate())),
                            ),
                            _buildTemplateCard(
                              'QR Generator',
                              '📱',
                              'Generate QR codes for sharing',
                              Colors.teal,
                                  () => Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => QRCodeTemplate())),
                            ),
                            _buildTemplateCard(
                              'Analytics Dashboard',
                              '📊',
                              'View Branch analytics',
                              Colors.indigo,
                                  () => Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => AnalyticsTemplate())),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String title, String icon, String description, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(icon, style: TextStyle(fontSize: 30)),
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Character Creator Template (Monster Factory style)
class CharacterCreatorTemplate extends StatefulWidget {
  final Map? deepLinkData;

  CharacterCreatorTemplate({this.deepLinkData});

  @override
  _CharacterCreatorTemplateState createState() => _CharacterCreatorTemplateState();
}

class _CharacterCreatorTemplateState extends State<CharacterCreatorTemplate> with TickerProviderStateMixin {
  int selectedBody = 0;
  int selectedFace = 0;
  int selectedColor = 0;
  String characterName = '';
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  final List<String> bodyTypes = ['🤖', '👾', '🦄', '🐲', '🦖', '🐙'];
  final List<String> faceTypes = ['😀', '😎', '🤯', '😈', '🥳', '🤓'];
  final List<Color> colors = [
    Colors.red, Colors.blue, Colors.green,
    Colors.purple, Colors.orange, Colors.pink
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadFromDeepLink();
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .animate(CurvedAnimation(parent: _bounceController, curve: Curves.elasticInOut));
  }

  void _loadFromDeepLink() {
    if (widget.deepLinkData != null) {
      setState(() {
        selectedBody = widget.deepLinkData!['body'] ?? 0;
        selectedFace = widget.deepLinkData!['face'] ?? 0;
        selectedColor = widget.deepLinkData!['color'] ?? 0;
        characterName = widget.deepLinkData!['character_name'] ?? '';
      });
    }
  }

  void _shareCharacter() async {
    if (characterName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please name your character first!')),
      );
      return;
    }

    _bounceController.forward().then((_) => _bounceController.reverse());

    String? branchLink = await BranchRestAPI.createBranchLink(
      title: 'Check out my character: $characterName',
      description: 'I created this awesome character in the Branch Demo app! Come see it!',
      campaignKey: 'test_flutter_demo',
      customData: {
        'template_type': 'character_creator',
        'character_name': characterName,
        'body': selectedBody,
        'face': selectedFace,
        'color': selectedColor,
        'body_emoji': bodyTypes[selectedBody],
        'face_emoji': faceTypes[selectedFace],
        'creator': 'branch_demo_user',
      },
    );

    if (branchLink != null) {
      await BranchRestAPI.trackCustomEvent(
        eventName: 'character_shared',
        customData: {
          'character_name': characterName,
          'sharing_method': 'branch_link',
          'template': 'character_creator',
        },
      );

      // Copy to clipboard and show share dialog
      Clipboard.setData(ClipboardData(text: branchLink));
      _showShareDialog(branchLink);
    }
  }

  void _showShareDialog(String link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Character Shared! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your character "$characterName" is ready to share!'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                link,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            Text('Link copied to clipboard!', style: TextStyle(color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Character Creator'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade300, Colors.yellow.shade200],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Character Display
                Expanded(
                  flex: 2,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _bounceAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: colors[selectedColor].withOpacity(0.3),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: colors[selectedColor], width: 4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  bodyTypes[selectedBody],
                                  style: TextStyle(fontSize: 60),
                                ),
                                Text(
                                  faceTypes[selectedFace],
                                  style: TextStyle(fontSize: 40),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Character Name Input
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Character Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) => setState(() => characterName = value),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Customization Options
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildCustomizationRow('Body', bodyTypes, selectedBody, (index) {
                        setState(() => selectedBody = index);
                        _bounceController.forward().then((_) => _bounceController.reverse());
                      }),
                      SizedBox(height: 15),
                      _buildCustomizationRow('Face', faceTypes, selectedFace, (index) {
                        setState(() => selectedFace = index);
                        _bounceController.forward().then((_) => _bounceController.reverse());
                      }),
                      SizedBox(height: 15),
                      _buildColorRow(),
                    ],
                  ),
                ),

                // Share Button
                Container(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _shareCharacter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      '🚀 Share My Character',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationRow(String title, List<String> options, int selected, Function(int) onTap) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => onTap(index),
                child: Container(
                  width: 60,
                  height: 60,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: selected == index ? Colors.white : Colors.white70,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selected == index ? Colors.orange : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      options[index],
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow() {
    return Column(
      children: [
        Text(
          'Color',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Container(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() => selectedColor = index);
                  _bounceController.forward().then((_) => _bounceController.reverse());
                },
                child: Container(
                  width: 60,
                  height: 60,
                  margin: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: colors[index],
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: selectedColor == index ? Colors.white : Colors.transparent,
                      width: 4,
                    ),
                  ),
                  child: selectedColor == index
                      ? Icon(Icons.check, color: Colors.white, size: 30)
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }
}

// Product Showcase Template
class ProductShowcaseTemplate extends StatefulWidget {
  final Map? deepLinkData;

  ProductShowcaseTemplate({this.deepLinkData});

  @override
  _ProductShowcaseTemplateState createState() => _ProductShowcaseTemplateState();
}

class _ProductShowcaseTemplateState extends State<ProductShowcaseTemplate> {
  int selectedProduct = 0;

  final List<Map<String, dynamic>> products = [
    {
      'name': 'JoinFloor Pro',
      'price': '\$29.99',
      'description': 'Premium workspace collaboration',
      'emoji': '💼',
      'features': ['Advanced Analytics', 'Team Collaboration', 'Priority Support'],
    },
    {
      'name': 'JoinFloor Basic',
      'price': '\$9.99',
      'description': 'Essential workspace tools',
      'emoji': '📝',
      'features': ['Basic Analytics', 'File Sharing', 'Email Support'],
    },
    {
      'name': 'JoinFloor Enterprise',
      'price': '\$99.99',
      'description': 'Complete business solution',
      'emoji': '🏢',
      'features': ['Custom Integration', 'Dedicated Support', 'Advanced Security'],
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.deepLinkData != null) {
      selectedProduct = widget.deepLinkData!['product_index'] ?? 0;
    }
  }

  void _shareProduct() async {
    var product = products[selectedProduct];

    String? branchLink = await BranchRestAPI.createBranchLink(
      title: 'Check out ${product['name']}!',
      description: '${product['description']} - Only ${product['price']}',
      campaignKey: 'test_flutter_demo',
      customData: {
        'template_type': 'product_showcase',
        'product_index': selectedProduct,
        'product_name': product['name'],
        'product_price': product['price'],
        'deep_link_path': '/#pricing-table',
      },
    );

    if (branchLink != null) {
      await BranchRestAPI.trackStandardEvent(
        eventName: 'VIEW_ITEM',
        eventData: {
          'currency': 'USD',
          'revenue': double.parse(product['price'].replaceAll(RegExp(r'[^\d.]'), '')),
          'description': 'Product shared via deep link',
        },
        customData: {
          'product_name': product['name'],
          'sharing_method': 'product_showcase',
        },
      );

      Clipboard.setData(ClipboardData(text: branchLink));
      _showShareDialog(branchLink, product);
    }
  }

  void _showShareDialog(String link, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${product['name']} Shared! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this amazing product with friends!'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                link,
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            Text('Link copied to clipboard!', style: TextStyle(color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var currentProduct = products[selectedProduct];

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Showcase'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade300, Colors.blue.shade200],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Product Selector
                Container(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => setState(() => selectedProduct = index),
                        child: Container(
                          width: 100,
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: selectedProduct == index ? Colors.white : Colors.white70,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedProduct == index ? Colors.green : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(products[index]['emoji'], style: TextStyle(fontSize: 24)),
                              Text(
                                products[index]['name'],
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 30),

                // Product Card
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentProduct['emoji'],
                            style: TextStyle(fontSize: 80),
                          ),
                          SizedBox(height: 20),
                          Text(
                            currentProduct['name'],
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            currentProduct['price'],
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            currentProduct['description'],
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30),
                          Column(
                            children: currentProduct['features'].map<Widget>((feature) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    SizedBox(width: 10),
                                    Text(feature, style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Share Button
                Container(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _shareProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      '🚀 Share This Product',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Social Sharing Template
class SocialSharingTemplate extends StatefulWidget {
  final Map? deepLinkData;

  SocialSharingTemplate({this.deepLinkData});

  @override
  _SocialSharingTemplateState createState() => _SocialSharingTemplateState();
}

class _SocialSharingTemplateState extends State<SocialSharingTemplate> with TickerProviderStateMixin {
  String postTitle = '';
  String postContent = '';
  int selectedTheme = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, dynamic>> themes = [
    {'name': 'Tech', 'color': Colors.blue, 'emoji': '💻'},
    {'name': 'Nature', 'color': Colors.green, 'emoji': '🌿'},
    {'name': 'Food', 'color': Colors.orange, 'emoji': '🍕'},
    {'name': 'Travel', 'color': Colors.purple, 'emoji': '✈️'},
    {'name': 'Fitness', 'color': Colors.red, 'emoji': '💪'},
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadFromDeepLink();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _pulseController.repeat(reverse: true);
  }

  void _loadFromDeepLink() {
    if (widget.deepLinkData != null) {
      setState(() {
        postTitle = widget.deepLinkData!['post_title'] ?? '';
        postContent = widget.deepLinkData!['post_content'] ?? '';
        selectedTheme = widget.deepLinkData!['theme'] ?? 0;
      });
    }
  }