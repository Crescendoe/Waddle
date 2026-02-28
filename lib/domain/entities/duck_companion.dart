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
    required int totalHealthyPicks,
    required int totalGoalsMet,
    required int totalDrinksLogged,
    required int uniqueDrinks,
    required List<bool> challengeActive,
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
      case DuckUnlockType.totalHealthyPicks:
        return totalHealthyPicks >= value;
      case DuckUnlockType.totalGoalsMet:
        return totalGoalsMet >= value;
      case DuckUnlockType.totalDrinksLogged:
        return totalDrinksLogged >= value;
      case DuckUnlockType.uniqueDrinks:
        return uniqueDrinks >= value;
      case DuckUnlockType.challengeSpecific:
        return value >= 0 &&
            value < challengeActive.length &&
            challengeActive[value];
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
  totalHealthyPicks,
  totalGoalsMet,
  totalDrinksLogged,
  uniqueDrinks,

  /// Unlocked by completing a specific challenge (value = challenge index).
  challengeSpecific,
}

enum DuckRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

extension DuckRarityExtension on DuckRarity {
  Color get color {
    switch (this) {
      case DuckRarity.common:
        return const Color(0xFF78909C);
      case DuckRarity.uncommon:
        return const Color(0xFF66BB6A);
      case DuckRarity.rare:
        return const Color(0xFF42A5F5);
      case DuckRarity.epic:
        return const Color(0xFFAB47BC);
      case DuckRarity.legendary:
        return const Color(0xFFFFB300);
    }
  }

  String get label {
    switch (this) {
      case DuckRarity.common:
        return 'Common';
      case DuckRarity.uncommon:
        return 'Uncommon';
      case DuckRarity.rare:
        return 'Rare';
      case DuckRarity.epic:
        return 'Epic';
      case DuckRarity.legendary:
        return 'Legendary';
    }
  }
}

/// All 24 collectible ducks
class DuckCompanions {
  DuckCompanions._();

