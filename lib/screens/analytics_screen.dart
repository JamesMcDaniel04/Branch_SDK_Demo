// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  bool _isRefreshing = false;
  String _selectedPeriod = '7 days';
  final List<String> _periods = ['1 day', '7 days', '30 days', '90 days'];

  // Mock analytics data
  Map<String, dynamic> _analyticsData = {
    'total_creatures': 0,
    'total_shares': 0,
    'total_battles': 0,
    'link_clicks': 0,
    'new_users': 0,
    'retention_rate': 0.0,
  };

  @override
  void initState() {
    super.initState();

    _refreshController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _refreshAnimation = CurvedAnimation(
      parent: _refreshController,
      curve: Curves.elasticOut,
    );

    _loadAnalyticsData();

    // Track analytics view
    BranchRestAPI.trackCustomEvent(
      eventName: 'analytics_dashboard_opened',
      customData: {
        'screen': 'analytics_dashboard',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isRefreshing = true;
    });

    _refreshController.forward();

    // Simulate API call to load analytics data
    await Future.delayed(Duration(seconds: 2));

    final state = ChangeNotifierProvider.of<CreatureAppState>(context);

    setState(() {
      _analyticsData = {
        'total_creatures': state.myCreatures.length + state.discoveredCreatures.length,
        'total_shares': state.totalShares,
        'total_battles': Random().nextInt(50) + state.totalShares * 2,
        'link_clicks': state.totalShares * Random().nextInt(5) + Random().nextInt(100),
        'new_users': Random().nextInt(20) + 5,
        'retention_rate': 0.65 + (Random().nextDouble() * 0.3), // 65-95%
      };
      _isRefreshing = false;
    });

    _refreshController.reset();

    // Track analytics refresh
    await BranchRestAPI.trackCustomEvent(
      eventName: 'analytics_refreshed',
      customData: {
        'period': _selectedPeriod,
        'data_points_loaded': _analyticsData.length,
      },
    );
  }

  Future<void> _exportAnalytics() async {
    // Track export action
    await BranchRestAPI.trackStandardEvent(
      eventName: 'VIEW_ITEM',
      eventData: {
        'description': 'Analytics data exported',
      },
      customData: {
        'export_type': 'analytics',
        'period': _selectedPeriod,
        'total_metrics': _analyticsData.length,
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.download, color: Colors.white),
            SizedBox(width: 10),
            Text('Analytics exported successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: Text('Analytics Dashboard'),
        backgroundColor: Colors.indigo.shade600,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _exportAnalytics,
            icon: Icon(Icons.download),
            tooltip: 'Export Data',
          ),
          IconButton(
            onPressed: _isRefreshing ? null : _loadAnalyticsData,
            icon: AnimatedBuilder(
              animation: _refreshAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshAnimation.value * 2 * pi,
                  child: Icon(Icons.refresh),
                );
              },
            ),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade400, Colors.purple.shade400],
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.analytics, size: 50, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        'Branch SDK Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Real-time insights from Branch tracking',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Period Selector
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Period',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _periods.map((period) {
                          bool isSelected = period == _selectedPeriod;
                          return FilterChip(
                            label: Text(period),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedPeriod = period;
                                });
                                _loadAnalyticsData();
                              }
                            },
                            selectedColor: Colors.indigo.shade100,
                            checkmarkColor: Colors.indigo.shade600,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Key Metrics Grid
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildMetricCard(
                    'Total Creatures',
                    _analyticsData['total_creatures'].toString(),
                    Icons.pets,
                    Colors.blue,
                    '+${Random().nextInt(5) + 1} this week',
                  ),
                  _buildMetricCard(
                    'Total Shares',
                    _analyticsData['total_shares'].toString(),
                    Icons.share,
                    Colors.green,
                    '${((_analyticsData['total_shares'] as int) * 0.15).toInt()} via Branch',
                  ),
                  _buildMetricCard(
                    'Link Clicks',
                    _analyticsData['link_clicks'].toString(),
                    Icons.link,
                    Colors.orange,
                    '${((_analyticsData['link_clicks'] as int) * 0.3).toInt()}% CTR',
                  ),
                  _buildMetricCard(
                    'New Users',
                    _analyticsData['new_users'].toString(),
                    Icons.person_add,
                    Colors.purple,
                    'From Branch links',
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Detailed Analytics Cards
              _buildDetailedAnalyticsCard(),
              SizedBox(height: 16),
              _buildBranchTrackingCard(),
              SizedBox(height: 16),
              _buildCampaignPerformanceCard(),
              SizedBox(height: 16),
              _buildUserJourneyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalyticsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.indigo.shade600),
                SizedBox(width: 10),
                Text(
                  'Engagement Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildAnalyticsRow('User Retention Rate',
                '${(_analyticsData['retention_rate'] * 100).toInt()}%',
                Colors.green),
            _buildAnalyticsRow('Avg. Battle Sessions',
                '${(_analyticsData['total_battles'] / math.max(1, _analyticsData['total_creatures'])).toStringAsFixed(1)}',
                Colors.orange),
            _buildAnalyticsRow('Share Conversion Rate',
                '${((_analyticsData['total_shares'] / math.max(1, _analyticsData['total_creatures'])) * 100).toInt()}%',
                Colors.blue),
            _buildAnalyticsRow('Link Performance Score',
                '${85 + Random().nextInt(15)}%',
                Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchTrackingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, color: Colors.green.shade600),
                SizedBox(width: 10),
                Text(
                  'Branch Event Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildTrackingEventRow('creature_created', '${_analyticsData['total_creatures']}', 'Custom Event'),
            _buildTrackingEventRow('SHARE', '${_analyticsData['total_shares']}', 'Standard Event'),
            _buildTrackingEventRow('creature_battle_started', '${_analyticsData['total_battles']}', 'Custom Event'),
            _buildTrackingEventRow('PURCHASE', '${(_analyticsData['total_battles'] * 0.6).toInt()}', 'Standard Event'),
            SizedBox(height: 15),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'All events are being tracked successfully via Branch REST API',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildCampaignPerformanceCard() {
    final campaigns = [
      {'name': 'creature_creator', 'performance': 92, 'clicks': Random().nextInt(200) + 50},
      {'name': 'creature_sharing', 'performance': 87, 'clicks': Random().nextInt(150) + 30},
      {'name': 'creature_battle', 'performance': 78, 'clicks': Random().nextInt(100) + 20},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: Colors.orange.shade600),
                SizedBox(width: 10),
                Text(
                  'Campaign Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ...campaigns.map((campaign) => _buildCampaignRow(
              campaign['name'] as String,
              campaign['performance'] as int,
              campaign['clicks'] as int,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserJourneyCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: Colors.purple.shade600),
                SizedBox(width: 10),
                Text(
                  'User Journey Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildJourneyStep('1. App Install', '${_analyticsData['new_users']}', Icons.download),
            _buildJourneyStep('2. First Creature Created', '${(_analyticsData['new_users'] * 0.8).toInt()}', Icons.create),
            _buildJourneyStep('3. First Share', '${(_analyticsData['new_users'] * 0.6).toInt()}', Icons.share),
            _buildJourneyStep('4. First Battle', '${(_analyticsData['new_users'] * 0.4).toInt()}', Icons.sports_mma),
            _buildJourneyStep('5. Became Active User', '${(_analyticsData['new_users'] * 0.3).toInt()}', Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingEventRow(String eventName, String count, String type) {
    Color typeColor = type == 'Standard Event' ? Colors.blue : Colors.green;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: typeColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              eventName,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 10,
                color: typeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 10),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignRow(String name, int performance, int clicks) {
    Color performanceColor = performance >= 90 ? Colors.green :
    performance >= 80 ? Colors.orange : Colors.red;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '$clicks clicks',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: performance / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(performanceColor),
                ),
              ),
              SizedBox(width: 10),
              Text(
                '$performance%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: performanceColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep(String step, String count, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.purple.shade400),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              step,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}