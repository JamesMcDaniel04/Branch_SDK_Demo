// lib/screens/rewards_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class RewardsScreen extends StatefulWidget {
  @override
  _RewardsScreenState createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with TickerProviderStateMixin {
  late AnimationController _coinController;
  late AnimationController _glowController;
  late Animation<double> _coinAnimation;
  late Animation<double> _glowAnimation;

  List<RewardItem> _availableRewards = [];
  List<Achievement> _achievements = [];
  String? _referralLink;
  bool _isGeneratingReferralLink = false;

  @override
  void initState() {
    super.initState();

    _coinController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _coinAnimation = CurvedAnimation(
      parent: _coinController,
      curve: Curves.bounceOut,
    );

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _coinController.repeat(reverse: true);
    _glowController.repeat(reverse: true);

    _initializeRewards();

    // Track rewards center view
    BranchRestAPI.trackCustomEvent(
      eventName: 'rewards_center_opened',
      customData: {
        'screen': 'rewards_center',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _initializeRewards() {
    _availableRewards = [
      RewardItem(
        id: 'power_boost',
        name: 'Power Boost',
        description: 'Increase creature power by 10 points',
        cost: 50,
        icon: Icons.flash_on,
        color: Colors.yellow,
        type: RewardType.powerUp,
      ),
      RewardItem(
        id: 'extra_slot',
        name: 'Extra Creature Slot',
        description: 'Create one additional creature',
        cost: 100,
        icon: Icons.add_circle,
        color: Colors.blue,
        type: RewardType.feature,
      ),
      RewardItem(
        id: 'premium_accessories',
        name: 'Premium Accessories Pack',
        description: 'Unlock exclusive creature accessories',
        cost: 150,
        icon: Icons.diamond,
        color: Colors.purple,
        type: RewardType.cosmetic,
      ),
      RewardItem(
        id: 'battle_armor',
        name: 'Battle Armor',
        description: 'Reduce battle damage by 25%',
        cost: 200,
        icon: Icons.shield,
        color: Colors.green,
        type: RewardType.powerUp,
      ),
      RewardItem(
        id: 'referral_bonus',
        name: 'Referral Multiplier',
        description: 'Double referral rewards for 7 days',
        cost: 250,
        icon: Icons.people,
        color: Colors.orange,
        type: RewardType.feature,
      ),
    ];

    _achievements = [
    Achievement(
    id: 'first_creature',
    name: 'Creator',
    description: 'Create your first creature',
    points: 10,
    icon: Icons.create,
    color: Colors.blue,
    isUnlocked: true,
    ),
    Achievement(
    id: 'first_share',
    name: 'Sharer',
    description: 'Share your first creature',
    points: 25,
    icon: Icons.share,
    color: Colors.green,
    isUnlocked: true,
    ),
    Achievement(
    id: 'five_creatures',
    name