import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ── Theme floating effects ──────────────────────────────────────────

/// Visual effect type for theme backgrounds — floating silhouettes, particles.
enum ThemeEffect {
  none,
  bubbles,
  leaves,
  snowflakes,
  stars,
  fireflies,
  petals,
  waves,
  sparkles,
}

// ── Unlock criteria ─────────────────────────────────────────────────

/// How a theme reward is unlocked — covers every major app facet.
enum ThemeUnlockType {
  /// Always available.
  free,

  /// Record streak ≥ value.
  streak,

  /// Total individual drink entries logged.
  totalDrinksLogged,

  /// Number of distinct drink types the user has tried.
  uniqueDrinks,

  /// Cumulative count of excellent + good tier drinks logged.
  healthyPicks,

  /// Number of challenges completed.
  challengesCompleted,

  /// Lifetime ounces consumed.
  totalOzConsumed,

  /// Total days where the daily goal was met.
  goalsMet,
}

/// Condition that must be satisfied to unlock a theme.
class ThemeUnlockCondition extends Equatable {
  final ThemeUnlockType type;
  final int value;
  final String displayText;

  const ThemeUnlockCondition({
    required this.type,
    required this.value,
    required this.displayText,
  });

  bool isUnlocked({
    required int recordStreak,
    required int totalDaysLogged,
    required int completedChallenges,
    required double totalOzConsumed,
    required int totalHealthyPicks,
    required int uniqueDrinks,
    required int totalGoalsMet,
    required int totalDrinksLogged,
  }) {
    switch (type) {
      case ThemeUnlockType.free:
        return true;
      case ThemeUnlockType.streak:
        return recordStreak >= value;
      case ThemeUnlockType.totalDrinksLogged:
        return totalDrinksLogged >= value;
      case ThemeUnlockType.uniqueDrinks:
        return uniqueDrinks >= value;
      case ThemeUnlockType.healthyPicks:
        return totalHealthyPicks >= value;
      case ThemeUnlockType.challengesCompleted:
        return completedChallenges >= value;
      case ThemeUnlockType.totalOzConsumed:
        return totalOzConsumed >= value;
      case ThemeUnlockType.goalsMet:
        return totalGoalsMet >= value;
    }
  }

  @override
  List<Object?> get props => [type, value];
}

// ── Theme reward entity ─────────────────────────────────────────────

/// An unlockable background theme the player can collect and apply.
class ThemeReward extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<Color> gradientColors;
  final IconData icon;
  final ThemeUnlockCondition unlockCondition;
  final ThemeEffect effect;

  const ThemeReward({
    required this.id,
    required this.name,
    required this.description,
    required this.gradientColors,
    required this.icon,
    required this.unlockCondition,
    this.effect = ThemeEffect.none,
  });

  @override
  List<Object?> get props => [id, name];
}

// ── All unlockable themes ───────────────────────────────────────────

class ThemeRewards {
  ThemeRewards._();

  static const List<ThemeReward> all = [
    // ── Free ────────────────────────────────────────────────────────
    ThemeReward(
      id: 'default',
      name: 'Default Pond',
      description: 'The classic Waddle look — cool and calming.',
      gradientColors: [Color(0xFFE8F4FC), Color(0xFFB8E4E8)],
      icon: Icons.water_drop_rounded,
      effect: ThemeEffect.bubbles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.free,
        value: 0,
        displayText: 'Always available',
      ),
    ),

