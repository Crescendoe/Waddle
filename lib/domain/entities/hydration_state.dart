import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Hydration tracking state for the current day and overall stats
class HydrationState extends Equatable {
  final double waterConsumedOz;
  final double waterGoalOz;
  final int currentStreak;
  final int recordStreak;
  final bool goalMetToday;
  final int completedChallenges;
  final int companionsCollected;
  final DateTime? lastResetDate;
  final DateTime? nextEntryTime;
  final int? activeChallengeIndex;
  final List<bool> challengeActive;
  final bool challengeFailed;
  final bool challengeCompleted;
  final int challengeDaysLeft;

  // ── Lifetime / rewards stats ──────────────────────────────────────
  final double totalWaterConsumedOz;
  final int totalDaysLogged;
  final int totalDrinksLogged;
  final int totalHealthyPicks;
  final List<String> uniqueDrinksLogged;
  final int totalGoalsMet;
  final String? activeThemeId;
  final int? activeDuckIndex;
  final int? cupDuckIndex;

  const HydrationState({
    this.waterConsumedOz = 0.0,
    this.waterGoalOz = 80.0,
    this.currentStreak = 0,
    this.recordStreak = 0,
    this.goalMetToday = false,
    this.completedChallenges = 0,
    this.companionsCollected = 0,
    this.lastResetDate,
    this.nextEntryTime,
    this.activeChallengeIndex,
    this.challengeActive = const [false, false, false, false, false, false],
    this.challengeFailed = false,
    this.challengeCompleted = false,
    this.challengeDaysLeft = 14,
    this.totalWaterConsumedOz = 0.0,
    this.totalDaysLogged = 0,
    this.totalDrinksLogged = 0,
    this.totalHealthyPicks = 0,
    this.uniqueDrinksLogged = const [],
    this.totalGoalsMet = 0,
    this.activeThemeId,
    this.activeDuckIndex,
    this.cupDuckIndex,
  });

  double get progressPercent =>
      waterGoalOz > 0 ? (waterConsumedOz / waterGoalOz).clamp(0.0, 1.0) : 0.0;

  double get waterConsumedCups => waterConsumedOz / 8.0;
  double get waterGoalCups => waterGoalOz / 8.0;
  double get remainingOz =>
      (waterGoalOz - waterConsumedOz).clamp(0.0, double.infinity);
  double get remainingCups => remainingOz / 8.0;

  bool get hasActiveChallenge => activeChallengeIndex != null;
  bool get isEntryOnCooldown =>
      nextEntryTime != null && DateTime.now().isBefore(nextEntryTime!);

