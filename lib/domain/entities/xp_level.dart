import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// XP EVENTS — every action that awards experience points
// ═══════════════════════════════════════════════════════════════════════

/// Defines how much XP each in-app action awards.
enum XpEvent {
  /// Log any drink
  logDrink(10, 'Logged a drink', Icons.local_drink_rounded),

  /// The logged drink was a healthy pick (excellent / good tier)
  healthyPick(5, 'Healthy pick bonus', Icons.eco_rounded),

  /// Meet your daily water goal
  dailyGoalMet(50, 'Daily goal met!', Icons.flag_rounded),

  /// Complete a 14-day challenge
  challengeComplete(200, 'Challenge completed!', Icons.emoji_events_rounded),

  /// Complete a daily quest
  dailyQuestComplete(30, 'Daily quest done', Icons.task_alt_rounded),

  /// Complete ALL 3 daily quests in one day
  allDailyQuests(50, 'All quests cleared!', Icons.star_rounded),

  /// Reach a new streak milestone (10, 20, 30, 60, 100, 365)
  streakMilestone(
      100, 'Streak milestone!', Icons.local_fire_department_rounded),

  /// First drink of the day
  firstDrinkOfDay(5, 'First sip of the day', Icons.wb_sunny_rounded);

  final int xp;
  final String label;
  final IconData icon;
  const XpEvent(this.xp, this.label, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════
// LEVELING CURVE
// ═══════════════════════════════════════════════════════════════════════

/// Static helpers for the leveling system.
///
/// XP thresholds follow a gentle polynomial curve so early levels feel
/// fast and later levels slow down — exactly like Duolingo.
///
/// Level 1 starts at 0 XP.  Max level is 100.
class XpLevel {
  XpLevel._();

  static const int maxLevel = 100;

  /// Total XP required to reach [level].
  ///
  /// Formula: `40 * level^1.5` (rounded), so:
  /// L1=0, L2=113, L5=358, L10=1265, L20=3578, L50=14142, L100=40000
  static int xpForLevel(int level) {
    if (level <= 1) return 0;
    return (40 * _pow15(level)).round();
  }

  /// XP required to go from [level] to [level]+1.
  static int xpToNextLevel(int level) =>
      xpForLevel(level + 1) - xpForLevel(level);

  /// The user's current level given their total XP.
  static int levelForXp(int totalXp) {
    int lvl = 1;
    while (xpForLevel(lvl + 1) <= totalXp && lvl < maxLevel) {
      lvl++;
    }
    return lvl;
  }

  /// Progress fraction (0.0‥1.0) towards the next level.
  static double progressForXp(int totalXp) {
    final lvl = levelForXp(totalXp);
    final base = xpForLevel(lvl);
    final needed = xpToNextLevel(lvl);
    if (needed <= 0) return 1.0;
    return ((totalXp - base) / needed).clamp(0.0, 1.0);
  }

  /// Friendly level title shown in the UI.
  /// Levels are just numbers — the user's streak tier provides the
  /// cosmetic rank / title, so there is no separate LevelTier.

  // pow(x, 1.5) without dart:math import
  static double _pow15(int x) {
    final d = x.toDouble();
    // x^1.5 = x * sqrt(x)
    return d * _sqrt(d);
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STREAK MILESTONES that grant bonus XP
// ═══════════════════════════════════════════════════════════════════════

class StreakMilestones {
  StreakMilestones._();

  static const List<int> milestones = [10, 20, 30, 60, 100, 365];

  /// Returns `true` if [streak] is exactly a milestone value.
  static bool isMilestone(int streak) => milestones.contains(streak);
}

/// Snapshot of a single XP-award event for animation / toast display.
class XpAward extends Equatable {
  final XpEvent event;
  final int amount;
  final DateTime awardedAt;

  const XpAward({
    required this.event,
    required this.amount,
    required this.awardedAt,
  });

  @override
  List<Object?> get props => [event, amount, awardedAt];
}
