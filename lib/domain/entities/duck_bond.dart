import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:waddle/domain/entities/duck_accessory.dart';

// ═══════════════════════════════════════════════════════════════════════
// PASSIVE BONUS TYPES
// ═══════════════════════════════════════════════════════════════════════

/// The category of a duck's passive bonus.
enum DuckPassiveType {
  /// Flat +N drops added every time the user logs a drink.
  bonusDropsPerLog,

  /// Flat +N drops added when the daily goal is met.
  bonusDropsOnGoal,

  /// Percentage increase to all XP earned.
  xpBoostPercent,

  /// Minutes removed from the entry cooldown timer.
  cooldownReductionMin,

  /// Percentage increase to quest rewards (drops + XP).
  questBonusPercent,

  /// Percentage increase to drops from all sources.
  dropMultiplierPercent,
}

extension DuckPassiveTypeExtension on DuckPassiveType {
  String get label {
    switch (this) {
      case DuckPassiveType.bonusDropsPerLog:
        return 'Drops per Log';
      case DuckPassiveType.bonusDropsOnGoal:
        return 'Drops on Goal';
      case DuckPassiveType.xpBoostPercent:
        return 'XP Boost';
      case DuckPassiveType.cooldownReductionMin:
        return 'Cooldown Reduction';
      case DuckPassiveType.questBonusPercent:
        return 'Quest Bonus';
      case DuckPassiveType.dropMultiplierPercent:
        return 'Drop Multiplier';
    }
  }

