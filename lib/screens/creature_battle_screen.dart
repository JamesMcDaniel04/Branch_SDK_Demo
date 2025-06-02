// lib/screens/creature_battle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class CreatureBattleScreen extends StatefulWidget {
  @override
  _CreatureBattleScreenState createState() => _CreatureBattleScreenState();
}

class _CreatureBattleScreenState extends State<CreatureBattleScreen>
    with TickerProviderStateMixin {
  late AnimationController _battleController;
  late AnimationController _shakeController;
  late Animation<double> _battleAnimation;
  late Animation<double> _shakeAnimation;

  Creature? _selectedCreature;
  Creature? _opponentCreature;
  bool _isBattling = false;
  bool _battleCompleted = false;
  String? _battleResult;
  String? _battleShareLink;

  // Battle stats
  int _myCreatureHealth = 100;
  int _opponentHealth = 100;
  List<String> _battleLog = [];

  @override
  void initState() {
    super.initState();

    _battleController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _battleAnimation = CurvedAnimation(
      parent: _battleController,
      curve: Curves.easeInOut,
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    // Generate a random opponent creature for demo
    _generateOpponentCreature();

    // Track battle arena view
    BranchRestAPI.trackCustomEvent(
      eventName: 'battle_arena_opened',
      customData: {
        'screen': 'battle_arena',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _battleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _generateOpponentCreature() {
    final bodies = ['🐸', '🐱', '🐶', '🐰', '🦊', '🐨', '🐻', '🐼'];
    final eyes = ['👁️', '👀', '😊', '😎', '🤔', '😴', '🤯', '🥴'];
    final mouths = ['😊', '😄', '😆', '🤣', '😂', '🙃', '😋', '🤪'];
    final accessories = ['🎩', '👑', '🎪', '🎭', '🎯', '🎲', '🎸', '🎺'];
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];

    _opponentCreature = Creature(
      id: 'opponent_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Wild ${['Warrior', 'Guardian', 'Champion', 'Beast', 'Legend'][Random().nextInt(5)]}',
      body: bodies[Random().nextInt(bodies.length)],
      eyes: eyes[Random().nextInt(eyes.length)],
      mouth: mouths[Random().nextInt(mouths.length)],
      accessory: accessories[Random().nextInt(accessories.length)],
      primaryColor: colors[Random().nextInt(colors.length)],
      secondaryColor: colors[Random().nextInt(colors.length)],
      createdAt: DateTime.now(),
      powerLevel: Random().nextInt(80) + 20, // 20-99 power level
      creatorId: 'wild_system',
    );
  }

  Future<void> _startBattle() async {
    if (_selectedCreature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a creature to battle!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isBattling = true;
      _battleCompleted = false;
      _myCreatureHealth = 100;
      _opponentHealth = 100;
      _battleLog.clear();
      _battleResult = null;
    });

    // Track battle start
    await BranchRestAPI.trackStandardEvent(
      eventName: 'INITIATE_PURCHASE',
      eventData: {
        'description': 'Creature battle started',
        'content_items': [
          {
            'name': _selectedCreature!.name,
            'sku': _selectedCreature!.id,
            'category': 'battle',
          }
        ],
      },
      customData: {
        'battle_type': 'vs_wild',
        'my_creature_power': _selectedCreature!.powerLevel,
        'opponent_power': _opponentCreature!.powerLevel,
        'battle_id': 'battle_${DateTime.now().millisecondsSinceEpoch}',
      },
    );

    _battleController.forward();

    // Simulate battle rounds
    for (int round = 1; round <= 5 && _myCreatureHealth > 0 && _opponentHealth > 0; round++) {
      await Future.delayed(Duration(milliseconds: 800));
      _performBattleRound(round);
    }

    await Future.delayed(Duration(milliseconds: 500));
    _completeBattle();
  }

  void _performBattleRound(int round) {
    final myAttack = Random().nextInt(_selectedCreature!.powerLevel ~/ 2) + 10;
    final opponentAttack = Random().nextInt(_opponentCreature!.powerLevel ~/ 2) + 10;

    setState(() {
      _opponentHealth = math.max(0, _opponentHealth - myAttack);
      _battleLog.add('Round $round: ${_selectedCreature!.name} deals $myAttack damage!');

      if (_opponentHealth > 0) {
        _myCreatureHealth = math.max(0, _myCreatureHealth - opponentAttack);
        _battleLog.add('Round $round: ${_opponentCreature!.name} deals $opponentAttack damage!');
      }
    });

    // Trigger shake animation
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  Future<void> _completeBattle() async {
    final bool victory = _myCreatureHealth > _opponentHealth;

    setState(() {
      _isBattling = false;
      _battleCompleted = true;
      _battleResult = victory ? 'VICTORY!' : 'DEFEAT!';
    });

    if (victory) {
      // Award reward points for victory
      ChangeNotifierProvider.of<CreatureAppState>(context).incrementShares(); // Using this for points
    }

    // Track battle completion
    await BranchRestAPI.trackStandardEvent(
      eventName: victory ? 'PURCHASE' : 'VIEW_ITEM',
      eventData: {
        'description': 'Battle completed',
        'revenue': victory ? 10.0 : 0.0, // Victory gives points
      },
      customData: {
        'battle_result': victory ? 'victory' : 'defeat',
        'final_health_my_creature': _myCreatureHealth,
        'final_health_opponent': _opponentHealth,
        'my_creature_id': _selectedCreature!.id,
        'opponent_creature_id': _opponentCreature!.id,
      },
    );

    // Create share link for battle result
    _createBattleShareLink(victory);

    _battleController.reset();
  }

  Future<void> _createBattleShareLink(bool victory) async {
    String? shareLink = await BranchRestAPI.createBranchLink(
      title: victory
          ? '🏆 ${_selectedCreature!.name} won an epic battle!'
          : '⚔️ Epic battle in Creature Creator!',
      description: victory
          ? 'My creature ${_selectedCreature!.name} just defeated ${_opponentCreature!.name} in an epic battle! Join the fun and create your own creature!'
          : 'Just had an intense battle in Creature Creator! Create your own creature and challenge friends!',
      campaignKey: 'creature_battle',
      customData: {
        'battle_result': victory ? 'victory' : 'defeat',
        'winner_creature_id': victory ? _selectedCreature!.id : _opponentCreature!.id,
        'winner_creature_name': victory ? _selectedCreature!.name : _opponentCreature!.name,
        'my_creature_data': jsonEncode(_selectedCreature!.toJson()),
        'opponent_creature_data': jsonEncode(_opponentCreature!.toJson()),
        'final_health_my': _myCreatureHealth,
        'final_health_opponent': _opponentHealth,
        'share_type': 'battle_result',
        'battle_timestamp': DateTime.now().toIso8601String(),
      },
    );

    setState(() {
      _battleShareLink = shareLink;
    });
  }

  Future<void> _shareBattleResult() async {
    if (_battleShareLink != null) {
      await Clipboard.setData(ClipboardData(text: _battleShareLink!));

      ChangeNotifierProvider.of<CreatureAppState>(context).incrementShares();

      await BranchRestAPI.trackStandardEvent(
        eventName: 'SHARE',
        eventData: {
          'description': 'Battle result shared',
        },
        customData: {
          'share_type': 'battle_result',
          'battle_result': _battleResult,
          'link_url': _battleShareLink!,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Battle result shared! +5 reward points earned!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ChangeNotifierProvider.of<CreatureAppState>(context);

    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: Text('Battle Arena'),
        backgroundColor: Colors.red.shade600,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arena Header
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.red.shade400, Colors.orange.shade400],
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.sports_mma, size: 50, color: Colors.white),
                    SizedBox(height: 10),
                    Text(
                      '⚔️ BATTLE ARENA ⚔️',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Choose your creature and fight!',
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

            // Creature Selection
            if (state.myCreatures.isEmpty) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.info, size: 60, color: Colors.grey.shade400),
                      SizedBox(height: 15),
                      Text(
                        'No Creatures Available',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Create your first creature to start battling!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/creator'),
                        icon: Icon(Icons.add),
                        label: Text('Create Creature'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // My Creature Selection
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Your Fighter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: state.myCreatures.length,
                          itemBuilder: (context, index) {
                            final creature = state.myCreatures[index];
                            final isSelected = _selectedCreature?.id == creature.id;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCreature = creature;
                                });
                              },
                              child: Container(
                                width: 100,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? creature.primaryColor.withOpacity(0.3)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? creature.primaryColor : Colors.grey.shade300,
                                    width: isSelected ? 3 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${creature.body} ${creature.eyes} ${creature.mouth} ${creature.accessory}',
                                      style: TextStyle(fontSize: 20),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      creature.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: creature.primaryColor,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Power: ${creature.powerLevel}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Battle Arena
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade200],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Battle VS Display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // My Creature
                          _buildBattleCreature(
                            _selectedCreature,
                            _myCreatureHealth,
                            'Your Creature',
                            true,
                          ),

                          // VS
                          AnimatedBuilder(
                            animation: _battleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_battleAnimation.value * 0.3),
                                child: Column(
                                  children: [
                                    Text(
                                      'VS',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade600,
                                      ),
                                    ),
                                    if (_isBattling) ...[
                                      SizedBox(height: 10),
                                      Icon(
                                        Icons.flash_on,
                                        color: Colors.yellow.shade600,
                                        size: 30,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),

                          // Opponent Creature
                          _buildBattleCreature(
                            _opponentCreature,
                            _opponentHealth,
                            'Wild Opponent',
                            false,
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Battle Button
                      if (!_isBattling && !_battleCompleted) ...[
                        ElevatedButton.icon(
                          onPressed: _selectedCreature != null ? _startBattle : null,
                          icon: Icon(Icons.sports_mma, size: 24),
                          label: Text('START BATTLE!'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (_isBattling) ...[
                        Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'BATTLE IN PROGRESS...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ] else if (_battleCompleted) ...[
                        Column(
                          children: [
                            Text(
                              _battleResult!,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _battleResult == 'VICTORY!' ? Colors.green : Colors.red,
                              ),
                            ),
                            SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _shareBattleResult,
                                  icon: Icon(Icons.share),
                                  label: Text('Share Result'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _generateOpponentCreature();
                                    setState(() {
                                      _battleCompleted = false;
                                      _battleResult = null;
                                      _battleShareLink = null;
                                    });
                                  },
                                  icon: Icon(Icons.refresh),
                                  label: Text('New Battle'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Battle Log
              if (_battleLog.isNotEmpty) ...[
                SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Battle Log',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          height: 150,
                          child: ListView.builder(
                            itemCount: _battleLog.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  _battleLog[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBattleCreature(Creature? creature, int health, String label, bool isMyCreature) {
    if (creature == null) {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Center(
              child: Text(
                '?',
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Select Creature',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (_isBattling && isMyCreature) ? _shakeAnimation.value * (Random().nextBool() ? 1 : -1) : 0,
            0,
          ),
          child: Column(
            children: [
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
              SizedBox(height: 8),
              Text(
                creature.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: creature.primaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                'Power: ${creature.powerLevel}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 4),
              // Health Bar
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: health / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: health > 50 ? Colors.green : health > 25 ? Colors.orange : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 2),
              Text(
                '$health HP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: health > 50 ? Colors.green : health > 25 ? Colors.orange : Colors.red,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}