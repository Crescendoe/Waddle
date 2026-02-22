import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A collectible duck companion with unlock conditions
class DuckCompanion extends Equatable {
  final int index;
  final String name;
  final String description;
  final DuckUnlockCondition unlockCondition;
  final DuckRarity rarity;

  /// The color used to tint wade_floating.png for this duck.
  final Color tintColor;

  const DuckCompanion({
    required this.index,
    required this.name,
    required this.description,
    required this.unlockCondition,
    required this.rarity,
    required this.tintColor,
  });

  @override
  List<Object?> get props => [index, name];
}

/// How a duck is unlocked
class DuckUnlockCondition extends Equatable {
  final DuckUnlockType type;
  final int value;
  final String displayText;

  const DuckUnlockCondition({
    required this.type,
    required this.value,
    required this.displayText,
  });

  bool isUnlocked({
    required int currentStreak,
    required int recordStreak,
    required int completedChallenges,
    required double totalWaterConsumed,
    required int totalDaysLogged,
  }) {
    switch (type) {
      case DuckUnlockType.streak:
        return recordStreak >= value;
      case DuckUnlockType.consecutiveDays:
        return totalDaysLogged >= value;
      case DuckUnlockType.challengesCompleted:
        return completedChallenges >= value;
      case DuckUnlockType.totalOzConsumed:
        return totalWaterConsumed >= value;
    }
  }

  @override
  List<Object?> get props => [type, value];
}

enum DuckUnlockType {
  streak,
  consecutiveDays,
  challengesCompleted,
  totalOzConsumed,
}

enum DuckRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// All collectible ducks
class DuckCompanions {
  DuckCompanions._();

