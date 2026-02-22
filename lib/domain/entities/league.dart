import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// WEEKLY LEADERBOARD / LEAGUE SYSTEM
// ═══════════════════════════════════════════════════════════════════════
//
// Inspired by Duolingo's league system:
// • Each week (Mon-Sun) users compete on XP earned.
// • Leagues are tiered: Puddle → Stream → River → Lake → Ocean.
// • At end of week, top 3 promote, bottom 3 demote.
// • XP earned during the week is tracked separately from total XP.
//
// Leaderboard data is stored in Firestore under the user doc and
// fetched for friends via FriendService. A Cloud Function handles
// weekly promotion/demotion (a TODO for server-side work), but the
// client drives the UI and tracks weeklyXp locally.
// ═══════════════════════════════════════════════════════════════════════

/// League tiers from lowest to highest.
enum LeagueTier {
  puddle('Puddle', Color(0xFF90CAF9), Icons.water_drop_outlined, 0),
  stream('Stream', Color(0xFF4FC3F7), Icons.stream_rounded, 1),
  river('River', Color(0xFF29B6F6), Icons.water_rounded, 2),
  lake('Lake', Color(0xFF0288D1), Icons.waves_rounded, 3),
  ocean('Ocean', Color(0xFFFFD700), Icons.tsunami_rounded, 4);

  final String label;
  final Color color;
  final IconData icon;
  final int rank;
  const LeagueTier(this.label, this.color, this.icon, this.rank);

  /// Next tier up, or null if at max.
  LeagueTier? get promotion {
    final idx = LeagueTier.values.indexOf(this);
    return idx < LeagueTier.values.length - 1
        ? LeagueTier.values[idx + 1]
        : null;
  }

  /// Next tier down, or null if at min.
  LeagueTier? get demotion {
    final idx = LeagueTier.values.indexOf(this);
    return idx > 0 ? LeagueTier.values[idx - 1] : null;
  }
}

/// A row in the weekly leaderboard.
class LeaderboardEntry extends Equatable {
  final String uid;
  final String username;
  final String? profileImageUrl;
  final int weeklyXp;
  final LeagueTier league;
  final int rank; // 1-based position in the sorted list

  const LeaderboardEntry({
    required this.uid,
    required this.username,
    this.profileImageUrl,
    required this.weeklyXp,
    required this.league,
    this.rank = 0,
  });

  @override
  List<Object?> get props => [uid, weeklyXp, league, rank];
}

/// Weekly leaderboard snapshot used by the UI.
class WeeklyLeaderboard extends Equatable {
  /// ISO week identifier, e.g. "2026-W08"
  final String weekId;
  final LeagueTier currentLeague;
  final List<LeaderboardEntry> entries;

  /// How many days remain in this league week (Mon-Sun).
  final int daysRemaining;

  const WeeklyLeaderboard({
    required this.weekId,
    required this.currentLeague,
    this.entries = const [],
    this.daysRemaining = 7,
  });

  /// Sorted entries (descending XP) with ranks populated.
  List<LeaderboardEntry> get ranked {
    final sorted = List<LeaderboardEntry>.from(entries)
      ..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
    return sorted
        .asMap()
        .entries
        .map((e) => LeaderboardEntry(
              uid: e.value.uid,
              username: e.value.username,
              profileImageUrl: e.value.profileImageUrl,
              weeklyXp: e.value.weeklyXp,
              league: e.value.league,
              rank: e.key + 1,
            ))
        .toList();
  }

  @override
  List<Object?> get props => [weekId, currentLeague, entries];
}

/// Helpers for ISO week calculations.
class LeagueWeek {
  LeagueWeek._();

  /// Returns the ISO week string for a given date, e.g. "2026-W08".
  static String weekIdFor(DateTime date) {
    // ISO week: weeks start Monday. Jan 4 is always in week 1.
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final weekNumber =
        ((dayOfYear - date.weekday + 10) / 7).floor().clamp(1, 53);
    return '${date.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Days remaining until end of current ISO week (Sunday 23:59).
  static int daysRemainingInWeek(DateTime now) {
    // weekday: 1=Mon..7=Sun
    return 7 - now.weekday;
  }

  /// Whether promotion/demotion should happen (new week started).
  static bool isNewWeek(String? lastWeekId, DateTime now) {
    return lastWeekId != weekIdFor(now);
  }
}
