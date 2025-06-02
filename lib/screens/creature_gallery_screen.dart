// lib/screens/creature_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CreatureGalleryScreen extends StatefulWidget {
  @override
  _CreatureGalleryScreenState createState() => _CreatureGalleryScreenState();
}

class _CreatureGalleryScreenState extends State<CreatureGalleryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    });

    // Track gallery view
    BranchRestAPI.trackCustomEvent(
      eventName: 'creature_gallery_opened',
      customData: {
        'screen': 'creature_gallery',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _shareCreature(Creature creature) async {
    // Create a new Branch link for this specific creature
    String? shareLink = await BranchRestAPI.createBranchLink(
      title: 'Check out ${creature.name}!',
      description: 'Look at this amazing creature I created in Creature Creator! Power Level: ${creature.powerLevel}',
      campaignKey: 'creature_sharing',
      customData: {
        'creature_id': creature.id,
        'creature_name': creature.name,
        'creature_data': jsonEncode(creature.toJson()),
        'share_type': 'gallery_share',
        'power_level': creature.powerLevel,
        'shared_at': DateTime.now().toIso8601String(),
      },
    );

    if (shareLink != null) {
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareLink));

      // Update app state
      ChangeNotifierProvider.of<CreatureAppState>(context).incrementShares();

      // Track the share event
      await BranchRestAPI.trackStandardEvent(
        eventName: 'SHARE',
        eventData: {
          'description': 'Creature shared from gallery',
          'content_items': [
            {
              'name': creature.name,
              'sku': creature.id,
              'category': 'creatures',
            }
          ],
        },
        customData: {
          'creature_id': creature.id,
          'share_source': 'gallery',
          'share_method': 'branch_link',
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
                child: Text('${creature.name} share link copied! +5 reward points earned!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create share link. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteCreature(Creature creature) async {
    bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 10),
                Text('Delete Creature?'),
              ],
            ),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            Text('Are you sure you want to delete ${creature.name}?'),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${creature.body} ${creature.eyes} ${creature.mouth} ${creature.accessory}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              ],
            ),
          ),

          // Action Buttons
          if (isMyCreatures) ...[
          Column(
          children: [
          IconButton(
          onPressed: () => _shareCreature(creature),
          icon: Icon(Icons.share, color: Colors.green),
          tooltip: 'Share',
          ),
          IconButton(
          onPressed: () => _deleteCreature(creature),
          icon: Icon(Icons.delete, color: Colors.red),
          tooltip: 'Delete',
          ),
          ],
          ),
          ] else ...[
          Icon(
          Icons.explore,
          color: Colors.blue,
          size: 24,
          ),
          ],
          ],
          );
        }

        void _showCreatureDetails(Creature creature, bool isMyCreatures) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    creature.primaryColor.withOpacity(0.1),
                    creature.secondaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Creature Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: creature.primaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Creature Display
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${creature.body} ${creature.eyes} ${creature.mouth} ${creature.accessory}',
                        style: TextStyle(fontSize: 40),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Creature Info
                  Text(
                    creature.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: creature.primaryColor,
                    ),
                  ),

                  SizedBox(height: 15),

                  // Stats
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: creature.primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow('Power Level', creature.powerLevel.toString(), Icons.flash_on),
                        Divider(),
                        _buildStatRow('Created',
                            '${creature.createdAt.day}/${creature.createdAt.month}/${creature.createdAt.year}',
                            Icons.calendar_today),
                        Divider(),
                        _buildStatRow('Creator ID',
                            creature.creatorId.substring(0, 8) + '...',
                            Icons.person),
                        Divider(),
                        _buildStatRow('Type', isMyCreatures ? 'My Creature' : 'Discovered',
                            isMyCreatures ? Icons.pets : Icons.explore),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Action Buttons
                  if (isMyCreatures) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _shareCreature(creature);
                            },
                            icon: Icon(Icons.share, size: 18),
                            label: Text('Share'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _deleteCreature(creature);
                            },
                            icon: Icon(Icons.delete, size: 18),
                            label: Text('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('You discovered ${creature.name}! +10 reward points!'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: Icon(Icons.favorite, size: 18),
                      label: Text('Add to Favorites'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );

      // Track creature view
      BranchRestAPI.trackCustomEvent(
        eventName: 'creature_viewed',
        customData: {
          'creature_id': creature.id,
          'creature_name': creature.name,
          'view_source': 'gallery_details',
          'is_own_creature': isMyCreatures,
        },
      );
    }

    Widget _buildStatRow(String label, String value, IconData icon) {
      return Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          SizedBox(width: 10),
          Text(
            label + ':',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      );
    }
  }(fontSize: 30),
  textAlign: TextAlign.center,
  ),
  ),
  ],
  ),
  actions: [
  TextButton(
  onPressed: () => Navigator.of(context).pop(false),
  child: Text('Cancel'),
  ),
  ElevatedButton(
  onPressed: () => Navigator.of(context).pop(true),
  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  child: Text('Delete', style: TextStyle(color: Colors.white)),
  ),
  ],
  );
},
);