  IconData get icon {
    switch (this) {
      case DuckPassiveType.bonusDropsPerLog:
        return Icons.water_drop_rounded;
      case DuckPassiveType.bonusDropsOnGoal:
        return Icons.flag_circle_rounded;
      case DuckPassiveType.xpBoostPercent:
        return Icons.bolt_rounded;
      case DuckPassiveType.cooldownReductionMin:
        return Icons.timer_rounded;
      case DuckPassiveType.questBonusPercent:
        return Icons.task_alt_rounded;
      case DuckPassiveType.dropMultiplierPercent:
        return Icons.trending_up_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DUCK PASSIVE — definition of what bonus each duck provides
// ═══════════════════════════════════════════════════════════════════════

/// The passive bonus definition for one duck.
class DuckPassive {
  final String name;
  final String description;
  final DuckPassiveType type;

  /// Explicit value at each bond level (1–10).
  /// Index 0 = level 1, index 9 = level 10.
  /// Rarer ducks have steeper / more frequent increases.
  final List<int> levelValues;

  const DuckPassive({
    required this.name,
    required this.description,
    required this.type,
    required this.levelValues,
  });

  /// The bonus value at a given bond level (1–10).
  double scaledValue(int bondLevel) {
    final clamped = bondLevel.clamp(1, 10);
    return levelValues[clamped - 1].toDouble();
  }

  /// Human-readable string for the bonus at a given bond level.
  String formattedValue(int bondLevel) {
    final v = scaledValue(bondLevel).toInt();
    switch (type) {
      case DuckPassiveType.bonusDropsPerLog:
      case DuckPassiveType.bonusDropsOnGoal:
        return '+$v';
      case DuckPassiveType.cooldownReductionMin:
        return '-$v min';
      case DuckPassiveType.xpBoostPercent:
      case DuckPassiveType.questBonusPercent:
      case DuckPassiveType.dropMultiplierPercent:
        return '+$v%';
    }
  }

  /// Formatted value at the next bond level, or null if already at max.
  String? nextLevelFormatted(int bondLevel) {
    if (bondLevel >= 10) return null;
    return formattedValue(bondLevel + 1);
  }

  /// Whether the value actually changes at the next level.
  bool improvesAtNextLevel(int bondLevel) {
    if (bondLevel >= 10) return false;
    return levelValues[bondLevel] != levelValues[bondLevel - 1];
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ALL 24 DUCK PASSIVES  (indexed by DuckCompanions.all order)
// ═══════════════════════════════════════════════════════════════════════

class DuckPassives {
  DuckPassives._();

  /// Passive for each duck, indexed by `DuckCompanion.index`.
  ///
  /// Each [levelValues] list contains the exact value at bond levels 1–10.
  /// Progression speed scales with rarity:
  ///   Common    → slow, lots of plateaus
  ///   Uncommon  → moderate, occasional plateaus
  ///   Rare      → steady growth, few plateaus
  ///   Epic      → consistent increases every level
  ///   Legendary → always increasing, large jumps
  static const Map<int, DuckPassive> all = {
    // ── Streak ducks (Common / Rare / Epic) ─────────────────────────
    0: DuckPassive(
      // Puddle — Common
      name: 'Puddle Pace',
      description: 'Reduces entry cooldown.',
      type: DuckPassiveType.cooldownReductionMin,
      levelValues: [1, 2, 2, 3, 3, 4, 4, 5, 5, 6],
    ),
    1: DuckPassive(
      // Ripple — Common
      name: 'Ripple Reward',
      description: 'Bonus drops every time you log a drink.',
      type: DuckPassiveType.bonusDropsPerLog,
      levelValues: [1, 1, 2, 2, 3, 3, 4, 4, 5, 6],
    ),
    2: DuckPassive(
      // Current — Rare
      name: 'Swift Current',
      description: 'Significantly cuts cooldown time.',
      type: DuckPassiveType.cooldownReductionMin,
      levelValues: [3, 4, 4, 5, 5, 6, 7, 7, 8, 9],
    ),
    3: DuckPassive(
      // Tidal — Epic
      name: 'Tidal Surge',
      description: 'Boosts XP from all sources.',
      type: DuckPassiveType.xpBoostPercent,
      levelValues: [8, 9, 11, 12, 14, 15, 17, 19, 21, 24],
    ),

    // ── Volume ducks (Common / Uncommon / Epic) ─────────────────────
    4: DuckPassive(
      // Dewdrop — Common
      name: 'Morning Dew',
      description: 'Bonus drops when you hit your daily goal.',
      type: DuckPassiveType.bonusDropsOnGoal,
      levelValues: [3, 4, 5, 6, 7, 8, 9, 10, 12, 14],
    ),
    5: DuckPassive(
      // Brook — Uncommon
      name: 'Babbling Brook',
      description: 'Extra drops with every drink logged.',
      type: DuckPassiveType.bonusDropsPerLog,
      levelValues: [2, 2, 3, 3, 4, 4, 5, 5, 6, 7],
    ),
    6: DuckPassive(
      // Cascade — Epic
      name: 'Cascade Flow',
      description: 'Multiplies all drop earnings.',
      type: DuckPassiveType.dropMultiplierPercent,
      levelValues: [8, 9, 11, 12, 14, 15, 17, 19, 21, 24],
    ),

    // ── Healthy picks ducks (Common / Uncommon) ─────────────────────
    7: DuckPassive(
      // Sprout — Common
      name: 'Green Thumb',
      description: 'A little extra for every drink you log.',
      type: DuckPassiveType.bonusDropsPerLog,
      levelValues: [1, 1, 2, 2, 3, 3, 4, 4, 5, 6],
    ),
    8: DuckPassive(
      // Botanist — Uncommon
      name: 'Botanical Knowledge',
      description: 'Boosts XP from all sources.',
      type: DuckPassiveType.xpBoostPercent,
      levelValues: [3, 4, 5, 5, 6, 7, 7, 8, 9, 10],
    ),

    // ── Goals met ducks (Common / Rare) ─────────────────────────────
    9: DuckPassive(
      // Bullseye — Common
      name: 'Perfect Aim',
      description: 'Generous bonus drops on goal completion.',
      type: DuckPassiveType.bonusDropsOnGoal,
      levelValues: [4, 5, 6, 7, 8, 9, 10, 12, 14, 16],
    ),
    10: DuckPassive(
      // Marksman — Rare
      name: 'Sharpshooter',
      description: 'Big drop bonus when you hit your goal.',
      type: DuckPassiveType.bonusDropsOnGoal,
      levelValues: [8, 10, 12, 14, 16, 18, 20, 23, 26, 30],
    ),

    // ── Drinks logged duck (Rare) ───────────────────────────────────
    11: DuckPassive(
      // Nightingale — Rare
      name: 'Melodic Boost',
      description: 'Increases all quest rewards.',
      type: DuckPassiveType.questBonusPercent,
      levelValues: [7, 8, 10, 11, 13, 14, 16, 18, 20, 22],
    ),

    // ── Challenge-specific ducks (Uncommon) ─────────────────────────
    12: DuckPassive(
      // Purist — Uncommon
      name: 'Pure Drops',
      description: 'A small bonus drop per drink logged.',
      type: DuckPassiveType.bonusDropsPerLog,
      levelValues: [1, 1, 2, 2, 3, 3, 4, 5, 5, 6],
    ),
    13: DuckPassive(
      // Brewmaster — Uncommon
      name: 'Steeped Wisdom',
      description: 'Brewed knowledge boosts XP.',
      type: DuckPassiveType.xpBoostPercent,
      levelValues: [3, 4, 5, 5, 6, 7, 7, 8, 9, 10],
    ),
    14: DuckPassive(
      // Serene — Uncommon
      name: 'Inner Peace',
      description: 'Calm focus reduces cooldown.',
      type: DuckPassiveType.cooldownReductionMin,
      levelValues: [2, 2, 3, 3, 4, 4, 5, 5, 6, 7],
    ),
    15: DuckPassive(
      // Frostbite — Uncommon
      name: 'Crisp Reward',
      description: 'A refreshing bonus with each log.',
      type: DuckPassiveType.bonusDropsPerLog,
      levelValues: [1, 1, 2, 2, 3, 3, 4, 5, 5, 6],
    ),
    16: DuckPassive(
      // Herbivore — Uncommon
      name: 'Plant Power',
      description: 'Nature-powered quest bonus.',
      type: DuckPassiveType.questBonusPercent,
      levelValues: [3, 4, 5, 5, 6, 7, 7, 8, 9, 10],
    ),
    17: DuckPassive(
      // Elixir — Uncommon
      name: 'Elixir Boost',
      description: 'A touch of magic on all drops earned.',
      type: DuckPassiveType.dropMultiplierPercent,
      levelValues: [3, 4, 5, 5, 6, 7, 7, 8, 9, 10],
    ),

    // ── Very unique ducks (Rare / Epic / Legendary) ─────────────────
    18: DuckPassive(
      // Verdant — Rare
      name: 'Verdant Wisdom',
      description: 'Deep botanical knowledge boosts XP.',
      type: DuckPassiveType.xpBoostPercent,
      levelValues: [5, 6, 7, 8, 10, 11, 13, 14, 16, 18],
    ),
    19: DuckPassive(
      // Leviathan — Epic
      name: 'Deep Harvest',
      description: 'The leviathan rewards each sip.',
      type: DuckPassiveType.bonusDropsPerLog,
      levelValues: [3, 4, 5, 6, 7, 8, 9, 10, 12, 14],
    ),
    20: DuckPassive(
      // Mixologist — Uncommon
      name: 'Mixed Mastery',
      description: 'Diverse tastes boost quest rewards.',
      type: DuckPassiveType.questBonusPercent,
      levelValues: [5, 6, 7, 7, 8, 9, 10, 11, 12, 14],
    ),
    21: DuckPassive(
      // Marathon — Legendary
      name: 'Endurance',
      description: 'Marathon stamina slashes cooldown.',
      type: DuckPassiveType.cooldownReductionMin,
      levelValues: [5, 6, 7, 8, 9, 10, 11, 12, 13, 15],
    ),
    22: DuckPassive(
      // Zenith — Legendary
      name: 'Peak Performance',
      description: 'A year of wisdom amplifies all XP.',
      type: DuckPassiveType.xpBoostPercent,
      levelValues: [10, 12, 14, 16, 18, 21, 24, 27, 30, 35],
    ),
    23: DuckPassive(
      // Kraken — Legendary
      name: 'Kraken\'s Hoard',
      description: 'A mythical multiplier on all drops.',
      type: DuckPassiveType.dropMultiplierPercent,
      levelValues: [10, 12, 14, 16, 18, 21, 24, 27, 30, 35],
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════
// DUCK BOND DATA — per-duck persistent state
// ═══════════════════════════════════════════════════════════════════════

/// Persistent bond data for one duck owned by the user.
class DuckBondData extends Equatable {
  /// Bond level (1–10). Higher = stronger passive bonus.
  final int bondLevel;

  /// User-chosen nickname for this duck. Null = use default name.
  final String? nickname;

  /// IDs of equipped accessories, keyed by slot name.
  /// e.g. `{ 'hat': 'hat_crown', 'eyewear': 'eye_monocle' }`
  final Map<String, String> equippedAccessories;

  // ── AFK bond progress ───────────────────────────────────────────
  /// Banked idle-time milliseconds toward the current level.
  /// Accumulated whenever the duck is removed from the home screen.
  final int afkAccumulatedMs;

  /// When the duck was last placed on the home screen (null = not active).
  /// While on the home screen, elapsed = now − afkStartTime.
  final DateTime? afkStartTime;

  const DuckBondData({
    this.bondLevel = 1,
    this.nickname,
    this.equippedAccessories = const {},
    this.afkAccumulatedMs = 0,
    this.afkStartTime,
  });

  /// Get the accessory ID equipped in a given slot, or null.
  String? accessoryForSlot(AccessorySlot slot) =>
      equippedAccessories[slot.name];

  // ── AFK helpers ─────────────────────────────────────────────────

  /// Total AFK milliseconds (banked + live elapsed if active).
  int totalAfkMs() {
    int total = afkAccumulatedMs;
    if (afkStartTime != null) {
      total += DateTime.now().difference(afkStartTime!).inMilliseconds;
    }
    return total.clamp(0, DuckAfkConfig.msForLevel(bondLevel));
  }

  /// AFK progress toward auto-level-up (0.0–1.0).
  double afkProgress() {
    if (bondLevel >= DuckBondLevels.maxLevel) return 1.0;
    final needed = DuckAfkConfig.msForLevel(bondLevel);
    if (needed <= 0) return 1.0;
    return (totalAfkMs() / needed).clamp(0.0, 1.0);
  }

  /// Drop cost after applying the AFK discount.
  int discountedCost() {
    if (bondLevel >= DuckBondLevels.maxLevel) return 0;
    final base = DuckBondLevels.costToLevel(bondLevel);
    final discount = afkProgress();
    return (base * (1.0 - discount)).ceil();
  }

  /// Whether AFK progress has reached 100% for auto-level-up.
  bool get readyToAutoLevel =>
      bondLevel < DuckBondLevels.maxLevel && afkProgress() >= 1.0;

  /// Remaining duration until auto-level-up (zero if already ready).
  Duration afkTimeRemaining() {
    if (bondLevel >= DuckBondLevels.maxLevel) return Duration.zero;
    final needed = DuckAfkConfig.msForLevel(bondLevel);
    final elapsed = totalAfkMs();
    final remaining = needed - elapsed;
    return remaining > 0 ? Duration(milliseconds: remaining) : Duration.zero;
  }

  DuckBondData copyWith({
    int? bondLevel,
    String? nickname,
    bool clearNickname = false,
    Map<String, String>? equippedAccessories,
    int? afkAccumulatedMs,
    DateTime? afkStartTime,
    bool clearAfkStartTime = false,
  }) {
    return DuckBondData(
      bondLevel: bondLevel ?? this.bondLevel,
      nickname: clearNickname ? null : (nickname ?? this.nickname),
      equippedAccessories: equippedAccessories ?? this.equippedAccessories,
      afkAccumulatedMs: afkAccumulatedMs ?? this.afkAccumulatedMs,
      afkStartTime:
          clearAfkStartTime ? null : (afkStartTime ?? this.afkStartTime),
    );
  }

  /// Serialize to a Firestore-compatible map.
  Map<String, dynamic> toMap() => {
        'bondLevel': bondLevel,
        if (nickname != null) 'nickname': nickname,
        'equippedAccessories': equippedAccessories,
        'afkAccumulatedMs': afkAccumulatedMs,
        if (afkStartTime != null)
          'afkStartTime': afkStartTime!.toIso8601String(),
      };

  /// Deserialize from Firestore.
  factory DuckBondData.fromMap(Map<String, dynamic> map) {
    return DuckBondData(
      bondLevel: (map['bondLevel'] as num?)?.toInt() ?? 1,
      nickname: map['nickname'] as String?,
      equippedAccessories: (map['equippedAccessories'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const {},
      afkAccumulatedMs: (map['afkAccumulatedMs'] as num?)?.toInt() ?? 0,
      afkStartTime: map['afkStartTime'] is String
          ? DateTime.tryParse(map['afkStartTime'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        bondLevel,
        nickname,
        equippedAccessories,
        afkAccumulatedMs,
        afkStartTime
      ];
}

// ═══════════════════════════════════════════════════════════════════════
// BOND LEVEL COSTS
// ═══════════════════════════════════════════════════════════════════════

class DuckBondLevels {
  DuckBondLevels._();

  /// Drops required to advance FROM [level] to [level + 1].
  /// Returns 0 when already at max (10).
  static int costToLevel(int level) {
    switch (level) {
      case 1:
        return 10;
      case 2:
        return 20;
      case 3:
        return 35;
      case 4:
        return 50;
      case 5:
        return 75;
      case 6:
        return 100;
      case 7:
        return 140;
      case 8:
        return 190;
      case 9:
        return 250;
      default:
        return 0; // max level
    }
  }

  static const int maxLevel = 10;

  /// Total drops required from level 1 to max.
  static int get totalCost {
    int sum = 0;
    for (int i = 1; i < maxLevel; i++) {
      sum += costToLevel(i);
    }
    return sum;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AFK / IDLE BOND CONFIG
// ═══════════════════════════════════════════════════════════════════════

/// Configuration for idle/AFK bond accumulation.
///
/// While a duck is on the home screen it slowly fills a bond gauge.
/// Once the gauge is full the duck auto-levels for free.
/// Partial progress proportionally reduces the feed cost.
class DuckAfkConfig {
  DuckAfkConfig._();

  /// Hours required to auto-level from [level] → [level + 1].
  static const Map<int, int> _hoursForLevel = {
    1: 8,
    2: 16,
    3: 24,
    4: 36,
    5: 48,
    6: 72,
    7: 120,
    8: 168,
    9: 240,
  };

  /// Milliseconds required to auto-level from [level] → [level + 1].
  static int msForLevel(int level) {
    final hours = _hoursForLevel[level] ?? 0;
    return hours * 3600 * 1000;
  }

  /// Duration required to auto-level from [level] → [level + 1].
  static Duration durationForLevel(int level) =>
      Duration(milliseconds: msForLevel(level));
}

// ═══════════════════════════════════════════════════════════════════════
// ACTIVE DUCK BONUSES — aggregated from all home-screen ducks
// ═══════════════════════════════════════════════════════════════════════

/// Aggregated passive bonuses from all ducks currently on the home screen.
class ActiveDuckBonuses {
  /// Flat drops added per water log.
  final int bonusDropsPerLog;

  /// Flat drops added when daily goal is met.
  final int bonusDropsOnGoal;

  /// Percentage XP boost (0.10 = 10%).
  final double xpBoostFraction;

  /// Minutes subtracted from entry cooldown.
  final int cooldownReductionMin;

  /// Percentage quest reward boost (0.10 = 10%).
  final double questBonusFraction;

  /// Percentage drop multiplier (0.10 = 10%).
  final double dropMultiplierFraction;

  const ActiveDuckBonuses({
    this.bonusDropsPerLog = 0,
    this.bonusDropsOnGoal = 0,
    this.xpBoostFraction = 0.0,
    this.cooldownReductionMin = 0,
    this.questBonusFraction = 0.0,
    this.dropMultiplierFraction = 0.0,
  });

  /// Whether any bonus has a non-zero value.
  bool get hasAny =>
      bonusDropsPerLog > 0 ||
      bonusDropsOnGoal > 0 ||
      xpBoostFraction > 0 ||
      cooldownReductionMin > 0 ||
      questBonusFraction > 0 ||
      dropMultiplierFraction > 0;

  /// Compute the aggregate bonuses from ducks currently on the home screen.
  ///
  /// Only ducks with indices in [homeDuckIndices] contribute.
  /// Each duck's bonus is scaled by its bond level.
  static ActiveDuckBonuses compute({
    required List<int> homeDuckIndices,
    required Map<int, DuckBondData> duckBonds,
  }) {
    double dropsPerLog = 0;
    double dropsOnGoal = 0;
    double xpBoost = 0;
    double cooldown = 0;
    double questBonus = 0;
    double dropMult = 0;

    for (final idx in homeDuckIndices) {
      final passive = DuckPassives.all[idx];
      if (passive == null) continue;

      final bond = duckBonds[idx] ?? const DuckBondData();
      final value = passive.scaledValue(bond.bondLevel);

      switch (passive.type) {
        case DuckPassiveType.bonusDropsPerLog:
          dropsPerLog += value;
        case DuckPassiveType.bonusDropsOnGoal:
          dropsOnGoal += value;
        case DuckPassiveType.xpBoostPercent:
          xpBoost += value;
        case DuckPassiveType.cooldownReductionMin:
          cooldown += value;
        case DuckPassiveType.questBonusPercent:
          questBonus += value;
        case DuckPassiveType.dropMultiplierPercent:
          dropMult += value;
      }
    }

    return ActiveDuckBonuses(
      bonusDropsPerLog: dropsPerLog.round(),
      bonusDropsOnGoal: dropsOnGoal.round(),
      xpBoostFraction: xpBoost / 100.0,
      cooldownReductionMin: cooldown.round(),
      questBonusFraction: questBonus / 100.0,
      dropMultiplierFraction: dropMult / 100.0,
    );
  }
}
