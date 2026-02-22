import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// DAILY QUEST SYSTEM
// ═══════════════════════════════════════════════════════════════════════
//
// Each day the user receives 3 randomly-selected quests from the pool.
// Quests reset at midnight alongside the daily hydration reset.
// Completing a quest awards XP + Drops. Completing all 3 awards a bonus.
//
// Quest progress is tracked in HydrationState as a flat list of ints
// (current progress per slot). Completion is determined by comparing
// to the quest's `target` value.
// ═══════════════════════════════════════════════════════════════════════

/// The type of daily quest — determines what triggers progress.
enum DailyQuestType {
  /// Log N drinks (any type)
  logDrinks,

  /// Drink N oz of water-equivalent
  drinkOz,

  /// Log N healthy-tier drinks (excellent or good)
  healthyPicks,

  /// Log at least 1 drink before a specific hour (e.g. 9 AM)
  earlyBird,

  /// Try N unique drink types today
  uniqueDrinks,

  /// Meet your daily water goal
  meetGoal,

  /// Log drinks in N different hours of the day (spread hydration)
  spreadHydration,
}

/// A quest template from the global pool.
class DailyQuestTemplate extends Equatable {
  final String id;
  final DailyQuestType type;
  final String title;
  final String description;
  final IconData icon;
  final int target;

  /// XP awarded on completion.
  final int xpReward;

  /// Drops (currency) awarded on completion.
  final int dropsReward;

  const DailyQuestTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.xpReward = 30,
    this.dropsReward = 10,
  });

  @override
  List<Object?> get props => [id];
}

/// Runtime state of a single assigned quest for today.
class DailyQuestProgress extends Equatable {
  final String questId;
  final int current;
  final bool completed;

  /// Whether the user has manually claimed the reward for this quest.
  final bool claimed;
  final DateTime? completedAt;

  const DailyQuestProgress({
    required this.questId,
    this.current = 0,
    this.completed = false,
    this.claimed = false,
    this.completedAt,
  });