if (confirmed == true) {
// In a real app, you'd remove from the state management
// For now, we'll just track the deletion
await BranchRestAPI.trackCustomEvent(
eventName: 'creature_deleted',
customData: {
'creature_id': creature.id,
'creature_name': creature.name,
'deletion_source': 'gallery',
},
);

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('${creature.name} has been deleted'),
backgroundColor: Colors.red,
),
);
}
}

@override
Widget build(BuildContext context) {
final state = ChangeNotifierProvider.of<CreatureAppState>(context);

return Scaffold(
backgroundColor: Colors.purple.shade50,
appBar: AppBar(
title: Text('Creature Gallery'),
backgroundColor: Colors.purple.shade600,
elevation: 0,
actions: [
IconButton(
onPressed: () {
setState(() {
_isGridView = !_isGridView;
});
},
icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
tooltip: _isGridView ? 'List View' : 'Grid View',
),
],
bottom: TabBar(
controller: _tabController,
tabs: [
Tab(
icon: Icon(Icons.pets),
text: 'My Creatures (${state.myCreatures.length})',
),
Tab(
icon: Icon(Icons.explore),
text: 'Discovered (${state.discoveredCreatures.length})',
),
],
),
),
body: TabBarView(
controller: _tabController,
children: [
// My Creatures Tab
_buildCreatureList(state.myCreatures, isMyCreatures: true),
// Discovered Creatures Tab
_buildCreatureList(state.discoveredCreatures, isMyCreatures: false),
],
),
floatingActionButton: FloatingActionButton.extended(
onPressed: () => Navigator.pushNamed(context, '/creator'),
icon: Icon(Icons.add),
label: Text('Create New'),
backgroundColor: Colors.purple.shade600,
),
);
}

Widget _buildCreatureList(List<Creature> creatures, {required bool isMyCreatures}) {
if (creatures.isEmpty) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Icon(
isMyCreatures ? Icons.pets : Icons.explore,
size: 80,
color: Colors.grey.shade400,
),
SizedBox(height: 20),
Text(
isMyCreatures
? 'No creatures created yet'
    : 'No creatures discovered yet',
style: TextStyle(
fontSize: 20,
color: Colors.grey.shade600,
fontWeight: FontWeight.bold,
),
),
SizedBox(height: 10),
Text(
isMyCreatures
? 'Tap the + button to create your first creature!'
    : 'Discover creatures by opening shared links!',
style: TextStyle(
fontSize: 16,
color: Colors.grey.shade500,
),
textAlign: TextAlign.center,
),
if (isMyCreatures) ...[
SizedBox(height: 30),
ElevatedButton.icon(
onPressed: () => Navigator.pushNamed(context, '/creator'),
icon: Icon(Icons.create),
label: Text('Create Your First Creature'),
style: ElevatedButton.styleFrom(
backgroundColor: Colors.purple.shade600,
foregroundColor: Colors.white,
padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
),
),
],
],
),
);
}

return Padding(
padding: EdgeInsets.all(16),
child: _isGridView
? _buildGridView(creatures, isMyCreatures)
    : _buildListView(creatures, isMyCreatures),
);
}