  static const List<DuckCompanion> all = [
    // Streak ducks
    DuckCompanion(
      index: 0,
      name: 'Puddle',
      description: 'A cheerful duck who loves splashing in puddles.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 5,
        displayText: 'Reach a 5-day streak',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFF90CAF9), // light blue
    ),
    DuckCompanion(
      index: 1,
      name: 'Ripple',
      description: 'Creates gentle ripples wherever it goes.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 10,
        displayText: 'Reach a 10-day streak',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFF80CBC4), // teal
    ),
    DuckCompanion(
      index: 2,
      name: 'Splash',
      description: 'An energetic duck who makes a big splash!',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 20,
        displayText: 'Reach a 20-day streak',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF4FC3F7), // sky blue
    ),
    DuckCompanion(
      index: 3,
      name: 'Tide',
      description: 'Goes with the flow and rides the tide.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 30,
        displayText: 'Reach a 30-day streak',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFF1E88E5), // vivid blue
    ),
    DuckCompanion(
      index: 4,
      name: 'Tsunami',
      description: 'A powerful duck who commands the waves!',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 60,
        displayText: 'Reach a 60-day streak',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFF7C4DFF), // deep purple
    ),
    DuckCompanion(
      index: 5,
      name: 'Poseidon',
      description: 'The legendary ruler of all waters.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 120,
        displayText: 'Reach a 120-day streak',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFF00BFA5), // aqua gold-green
    ),
    DuckCompanion(
      index: 6,
      name: 'Eternal Quacker',
      description: 'Has been drinking water since the dawn of time.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 365,
        displayText: 'Reach a 365-day streak',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFFFFD700), // pure gold
    ),

    // Consecutive days ducks
    DuckCompanion(
      index: 7,
      name: 'Logger',
      description: 'Keeps a careful log of every sip.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.consecutiveDays,
        value: 7,
        displayText: 'Log water for 7 days',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFFA5D6A7), // soft green
    ),
    DuckCompanion(
      index: 8,
      name: 'Scribe',
      description: 'A meticulous record keeper.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.consecutiveDays,
        value: 14,
        displayText: 'Log water for 14 days',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFFBCAAA4), // warm taupe
    ),
    DuckCompanion(
      index: 9,
      name: 'Chronicler',
      description: 'Documents the history of hydration.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.consecutiveDays,
        value: 21,
        displayText: 'Log water for 21 days',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF66BB6A), // bright green
    ),
    DuckCompanion(
      index: 10,
      name: 'Historian',
      description: 'A walking encyclopedia of water wisdom.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.consecutiveDays,
        value: 28,
        displayText: 'Log water for 28 days',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFF5C6BC0), // indigo
    ),
    DuckCompanion(
      index: 11,
      name: 'Archivist',
      description: 'Has the most impressive hydration archives.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.consecutiveDays,
        value: 50,
        displayText: 'Log water for 50 days',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFFAB47BC), // purple
    ),

    // Challenge ducks
    DuckCompanion(
      index: 12,
      name: 'Crystal Clear',
      description: 'Pure as water itself — Nothing But Water champion.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengesCompleted,
        value: 1,
        displayText: 'Complete 1 challenge',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFFE0F7FA), // crystal / ice white-blue
    ),
    DuckCompanion(
      index: 13,
      name: 'Challenger',
      description: 'Never backs down from a hydration challenge.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengesCompleted,
        value: 3,
        displayText: 'Complete 3 challenges',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFFEF5350), // bold red
    ),
    DuckCompanion(
      index: 14,
      name: 'Champion',
      description: 'The ultimate challenge conqueror!',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengesCompleted,
        value: 6,
        displayText: 'Complete all 6 challenges',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFFFF6F00), // fiery amber
    ),

    // Total oz consumed ducks
    DuckCompanion(
      index: 15,
      name: 'Sipper',
      description: 'Takes small sips but stays consistent.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 100,
        displayText: 'Drink 100 oz total',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFFB3E5FC), // pale cyan
    ),
    DuckCompanion(
      index: 16,
      name: 'Gulper',
      description: 'Drinks with enthusiasm and gusto!',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 500,
        displayText: 'Drink 500 oz total',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF26A69A), // deep teal
    ),
    DuckCompanion(
      index: 17,
      name: 'Stream',
      description: 'A steady stream of hydration.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 1000,
        displayText: 'Drink 1,000 oz total',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFF42A5F5), // calm blue
    ),
    DuckCompanion(
      index: 18,
      name: 'River',
      description: 'Flows with the power of a mighty river.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 3000,
        displayText: 'Drink 3,000 oz total',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFF0D47A1), // navy
    ),
    DuckCompanion(
      index: 19,
      name: 'Waterfall',
      description: 'An awe-inspiring cascade of hydration.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 5000,
        displayText: 'Drink 5,000 oz total',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFF00ACC1), // cyan
    ),
    DuckCompanion(
      index: 20,
      name: 'Ocean',
      description: 'Contains multitudes of water.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 10000,
        displayText: 'Drink 10,000 oz total',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFF1A237E), // midnight blue
    ),

    // Bonus rare ducks
    DuckCompanion(
      index: 21,
      name: 'Golden Quack',
      description: 'The rarest duck, forged in liquid gold.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 100,
        displayText: 'Reach a 100-day streak',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFFFFB300), // golden amber
    ),
    DuckCompanion(
      index: 22,
      name: 'Bubble',
      description: 'Floats along happily in a bubble of joy.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 2000,
        displayText: 'Drink 2,000 oz total',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFFF48FB1), // bubblegum pink
    ),
    DuckCompanion(
      index: 23,
      name: 'Hydra',
      description: 'The mythical multi-headed hydration duck!',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengesCompleted,
        value: 4,
        displayText: 'Complete 4 challenges',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFF8E24AA), // magenta purple
    ),
  ];

  static int countUnlocked({
    required int currentStreak,
    required int recordStreak,
    required int completedChallenges,
    required double totalWaterConsumed,
    required int totalDaysLogged,
  }) {
    return all
        .where((duck) => duck.unlockCondition.isUnlocked(
              currentStreak: currentStreak,
              recordStreak: recordStreak,
              completedChallenges: completedChallenges,
              totalWaterConsumed: totalWaterConsumed,
              totalDaysLogged: totalDaysLogged,
            ))
        .length;
  }
}
