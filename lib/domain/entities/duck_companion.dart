import 'package:equatable/equatable.dart';

/// A collectible duck companion with unlock conditions
class DuckCompanion extends Equatable {
  final int index;
  final String name;
  final String description;
  final DuckUnlockCondition unlockCondition;
  final DuckRarity rarity;

  const DuckCompanion({
    required this.index,
    required this.name,
    required this.description,
    required this.unlockCondition,
    required this.rarity,
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
