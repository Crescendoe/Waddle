import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// VIRTUAL CURRENCY ("DROPS") & SHOP SYSTEM
// ═══════════════════════════════════════════════════════════════════════
//
// Drops are earned through gameplay actions and spent in the Shop.
// Earning sources:
//   • Daily quest completion: 8-20 drops each
//   • Level-up: 50 drops
//   • Daily goal met: 5 drops
//   • Challenge completed: 100 drops
//
// The shop contains consumable items and (in the future) cosmetics.
// ═══════════════════════════════════════════════════════════════════════

/// How drops are earned (for ledger / animation display).
enum DropsSource {
  dailyQuest('Daily Quest', Icons.task_alt_rounded),
  levelUp('Level Up', Icons.arrow_upward_rounded),
  dailyGoal('Daily Goal', Icons.flag_rounded),
  challengeComplete('Challenge', Icons.emoji_events_rounded),
  purchase('Purchase', Icons.shopping_bag_rounded);

  final String label;
  final IconData icon;
  const DropsSource(this.label, this.icon);
}

/// A purchasable item in the shop.
class ShopItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int price; // in Drops
  final ShopItemType type;

  /// Max quantity a user can hold at once (0 = unlimited).
  final int maxOwned;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.price,
    required this.type,
    this.maxOwned = 0,
  });

  @override
  List<Object?> get props => [id];
}

enum ShopItemType {
  /// Single-use consumable
  consumable,

  /// Permanent unlock
  permanent,
}

// ═══════════════════════════════════════════════════════════════════════
// SHOP CATALOG
// ═══════════════════════════════════════════════════════════════════════

class ShopItems {
  ShopItems._();

  static const streakFreeze = ShopItem(
    id: 'streak_freeze',
    name: 'Streak Freeze',
    description: 'Protects your streak for one missed day. '
        'Automatically used when you miss your goal.',
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF4FC3F7),
    price: 100,
    type: ShopItemType.consumable,
    maxOwned: 3,
  );

  static const doubleXp = ShopItem(
    id: 'double_xp',
    name: 'Double XP',
    description: 'All XP earned is doubled for the rest of today. '
        'Stacks with daily quests.',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFFD54F),
    price: 200,
    type: ShopItemType.consumable,
    maxOwned: 2,
  );

  static const cooldownSkip = ShopItem(
    id: 'cooldown_skip',
    name: 'Quick Sip',
    description: 'Immediately removes the drink-logging cooldown timer '
        'so you can log your next drink right away.',
    icon: Icons.timer_off_rounded,
    color: Color(0xFF81C784),
    price: 50,
    type: ShopItemType.consumable,
    maxOwned: 5,
  );

  static const List<ShopItem> all = [
    streakFreeze,
    doubleXp,
    cooldownSkip,
  ];

  static ShopItem? byId(String id) {
    try {
      return all.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// USER INVENTORY — tracks owned consumables
// ═══════════════════════════════════════════════════════════════════════

/// Tracks how many of each shop item the user currently owns.
class UserInventory extends Equatable {
  final int streakFreezes;
  final int doubleXpTokens;
  final int cooldownSkips;

  /// Whether a Double-XP token is currently active today.
  final bool doubleXpActive;

  const UserInventory({
    this.streakFreezes = 0,
    this.doubleXpTokens = 0,
    this.cooldownSkips = 0,
    this.doubleXpActive = false,
  });

  int countOf(String itemId) {
    switch (itemId) {
      case 'streak_freeze':
        return streakFreezes;
      case 'double_xp':
        return doubleXpTokens;
      case 'cooldown_skip':
        return cooldownSkips;
      default:
        return 0;
    }
  }

  bool canPurchase(ShopItem item) {
    if (item.maxOwned <= 0) return true;
    return countOf(item.id) < item.maxOwned;
  }

  UserInventory copyWith({
    int? streakFreezes,
    int? doubleXpTokens,
    int? cooldownSkips,
    bool? doubleXpActive,
  }) {
    return UserInventory(
      streakFreezes: streakFreezes ?? this.streakFreezes,
      doubleXpTokens: doubleXpTokens ?? this.doubleXpTokens,
      cooldownSkips: cooldownSkips ?? this.cooldownSkips,
      doubleXpActive: doubleXpActive ?? this.doubleXpActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'streakFreezes': streakFreezes,
        'doubleXpTokens': doubleXpTokens,
        'cooldownSkips': cooldownSkips,
        'doubleXpActive': doubleXpActive,
      };

  factory UserInventory.fromMap(Map<String, dynamic> map) {
    return UserInventory(
      streakFreezes: (map['streakFreezes'] as num?)?.toInt() ?? 0,
      doubleXpTokens: (map['doubleXpTokens'] as num?)?.toInt() ?? 0,
      cooldownSkips: (map['cooldownSkips'] as num?)?.toInt() ?? 0,
      doubleXpActive: map['doubleXpActive'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [streakFreezes, doubleXpTokens, cooldownSkips, doubleXpActive];
}