Widget _buildGridView(List<Creature> creatures, bool isMyCreatures) {
return GridView.builder(
gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
crossAxisSpacing: 16,
mainAxisSpacing: 16,
childAspectRatio: 0.8,
),
itemCount: creatures.length,
itemBuilder: (context, index) {
final creature = creatures[index];
return _buildCreatureCard(creature, isMyCreatures, isGrid: true);
},
);
}

Widget _buildListView(List<Creature> creatures, bool isMyCreatures) {
return ListView.builder(
itemCount: creatures.length,
itemBuilder: (context, index) {
final creature = creatures[index];
return Padding(
padding: EdgeInsets.only(bottom: 16),
child: _buildCreatureCard(creature, isMyCreatures, isGrid: false),
);
},
);
}

Widget _buildCreatureCard(Creature creature, bool isMyCreatures, {required bool isGrid}) {
return Card(
elevation: 6,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
child: InkWell(
onTap: () => _showCreatureDetails(creature, isMyCreatures),
borderRadius: BorderRadius.circular(15),
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(15),
gradient: LinearGradient(
colors: [
creature.primaryColor.withOpacity(0.1),
creature.secondaryColor.withOpacity(0.1),
],
begin: Alignment.topLeft,
end: Alignment.bottomRight,
),
),
child: Padding(
padding: EdgeInsets.all(16),
child: isGrid ? _buildGridCardContent(creature, isMyCreatures)
    : _buildListCardContent(creature, isMyCreatures),
),
),
),
);
}

Widget _buildGridCardContent(Creature creature, bool isMyCreatures) {
return Column(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
// Creature Display
Expanded(
child: Center(
child: Text(
'${creature.body} ${creature.eyes} ${creature.mouth} ${creature.accessory}',
style: TextStyle(fontSize: 40),
textAlign: TextAlign.center,
),
),
),

// Creature Info
Column(
children: [
Text(
creature.name,
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
color: creature.primaryColor,
),
textAlign: TextAlign.center,
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
SizedBox(height: 4),
Container(
padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: creature.primaryColor.withOpacity(0.2),
borderRadius: BorderRadius.circular(12),
),
child: Text(
'Power: ${creature.powerLevel}',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: creature.primaryColor,
),
),
),
],
),

SizedBox(height: 8),

// Action Buttons
if (isMyCreatures) ...[
Row(
mainAxisAlignment: MainAxisAlignment.spaceEvenly,
children: [
IconButton(
onPressed: () => _shareCreature(creature),
icon: Icon(Icons.share, color: Colors.green),
tooltip: 'Share',
),
IconButton(
onPressed: () => _deleteCreature(creature),
icon: Icon(Icons.delete, color: Colors.red),
tooltip: 'Delete',
),
],
),
] else ...[
Icon(
Icons.explore,
color: Colors.blue,
size: 20,
),
],
],
);
}

Widget _buildListCardContent(Creature creature, bool isMyCreatures) {
return Row(
children: [
// Creature Display
Container(
width: 80,
height: 80,
decoration: BoxDecoration(
color: creature.primaryColor.withOpacity(0.2),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: creature.primaryColor, width: 2),
),
child: Center(
child: Text(
'${creature.body} ${creature.eyes} ${creature.mouth} ${creature.accessory}',
style: TextStyle(fontSize: 20),
textAlign: TextAlign.center,
),
),
),

SizedBox(width: 16),

// Creature Info
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
creature.name,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: creature.primaryColor,
),
),
SizedBox(height: 4),
Row(
children: [
Container(
padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
decoration: BoxDecoration(
color: creature.primaryColor.withOpacity(0.2),
borderRadius: BorderRadius.circular(8),
),
child: Text(
'Power: ${creature.powerLevel}',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: creature.primaryColor,
),
),
),
SizedBox(width: 8),
Text(
isMyCreatures ? 'Created' : 'Discovered',
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade600,
),
),
],
),
SizedBox(height: 4),
Text(
'${creature.createdAt.day}/${creature.createdAt.month}/${creature.createdAt.year}',
style: TextStyle