  Duration get cooldownRemaining {
    if (nextEntryTime == null) return Duration.zero;
    final diff = nextEntryTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  StreakTier get streakTier {
    if (currentStreak >= 30) return StreakTier.platinum;
    if (currentStreak >= 20) return StreakTier.gold;
    if (currentStreak >= 15) return StreakTier.silver;
    if (currentStreak >= 10) return StreakTier.bronze;
    return StreakTier.normal;
  }

  HydrationState copyWith({
    double? waterConsumedOz,
    double? waterGoalOz,
    int? currentStreak,
    int? recordStreak,
    bool? goalMetToday,
    int? completedChallenges,
    int? companionsCollected,
    DateTime? lastResetDate,
    DateTime? nextEntryTime,
    int? activeChallengeIndex,
    List<bool>? challengeActive,
    bool? challengeFailed,
    bool? challengeCompleted,
    int? challengeDaysLeft,
    bool clearActiveChallengeIndex = false,
    bool clearNextEntryTime = false,
    double? totalWaterConsumedOz,
    int? totalDaysLogged,
    int? totalDrinksLogged,
    int? totalHealthyPicks,
    List<String>? uniqueDrinksLogged,
    int? totalGoalsMet,
    String? activeThemeId,
    bool clearActiveThemeId = false,
    int? activeDuckIndex,
    bool clearActiveDuckIndex = false,
    int? cupDuckIndex,
    bool clearCupDuckIndex = false,
  }) {
    return HydrationState(
      waterConsumedOz: waterConsumedOz ?? this.waterConsumedOz,
      waterGoalOz: waterGoalOz ?? this.waterGoalOz,
      currentStreak: currentStreak ?? this.currentStreak,
      recordStreak: recordStreak ?? this.recordStreak,
      goalMetToday: goalMetToday ?? this.goalMetToday,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      companionsCollected: companionsCollected ?? this.companionsCollected,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      nextEntryTime:
          clearNextEntryTime ? null : (nextEntryTime ?? this.nextEntryTime),
      activeChallengeIndex: clearActiveChallengeIndex
          ? null
          : (activeChallengeIndex ?? this.activeChallengeIndex),
      challengeActive: challengeActive ?? this.challengeActive,
      challengeFailed: challengeFailed ?? this.challengeFailed,
      challengeCompleted: challengeCompleted ?? this.challengeCompleted,
      challengeDaysLeft: challengeDaysLeft ?? this.challengeDaysLeft,
      totalWaterConsumedOz: totalWaterConsumedOz ?? this.totalWaterConsumedOz,
      totalDaysLogged: totalDaysLogged ?? this.totalDaysLogged,
      totalDrinksLogged: totalDrinksLogged ?? this.totalDrinksLogged,
      totalHealthyPicks: totalHealthyPicks ?? this.totalHealthyPicks,
      uniqueDrinksLogged: uniqueDrinksLogged ?? this.uniqueDrinksLogged,
      totalGoalsMet: totalGoalsMet ?? this.totalGoalsMet,
      activeThemeId:
          clearActiveThemeId ? null : (activeThemeId ?? this.activeThemeId),
      activeDuckIndex: clearActiveDuckIndex
          ? null
          : (activeDuckIndex ?? this.activeDuckIndex),
      cupDuckIndex:
          clearCupDuckIndex ? null : (cupDuckIndex ?? this.cupDuckIndex),
    );
  }

  @override
  List<Object?> get props => [
        waterConsumedOz,
        waterGoalOz,
        currentStreak,
        recordStreak,
        goalMetToday,
        completedChallenges,
        companionsCollected,
        lastResetDate,
        nextEntryTime,
        activeChallengeIndex,
        challengeActive,
        challengeFailed,
        challengeCompleted,
        challengeDaysLeft,
        totalWaterConsumedOz,
        totalDaysLogged,
        totalDrinksLogged,
        totalHealthyPicks,
        uniqueDrinksLogged,
        totalGoalsMet,
        activeThemeId,
        activeDuckIndex,
        cupDuckIndex,
      ];
}

enum StreakTier { normal, bronze, silver, gold, platinum }

extension StreakTierExtension on StreakTier {
  Color get color {
    switch (this) {
      case StreakTier.platinum:
        return const Color(0xFF36708B);
      case StreakTier.gold:
        return const Color(0xFFFFD700);
      case StreakTier.silver:
        return const Color(0xFFC0C0C0);
      case StreakTier.bronze:
        return const Color(0xFFCD7F32);
      case StreakTier.normal:
        return const Color(0xFF90CAF9);
    }
  }

  String get label {
    switch (this) {
      case StreakTier.platinum:
        return 'Platinum';
      case StreakTier.gold:
        return 'Gold';
      case StreakTier.silver:
        return 'Silver';
      case StreakTier.bronze:
        return 'Bronze';
      case StreakTier.normal:
        return 'Starter';
    }
  }

  IconData get icon {
    switch (this) {
      case StreakTier.platinum:
        return Icons.diamond_rounded;
      case StreakTier.gold:
        return Icons.emoji_events_rounded;
      case StreakTier.silver:
        return Icons.workspace_premium_rounded;
      case StreakTier.bronze:
        return Icons.military_tech_rounded;
      case StreakTier.normal:
        return Icons.water_drop_rounded;
    }
  }
}