  DailyQuestProgress copyWith({
    int? current,
    bool? completed,
    bool? claimed,
    DateTime? completedAt,
  }) {
    return DailyQuestProgress(
      questId: questId,
      current: current ?? this.current,
      completed: completed ?? this.completed,
      claimed: claimed ?? this.claimed,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'questId': questId,
        'current': current,
        'completed': completed,
        'claimed': claimed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DailyQuestProgress.fromMap(Map<String, dynamic> map) {
    return DailyQuestProgress(
      questId: map['questId'] as String? ?? '',
      current: (map['current'] as num?)?.toInt() ?? 0,
      completed: map['completed'] as bool? ?? false,
      claimed: map['claimed'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [questId, current, completed, claimed];
}

// ═══════════════════════════════════════════════════════════════════════
// QUEST POOL — all possible daily quests
// ═══════════════════════════════════════════════════════════════════════

class DailyQuests {
  DailyQuests._();

  static const List<DailyQuestTemplate> pool = [
    // ── Log drinks ─────────────────────────────────────────────
    DailyQuestTemplate(
      id: 'log_3_drinks',
      type: DailyQuestType.logDrinks,
      title: 'Sip Sip Sip',
      description: 'Log 3 drinks today',
      icon: Icons.local_drink_rounded,
      target: 3,
      xpReward: 25,
      dropsReward: 8,
    ),
    DailyQuestTemplate(
      id: 'log_5_drinks',
      type: DailyQuestType.logDrinks,
      title: 'Five-a-Sip',
      description: 'Log 5 drinks today',
      icon: Icons.local_drink_rounded,
      target: 5,
      xpReward: 35,
      dropsReward: 12,
    ),
    DailyQuestTemplate(
      id: 'log_8_drinks',
      type: DailyQuestType.logDrinks,
      title: 'Hydration Station',
      description: 'Log 8 drinks today',
      icon: Icons.local_drink_rounded,
      target: 8,
      xpReward: 50,
      dropsReward: 20,
    ),
    DailyQuestTemplate(
      id: 'log_4_drinks',
      type: DailyQuestType.logDrinks,
      title: 'Four on the Floor',
      description: 'Log 4 drinks today',
      icon: Icons.local_drink_rounded,
      target: 4,
      xpReward: 30,
      dropsReward: 10,
    ),
    DailyQuestTemplate(
      id: 'log_6_drinks',
      type: DailyQuestType.logDrinks,
      title: 'Six Pack',
      description: 'Log 6 drinks today',
      icon: Icons.local_drink_rounded,
      target: 6,
      xpReward: 40,
      dropsReward: 14,
    ),

    // ── Drink volume ───────────────────────────────────────────
    DailyQuestTemplate(
      id: 'drink_24oz',
      type: DailyQuestType.drinkOz,
      title: 'Steady Flow',
      description: 'Drink 24 oz today',
      icon: Icons.water_drop_rounded,
      target: 24,
      xpReward: 20,
      dropsReward: 8,
    ),
    DailyQuestTemplate(
      id: 'drink_32oz',
      type: DailyQuestType.drinkOz,
      title: 'Quart Crusher',
      description: 'Drink 32 oz today',
      icon: Icons.water_drop_rounded,
      target: 32,
      xpReward: 25,
      dropsReward: 10,
    ),
    DailyQuestTemplate(
      id: 'drink_48oz',
      type: DailyQuestType.drinkOz,
      title: 'Half-Way Hero',
      description: 'Drink 48 oz today',
      icon: Icons.water_drop_rounded,
      target: 48,
      xpReward: 30,
      dropsReward: 12,
    ),
    DailyQuestTemplate(
      id: 'drink_64oz',
      type: DailyQuestType.drinkOz,
      title: 'Big Gulp',
      description: 'Drink 64 oz today',
      icon: Icons.water_drop_rounded,
      target: 64,
      xpReward: 40,
      dropsReward: 15,
    ),
    DailyQuestTemplate(
      id: 'drink_80oz',
      type: DailyQuestType.drinkOz,
      title: 'Overflow',
      description: 'Drink 80 oz today',
      icon: Icons.water_drop_rounded,
      target: 80,
      xpReward: 50,
      dropsReward: 20,
    ),

    // ── Healthy picks ──────────────────────────────────────────
    DailyQuestTemplate(
      id: 'healthy_2',
      type: DailyQuestType.healthyPicks,
      title: 'Clean Sipping',
      description: 'Log 2 healthy drinks',
      icon: Icons.eco_rounded,
      target: 2,
      xpReward: 25,
      dropsReward: 10,
    ),
    DailyQuestTemplate(
      id: 'healthy_3',
      type: DailyQuestType.healthyPicks,
      title: 'Triple Green',
      description: 'Log 3 healthy drinks',
      icon: Icons.eco_rounded,
      target: 3,
      xpReward: 30,
      dropsReward: 12,
    ),
    DailyQuestTemplate(
      id: 'healthy_4',
      type: DailyQuestType.healthyPicks,
      title: 'Green Machine',
      description: 'Log 4 healthy drinks',
      icon: Icons.eco_rounded,
      target: 4,
      xpReward: 40,
      dropsReward: 15,
    ),
    DailyQuestTemplate(
      id: 'healthy_5',
      type: DailyQuestType.healthyPicks,
      title: 'Nature\'s Best',
      description: 'Log 5 healthy drinks',
      icon: Icons.eco_rounded,
      target: 5,
      xpReward: 50,
      dropsReward: 18,
    ),

    // ── Early bird ─────────────────────────────────────────────
    DailyQuestTemplate(
      id: 'early_bird_9am',
      type: DailyQuestType.earlyBird,
      title: 'Early Bird',
      description: 'Log a drink before 9 AM',
      icon: Icons.wb_sunny_rounded,
      target: 9,
      xpReward: 25,
      dropsReward: 10,
    ),
    DailyQuestTemplate(
      id: 'early_bird_8am',
      type: DailyQuestType.earlyBird,
      title: 'Rise & Hydrate',
      description: 'Log a drink before 8 AM',
      icon: Icons.wb_sunny_rounded,
      target: 8,
      xpReward: 30,
      dropsReward: 12,
    ),
    DailyQuestTemplate(
      id: 'early_bird_7am',
      type: DailyQuestType.earlyBird,
      title: 'Dawn Patrol',
      description: 'Log a drink before 7 AM',
      icon: Icons.wb_twilight_rounded,
      target: 7,
      xpReward: 35,
      dropsReward: 15,
    ),

    // ── Unique drinks ──────────────────────────────────────────
    DailyQuestTemplate(
      id: 'unique_2',
      type: DailyQuestType.uniqueDrinks,
      title: 'Double Feature',
      description: 'Try 2 different drink types today',
      icon: Icons.shuffle_rounded,
      target: 2,
      xpReward: 20,
      dropsReward: 8,
    ),
    DailyQuestTemplate(
      id: 'unique_3',
      type: DailyQuestType.uniqueDrinks,
      title: 'Mix It Up',
      description: 'Try 3 different drink types today',
      icon: Icons.shuffle_rounded,
      target: 3,
      xpReward: 30,
      dropsReward: 12,
    ),
    DailyQuestTemplate(
      id: 'unique_4',
      type: DailyQuestType.uniqueDrinks,
      title: 'Drink Explorer',
      description: 'Try 4 different drink types today',
      icon: Icons.explore_rounded,
      target: 4,
      xpReward: 40,
      dropsReward: 16,
    ),

    // ── Meet goal ──────────────────────────────────────────────
    DailyQuestTemplate(
      id: 'meet_goal',
      type: DailyQuestType.meetGoal,
      title: 'Goal Getter',
      description: 'Meet your daily water goal',
      icon: Icons.flag_rounded,
      target: 1,
      xpReward: 40,
      dropsReward: 15,
    ),

    // ── Spread hydration ───────────────────────────────────────
    DailyQuestTemplate(
      id: 'spread_3h',
      type: DailyQuestType.spreadHydration,
      title: 'Steady Dripper',
      description: 'Log drinks in 3 different hours',
      icon: Icons.schedule_rounded,
      target: 3,
      xpReward: 30,
      dropsReward: 12,
    ),
    DailyQuestTemplate(
      id: 'spread_4h',
      type: DailyQuestType.spreadHydration,
      title: 'Clock Watcher',
      description: 'Log drinks in 4 different hours',
      icon: Icons.schedule_rounded,
      target: 4,
      xpReward: 35,
      dropsReward: 14,
    ),
    DailyQuestTemplate(
      id: 'spread_5h',
      type: DailyQuestType.spreadHydration,
      title: 'All-Day Hydrator',
      description: 'Log drinks in 5 different hours',
      icon: Icons.schedule_rounded,
      target: 5,
      xpReward: 45,
      dropsReward: 18,
    ),
    DailyQuestTemplate(
      id: 'spread_6h',
      type: DailyQuestType.spreadHydration,
      title: 'Around the Clock',
      description: 'Log drinks in 6 different hours',
      icon: Icons.access_time_filled_rounded,
      target: 6,
      xpReward: 55,
      dropsReward: 22,
    ),
  ];

  /// Look up a quest template by its id.
  static DailyQuestTemplate? byId(String id) {
    try {
      return pool.firstWhere((q) => q.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Pick [count] random non-duplicate quests for today.
  /// Uses the day-of-year as a seed so the same user sees the same
  /// quests all day, but different quests tomorrow.
  static List<DailyQuestTemplate> pickForDay(DateTime date, {int count = 3}) {
    // Simple deterministic shuffle based on day-of-year + year
    final seed = date.year * 1000 + date.month * 40 + date.day;
    final shuffled = List<DailyQuestTemplate>.from(pool);

    // Fisher-Yates with a simple LCG seeded on the day
    int rng = seed;
    for (int i = shuffled.length - 1; i > 0; i--) {
      rng = ((rng * 1103515245) + 12345) & 0x7fffffff;
      final j = rng % (i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }

    return shuffled.take(count).toList();
  }
}
