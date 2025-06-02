// lib/screens/creature_creator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class CreatureCreatorScreen extends StatefulWidget {
  @override
  _CreatureCreatorScreenState createState() => _CreatureCreatorScreenState();
}

class _CreatureCreatorScreenState extends State<CreatureCreatorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();

  // Creature customization options
  String _selectedBody = '🐸';
  String _selectedEyes = '👁️';
  String _selectedMouth = '😊';
  String _selectedAccessory = '🎩';
  Color _primaryColor = Colors.green;
  Color _secondaryColor = Colors.blue;

  // Animation controllers
  late AnimationController _bounceController;
  late AnimationController _colorController;
  late Animation<double> _bounceAnimation;
  late Animation<Color?> _colorAnimation;

  // Creation state
  bool _isCreating = false;
  String? _shareLink;

  // Available options
  final List<String> _bodies = ['🐸', '🐱', '🐶', '🐰', '🦊', '🐨', '🐻', '🐼'];
  final List<String> _eyes = ['👁️', '👀', '😊', '😎', '🤔', '😴', '🤯', '🥴'];
  final List<String> _mouths = ['😊', '😄', '😆', '🤣', '😂', '🙃', '😋', '🤪'];
  final List<String> _accessories = ['🎩', '👑', '🎪', '🎭', '🎯', '🎲', '🎸', '🎺'];
  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.pink, Colors.cyan, Colors.amber,
    Colors.teal, Colors.lime, Colors.indigo, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    _colorAnimation = ColorTween(
      begin: Colors.purple.shade200,
      end: Colors.pink.shade200,
    ).animate(_colorController);

    _bounceController.repeat(reverse: true);
    _colorController.repeat(reverse: true);

    // Track screen view
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
    _bounceController.dispose();
    _colorController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _randomizeCreature() {
    setState(() {
      _selectedBody = _bodies[Random().nextInt(_bodies.length)];
      _selectedEyes = _eyes[Random().nextInt(_eyes.length)];
      _selectedMouth = _mouths[Random().nextInt(_mouths.length)];
      _selectedAccessory = _accessories[Random().nextInt(_accessories.length)];
      _primaryColor = _colors[Random().nextInt(_colors.length)];
      _secondaryColor = _colors[Random().nextInt(_colors.length)];
    });

    // Track randomization
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
      // Create the creature
      final creature = Creature(
        id: 'creature_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        body: _selectedBody,
        eyes: _selectedEyes,
        mouth: _selectedMouth,
        accessory: _selectedAccessory,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        createdAt: DateTime.now(),
        powerLevel: Random().nextInt(100) + 1,
        creatorId: ChangeNotifierProvider.of<CreatureAppState>(context).currentUserId,
      );

      // Add to app state
      ChangeNotifierProvider.of<CreatureAppState>(context).addCreature(creature);

      // Create Branch link for sharing the creature
      String? shareLink = await BranchRestAPI.createBranchLink(
        title: 'Check out my creature: ${creature.name}!',
        description: 'I just created an amazing creature in Creature Creator! Come see ${creature.name} and create your own!',
        campaignKey: 'creature_sharing',
        customData: {
          'creature_id': creature.id,
          'creature_name': creature.name,
          'creature_data': jsonEncode(creature.toJson()),
          'share_type': 'creature_creation',
          'creator_id': creature.creatorId,
          'power_level': creature.powerLevel,
          'created_at': creature.createdAt.toIso8601String(),
        },
      );

      // Track creature creation
      await BranchRestAPI.trackStandardEvent(
        eventName: 'ADD_TO_CART',
        eventData: {
          'description': 'Creature created and ready to share',
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
        _shareLink = shareLink;
        _isCreating = false;
      });

      // Show success dialog
      _showCreatureCreatedDialog(creature);

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

  void _showCreatureCreatedDialog(Creature creature) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.celebration, color: Colors.amber, size: 30),
              SizedBox(width: 10),
              Text('Creature Created!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor, width: 2),
                ),
              ),
              SizedBox(height: 20),
              if (_shareLink != null) ...[
                Text(
                  'Share your creature with friends:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _shareLink!,
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _copyShareLink(),
                      icon: Icon(Icons.copy, size: 16),
                      label: Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _shareCreature(),
                      icon: Icon(Icons.share, size: 16),
                      label: Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetCreator();
              },
              child: Text('Create Another'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to home
              },
              child: Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyShareLink() {
    if (_shareLink != null) {
      Clipboard.setData(ClipboardData(text: _shareLink!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share link copied to clipboard!'),
          backgroundColor: Colors.green,
        ),
      );

      BranchRestAPI.trackCustomEvent(
        eventName: 'creature_link_copied',
        customData: {
          'action': 'copy_share_link',
          'link_url': _shareLink!,
        },
      );
    }
  }

  void _shareCreature() {
    if (_shareLink != null) {
      // In a real app, you'd use share_plus package here
      // For demo purposes, we'll just track the action
      ChangeNotifierProvider.of<CreatureAppState>(context).incrementShares();

      BranchRestAPI.trackStandardEvent(
        eventName: 'SHARE',
        eventData: {
          'description': 'Creature shared via Branch link',
        },
        customData: {
          'share_method': 'native_share',
          'content_type': 'creature',
          'link_url': _shareLink!,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Creature shared! +5 reward points earned!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetCreator() {
    setState(() {
      _nameController.clear();
      _selectedBody = _bodies[0];
      _selectedEyes = _eyes[0];
      _selectedMouth = _mouths[0];
      _selectedAccessory = _accessories[0];
      _primaryColor = Colors.green;
      _secondaryColor = Colors.blue;
      _shareLink = null;
    });
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
              child: AnimatedBuilder(
                animation: _colorAnimation,
                builder: (context, child) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          _colorAnimation.value ?? Colors.purple.shade200,
                          _primaryColor.withOpacity(0.3),
                          _secondaryColor.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: ScaleTransition(
                        scale: _bounceAnimation,
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
                  );
                },
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
              'Colors',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Primary Color',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
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
            SizedBox(height: 15),
            Text(
              'Secondary Color',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                bool isSelected = color == _secondaryColor;
                return GestureDetector(
                  onTap: () => setState(() => _secondaryColor = color),
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
child: Column(
children: [
Text(
'$_selectedBody $_selectedEyes $_selectedMouth $_selectedAccessory',
style: TextStyle(fontSize: 40),
),
SizedBox(height: 10),
Text(
creature.name,
style: TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
color: _primaryColor,
),
),
Text(
'Power Level: ${creature.powerLevel}',
style: TextStyle(
fontSize: 14,
color: Colors.grey.shade600,
),
),
],
),