    // ── Total drinks logged ─────────────────────────────────────────
    ThemeReward(
      id: 'morning_dew',
      name: 'Morning Dew',
      description: 'A fresh green start to every day.',
      gradientColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      icon: Icons.grass_rounded,
      effect: ThemeEffect.leaves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.totalDrinksLogged,
        value: 1,
        displayText: 'Log your first drink',
      ),
    ),
    ThemeReward(
      id: 'sunset_glow',
      name: 'Sunset Glow',
      description: 'Warm peach skies after a well-hydrated day.',
      gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFCCBC)],
      icon: Icons.wb_twilight_rounded,
      effect: ThemeEffect.fireflies,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.totalDrinksLogged,
        value: 25,
        displayText: 'Log 25 drinks',
      ),
    ),

    // ── Streaks ─────────────────────────────────────────────────────
    ThemeReward(
      id: 'ocean_breeze',
      name: 'Ocean Breeze',
      description: 'Cool blue tones — like a walk along the coast.',
      gradientColors: [Color(0xFFE1F5FE), Color(0xFFB2EBF2)],
      icon: Icons.air_rounded,
      effect: ThemeEffect.waves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.streak,
        value: 7,
        displayText: 'Reach a 7-day streak',
      ),
    ),
    ThemeReward(
      id: 'lavender_fields',
      name: 'Lavender Fields',
      description: 'Soft purple tranquility as far as the eye can see.',
      gradientColors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
      icon: Icons.spa_rounded,
      effect: ThemeEffect.petals,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.streak,
        value: 14,
        displayText: 'Reach a 14-day streak',
      ),
    ),
    ThemeReward(
      id: 'emerald_spring',
      name: 'Emerald Spring',
      description: 'Lush green and teal — nature in full bloom.',
      gradientColors: [Color(0xFFC8E6C9), Color(0xFF80CBC4)],
      icon: Icons.eco_rounded,
      effect: ThemeEffect.leaves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.streak,
        value: 30,
        displayText: 'Reach a 30-day streak',
      ),
    ),
    ThemeReward(
      id: 'diamond_falls',
      name: 'Diamond Falls',
      description: 'Platinum shimmer reserved for the most dedicated.',
      gradientColors: [Color(0xFFECEFF1), Color(0xFFF5F5F5)],
      icon: Icons.diamond_rounded,
      effect: ThemeEffect.snowflakes,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.streak,
        value: 60,
        displayText: 'Reach a 60-day streak',
      ),
    ),

    // ── Unique drinks tried ─────────────────────────────────────────
    ThemeReward(
      id: 'forest_canopy',
      name: 'Forest Canopy',
      description: 'Exploring the full spectrum of green.',
      gradientColors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
      icon: Icons.forest_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.uniqueDrinks,
        value: 5,
        displayText: 'Try 5 different drinks',
      ),
    ),
    ThemeReward(
      id: 'coral_reef',
      name: 'Coral Reef',
      description: 'A vibrant underwater palette of warm corals.',
      gradientColors: [Color(0xFFFBE9E7), Color(0xFFFFAB91)],
      icon: Icons.scuba_diving_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.uniqueDrinks,
        value: 10,
        displayText: 'Try 10 different drinks',
      ),
    ),

    // ── Healthy picks ───────────────────────────────────────────────
    ThemeReward(
      id: 'berry_patch',
      name: 'Berry Patch',
      description: 'Sweet berry tones for sweet healthy choices.',
      gradientColors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      icon: Icons.local_florist_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.healthyPicks,
        value: 15,
        displayText: 'Log 15 healthy drinks',
      ),
    ),
    ThemeReward(
      id: 'cherry_blossom',
      name: 'Cherry Blossom',
      description: 'Delicate pink petals celebrating your choices.',
      gradientColors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      icon: Icons.filter_vintage_rounded,
      effect: ThemeEffect.petals,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.healthyPicks,
        value: 50,
        displayText: 'Log 50 healthy drinks',
      ),
    ),
    ThemeReward(
      id: 'cosmic_tide',
      name: 'Cosmic Tide',
      description: 'Deep space hues for a truly healthy explorer.',
      gradientColors: [Color(0xFFD1C4E9), Color(0xFFBBDEFB)],
      icon: Icons.auto_awesome_rounded,
      effect: ThemeEffect.stars,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.healthyPicks,
        value: 100,
        displayText: 'Log 100 healthy drinks',
      ),
    ),

    // ── Goals met ───────────────────────────────────────────────────
    ThemeReward(
      id: 'golden_hour',
      name: 'Golden Hour',
      description: 'Warm amber glow for meeting your daily targets.',
      gradientColors: [Color(0xFFFFFDE7), Color(0xFFFFE082)],
      icon: Icons.wb_sunny_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.goalsMet,
        value: 7,
        displayText: 'Meet your daily goal 7 times',
      ),
    ),
    ThemeReward(
      id: 'midnight_lake',
      name: 'Midnight Lake',
      description: 'Cool indigo waters of consistent dedication.',
      gradientColors: [Color(0xFFE8EAF6), Color(0xFF9FA8DA)],
      icon: Icons.nightlight_round,
      effect: ThemeEffect.stars,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.goalsMet,
        value: 30,
        displayText: 'Meet your daily goal 30 times',
      ),
    ),

    // ── Total oz consumed ───────────────────────────────────────────
    ThemeReward(
      id: 'arctic_frost',
      name: 'Arctic Frost',
      description: 'Ice-cold blue for serious hydration volume.',
      gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      icon: Icons.ac_unit_rounded,
      effect: ThemeEffect.snowflakes,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.totalOzConsumed,
        value: 500,
        displayText: 'Drink 500 oz total',
      ),
    ),
    ThemeReward(
      id: 'desert_oasis',
      name: 'Desert Oasis',
      description: 'Sand meeting aqua — a true hydration journey.',
      gradientColors: [Color(0xFFFFF8E1), Color(0xFFB2EBF2)],
      icon: Icons.beach_access_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.totalOzConsumed,
        value: 2000,
        displayText: 'Drink 2,000 oz total',
      ),
    ),

    // ── Challenges ──────────────────────────────────────────────────
    ThemeReward(
      id: 'tropical_splash',
      name: 'Tropical Splash',
      description: 'Breezy teal for your first challenge victory.',
      gradientColors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      icon: Icons.emoji_events_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.challengesCompleted,
        value: 1,
        displayText: 'Complete 1 challenge',
      ),
    ),
    ThemeReward(
      id: 'northern_lights',
      name: 'Northern Lights',
      description: 'An aurora of green and purple — truly rare.',
      gradientColors: [Color(0xFFC8E6C9), Color(0xFFCE93D8)],
      icon: Icons.auto_awesome_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.challengesCompleted,
        value: 3,
        displayText: 'Complete 3 challenges',
      ),
    ),
    ThemeReward(
      id: 'volcanic_spring',
      name: 'Volcanic Spring',
      description: 'Magma meets amber — forged by every challenge.',
      gradientColors: [Color(0xFFFFCCBC), Color(0xFFFFECB3)],
      icon: Icons.local_fire_department_rounded,
      effect: ThemeEffect.fireflies,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.challengesCompleted,
        value: 6,
        displayText: 'Complete all 6 challenges',
      ),
    ),
  ];

  /// Look up a theme by its ID.
  static ThemeReward? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// How many themes the player has unlocked.
  static int countUnlocked({
    required int recordStreak,
    required int totalDaysLogged,
    required int completedChallenges,
    required double totalOzConsumed,
    required int totalHealthyPicks,
    required int uniqueDrinks,
    required int totalGoalsMet,
    required int totalDrinksLogged,
  }) {
    return all
        .where((t) => t.unlockCondition.isUnlocked(
              recordStreak: recordStreak,
              totalDaysLogged: totalDaysLogged,
              completedChallenges: completedChallenges,
              totalOzConsumed: totalOzConsumed,
              totalHealthyPicks: totalHealthyPicks,
              uniqueDrinks: uniqueDrinks,
              totalGoalsMet: totalGoalsMet,
              totalDrinksLogged: totalDrinksLogged,
            ))
        .length;
  }
}