  static const List<DuckCompanion> all = [
    // ═══════════════════════════════════════════════════════════════════
    // REGULAR PROGRESSION (12 ducks)
    // ═══════════════════════════════════════════════════════════════════

    // ── Streak milestones (4) ────────────────────────────────────────
    DuckCompanion(
      index: 0,
      name: 'Puddle',
      description: 'Takes its first brave steps into the water. '
          'Every journey begins with a single splash.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 3,
        displayText: 'Reach a 3-day streak',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFF90CAF9), // light blue
    ),
    DuckCompanion(
      index: 1,
      name: 'Ripple',
      description: 'Creates gentle ripples wherever it goes. '
          'Small actions, big waves.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 7,
        displayText: 'Reach a 7-day streak',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFF80CBC4), // teal
    ),
    DuckCompanion(
      index: 2,
      name: 'Current',
      description: 'Rides the current with unwavering focus. '
          'Nothing can divert this duck from its path.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 30,
        displayText: 'Reach a 30-day streak',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFF1E88E5), // vivid blue
    ),
    DuckCompanion(
      index: 3,
      name: 'Tidal',
      description: 'Commands the ebb and flow of the tides. '
          'Two months of relentless dedication.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 60,
        displayText: 'Reach a 60-day streak',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFF7C4DFF), // deep purple
    ),

    // ── Total water volume (3) ───────────────────────────────────────
    DuckCompanion(
      index: 4,
      name: 'Dewdrop',
      description: 'A tiny drop that\'s part of something bigger. '
          'Every ounce adds up.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 500,
        displayText: 'Drink 500 oz total',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFFB3E5FC), // pale cyan
    ),
    DuckCompanion(
      index: 5,
      name: 'Brook',
      description: 'A babbling brook of steady dedication. '
          'Always flowing, never stopping.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 2000,
        displayText: 'Drink 2,000 oz total',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF26A69A), // deep teal
    ),
    DuckCompanion(
      index: 6,
      name: 'Cascade',
      description: 'An unstoppable cascade of pure hydration. '
          'The sound of ten thousand ounces.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 10000,
        displayText: 'Drink 10,000 oz total',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFF00ACC1), // cyan
    ),

    // ── Healthy beverages (2) ────────────────────────────────────────
    DuckCompanion(
      index: 7,
      name: 'Sprout',
      description: 'Growing strong on nature\'s finest beverages. '
          'Clean sipping, clear thinking.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalHealthyPicks,
        value: 25,
        displayText: 'Log 25 healthy drinks',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFFA5D6A7), // soft green
    ),
    DuckCompanion(
      index: 8,
      name: 'Botanist',
      description: 'Studies every leaf and petal in the pond. '
          'An expert in the finest drinks nature offers.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalHealthyPicks,
        value: 100,
        displayText: 'Log 100 healthy drinks',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF66BB6A), // bright green
    ),

    // ── Goals met (2) ────────────────────────────────────────────────
    DuckCompanion(
      index: 9,
      name: 'Bullseye',
      description: 'Always hits the daily mark. '
          'Ten goals down, many more to go.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalGoalsMet,
        value: 10,
        displayText: 'Meet your daily goal 10 times',
      ),
      rarity: DuckRarity.common,
      tintColor: Color(0xFFEF5350), // bold red
    ),
    DuckCompanion(
      index: 10,
      name: 'Marksman',
      description: 'One hundred perfect days and counting. '
          'Precision hydration at its finest.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalGoalsMet,
        value: 100,
        displayText: 'Meet your daily goal 100 times',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFFFF7043), // deep orange
    ),

    // ── Drinks logged (1) ────────────────────────────────────────────
    DuckCompanion(
      index: 11,
      name: 'Nightingale',
      description: 'Sings the song of a thousand sips. '
          'Five hundred drinks — each one a note in the melody.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalDrinksLogged,
        value: 500,
        displayText: 'Log 500 drinks total',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFFF48FB1), // bubblegum pink
    ),

    // ═══════════════════════════════════════════════════════════════════
    // CHALLENGE-SPECIFIC (6 ducks — one per challenge)
    // ═══════════════════════════════════════════════════════════════════

    DuckCompanion(
      index: 12,
      name: 'Purist',
      description: 'Drank nothing but water for two full weeks. '
          'The purest duck in the pond.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengeSpecific,
        value: 0,
        displayText: 'Complete "Nothing But Water"',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF42A5F5), // water blue
    ),
    DuckCompanion(
      index: 13,
      name: 'Brewmaster',
      description: 'Steeped in knowledge and flavor. '
          'Fourteen days of tea — a true connoisseur.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengeSpecific,
        value: 1,
        displayText: 'Complete "Tea Time"',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF66BB6A), // tea green
    ),
    DuckCompanion(
      index: 14,
      name: 'Serene',
      description: 'Found peace beyond the buzz. '
          'Two weeks without caffeine — clear-headed and calm.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengeSpecific,
        value: 2,
        displayText: 'Complete "Caffeine Cut"',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFF8D6E63), // coffee brown
    ),
    DuckCompanion(
      index: 15,
      name: 'Frostbite',
      description: 'Cold and crisp — no sugar needed. '
          'Fourteen sugar-free days of icy refreshment.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengeSpecific,
        value: 3,
        displayText: 'Complete "Sugar-Free Sips"',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFFEF5350), // cherry red
    ),
    DuckCompanion(
      index: 16,
      name: 'Herbivore',
      description: 'Swapped the cream for green. '
          'Two weeks dairy-free — thriving on plants.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengeSpecific,
        value: 4,
        displayText: 'Complete "Dairy-Free Refresh"',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFFFFA726), // orange
    ),
    DuckCompanion(
      index: 17,
      name: 'Elixir',
      description: 'Brews potions of pure vitality. '
          'Fourteen days packed with vitamins and minerals.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.challengeSpecific,
        value: 5,
        displayText: 'Complete "Vitamin Vitality"',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFFAB47BC), // purple
    ),

    // ═══════════════════════════════════════════════════════════════════
    // VERY UNIQUE (6 ducks)
    // ═══════════════════════════════════════════════════════════════════

    DuckCompanion(
      index: 18,
      name: 'Verdant',
      description: 'So healthy it practically photosynthesizes. '
          'Three hundred healthy picks and counting.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalHealthyPicks,
        value: 300,
        displayText: 'Log 300 healthy drinks',
      ),
      rarity: DuckRarity.rare,
      tintColor: Color(0xFF2E7D32), // forest green
    ),
    DuckCompanion(
      index: 19,
      name: 'Leviathan',
      description: 'A deep-sea titan of relentless logging. '
          'Two thousand drinks — it never stops.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalDrinksLogged,
        value: 2000,
        displayText: 'Log 2,000 drinks total',
      ),
      rarity: DuckRarity.epic,
      tintColor: Color(0xFF0D47A1), // navy
    ),
    DuckCompanion(
      index: 20,
      name: 'Mixologist',
      description: 'A true connoisseur who\'s tasted every stream. '
          'Twelve different beverages and always exploring.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.uniqueDrinks,
        value: 12,
        displayText: 'Try 12 different drinks',
      ),
      rarity: DuckRarity.uncommon,
      tintColor: Color(0xFFAB47BC), // purple
    ),
    DuckCompanion(
      index: 21,
      name: 'Marathon',
      description: 'The streak that defies all odds. '
          'Two hundred days without missing a single one.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.streak,
        value: 200,
        displayText: 'Reach a 200-day streak',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFFFFB300), // golden amber
    ),
    DuckCompanion(
      index: 22,
      name: 'Zenith',
      description: 'A full year of unwavering commitment. '
          'Three hundred and sixty-five days at the peak.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.consecutiveDays,
        value: 365,
        displayText: 'Log water for 365 days',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFF00BFA5), // aqua gold-green
    ),
    DuckCompanion(
      index: 23,
      name: 'Kraken',
      description: 'A mythical beast of unfathomable hydration. '
          'Fifty thousand ounces consumed — truly monstrous.',
      unlockCondition: DuckUnlockCondition(
        type: DuckUnlockType.totalOzConsumed,
        value: 50000,
        displayText: 'Drink 50,000 oz total',
      ),
      rarity: DuckRarity.legendary,
      tintColor: Color(0xFF1A237E), // midnight blue
    ),
  ];

  static int countUnlocked({
    required int currentStreak,
    required int recordStreak,
    required int completedChallenges,
    required double totalWaterConsumed,
    required int totalDaysLogged,
    required int totalHealthyPicks,
    required int totalGoalsMet,
    required int totalDrinksLogged,
    required int uniqueDrinks,
    required List<bool> challengeActive,
  }) {
    return all
        .where((duck) => duck.unlockCondition.isUnlocked(
              currentStreak: currentStreak,
              recordStreak: recordStreak,
              completedChallenges: completedChallenges,
              totalWaterConsumed: totalWaterConsumed,
              totalDaysLogged: totalDaysLogged,
              totalHealthyPicks: totalHealthyPicks,
              totalGoalsMet: totalGoalsMet,
              totalDrinksLogged: totalDrinksLogged,
              uniqueDrinks: uniqueDrinks,
              challengeActive: challengeActive,
            ))
        .length;
  }
}
