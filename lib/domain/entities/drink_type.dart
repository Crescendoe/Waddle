import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Health tier — independent of hydration science.
/// Encourages healthier beverage choices via UI badges and wellness bonuses.
enum HealthTier {
  /// Pure hydration with no downsides (water, herbal tea)
  excellent('Excellent', Color(0xFF2E7D32), Icons.eco_rounded),

  /// Healthy beverages with minor considerations (coffee, milk, green tea)
  good('Good', Color(0xFF558B2F), Icons.thumb_up_alt_rounded),

  /// Nutritious but watch sugar/calories (juice, smoothie, sports drink)
  fair('Fair', Color(0xFFF9A825), Icons.info_outline_rounded),

  /// Hydrates but has health trade-offs (soda, energy drink, milkshake)
  limit('Limit', Color(0xFFE65100), Icons.warning_amber_rounded);

  final String label;
  final Color color;
  final IconData icon;
  const HealthTier(this.label, this.color, this.icon);
}

/// Drink type definition with hydration ratio and health tier
class DrinkType extends Equatable {
  final String name;
  final IconData icon;
  final Color color;
  final double waterRatio; // 1.0 = 100% water equivalent
  final DrinkCategory category;
  final HealthTier healthTier;
  final bool hasDisclaimer;
  final String? disclaimerText;

  const DrinkType({
    required this.name,
    required this.icon,
    required this.color,
    required this.waterRatio,
    required this.category,
    this.healthTier = HealthTier.good,
    this.hasDisclaimer = false,
    this.disclaimerText,
  });

  double waterEquivalent(double amountOz) => amountOz * waterRatio;

  @override
  List<Object?> get props => [name, waterRatio, category, healthTier];
}

enum DrinkCategory {
  water,
  tea,
  coffee,
  juice,
  dairy,
  dairyFree,
  carbonated,
  blended,
  sports,
  other,
}

/// All available drink types in the app.
///
/// Water ratios based on:
/// - Maughan et al. (2016) Beverage Hydration Index (BHI), Am J Clin Nutr
///   → cola, diet cola, tea, coffee, OJ, sparkling water, sports drinks all
///     produced urine output NOT significantly different from still water.
///   → Milk (BHI ~1.5) retains MORE fluid than water.
/// - Mayo Clinic: "Tea, coffee and milk help keep you hydrated."
/// - Small discounts applied for health-guidance on sugary/stimulant beverages
///   even when BHI ≈ 1.0, to gently encourage healthier choices.
class DrinkTypes {
  DrinkTypes._();

  static const List<DrinkType> all = [
    // Water category
    DrinkType(
      name: 'Water',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF1565C0),
      waterRatio: 1.0,
      category: DrinkCategory.water,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Sparkling Water',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFF00838F),
      waterRatio: 1.0,
      category: DrinkCategory.water,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Coconut Water',
      icon: Icons.beach_access_rounded,
      color: Color(0xFF00897B),
      waterRatio: 1.0,
      category: DrinkCategory.water,
      healthTier: HealthTier.excellent,
    ),

    // Tea category
    DrinkType(
      name: 'Black Tea',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF4E342E),
      waterRatio: 0.97,
      category: DrinkCategory.tea,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Green Tea',
      icon: Icons.eco_rounded,
      color: Color(0xFF388E3C),
      waterRatio: 0.97,
      category: DrinkCategory.tea,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Herbal Tea',
      icon: Icons.spa_rounded,
      color: Color(0xFF689F38),
      waterRatio: 1.0,
      category: DrinkCategory.tea,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Matcha',
      icon: Icons.grass_rounded,
      color: Color(0xFF00C853),
      waterRatio: 0.96,
      category: DrinkCategory.tea,
      healthTier: HealthTier.excellent,
    ),

    // Coffee category
    DrinkType(
      name: 'Coffee',
      icon: Icons.coffee_rounded,
      color: Color(0xFF5D4037),
      waterRatio: 0.96,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Coffee hydrates nearly as well as water (BHI ≈ 1.0). Up to 400 mg caffeine/day is safe for most adults. — Mayo Clinic',
    ),
    DrinkType(
      name: 'Decaf Coffee',
      icon: Icons.coffee_outlined,
      color: Color(0xFF6D4C41),
      waterRatio: 0.99,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Latte',
      icon: Icons.local_cafe_outlined,
      color: Color(0xFF795548),
      waterRatio: 0.97,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Hot Chocolate',
      icon: Icons.coffee_rounded,
      color: Color(0xFFBF360C),
      waterRatio: 0.90,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Hot chocolate often contains added sugar. Choose low-sugar options when possible.',
    ),

    // Juice category
    DrinkType(
      name: 'Juice',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFE65100),
      waterRatio: 0.95,
      category: DrinkCategory.juice,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Fruit juice has vitamins but also natural sugars — similar calories to soda. Whole fruit is a healthier choice.',
    ),
    DrinkType(
      name: 'Lemonade',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF9A825),
      waterRatio: 0.90,
      category: DrinkCategory.juice,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Lemonade is refreshing but typically high in added sugar. Try sparkling water with lemon instead.',
    ),

    // Dairy category
    DrinkType(
      name: 'Milk',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF78909C),
      waterRatio: 1.0,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Skim Milk',
      icon: Icons.local_drink_outlined,
      color: Color(0xFF7986CB),
      waterRatio: 1.0,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Yogurt Drink',
      icon: Icons.icecream_rounded,
      color: Color(0xFFE64A19),
      waterRatio: 0.90,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Milkshake',
      icon: Icons.blender_rounded,
      color: Color(0xFF7B1FA2),
      waterRatio: 0.75,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Milkshakes are high in sugar and calories. Enjoy occasionally — try a protein shake for a healthier alternative.',
    ),

    // Dairy-free category
    DrinkType(
      name: 'Almond Milk',
      icon: Icons.nature_rounded,
      color: Color(0xFFEC407A),
      waterRatio: 0.95,
      category: DrinkCategory.dairyFree,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Oat Milk',
      icon: Icons.grain_rounded,
      color: Color(0xFF8D6E63),
      waterRatio: 0.95,
      category: DrinkCategory.dairyFree,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Soy Milk',
      icon: Icons.emoji_nature_rounded,
      color: Color(0xFFFFB300),
      waterRatio: 0.95,
      category: DrinkCategory.dairyFree,
      healthTier: HealthTier.good,
    ),

    // Carbonated category
    DrinkType(
      name: 'Soda',
      icon: Icons.sports_bar_rounded,
      color: Color(0xFFD32F2F),
      waterRatio: 0.85,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Soda hydrates similarly to water (BHI study), but high sugar adds empty calories. Water is the healthier choice.',
    ),
    DrinkType(
      name: 'Diet Soda',
      icon: Icons.no_drinks_rounded,
      color: Color(0xFFC2185B),
      waterRatio: 0.95,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Diet soda hydrates well but artificial sweeteners may affect gut health. Water or sparkling water is preferred.',
    ),
    DrinkType(
      name: 'Energy Drink',
      icon: Icons.bolt_rounded,
      color: Color(0xFFD32F2F),
      waterRatio: 0.80,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Energy drinks contain high caffeine and often sugar. Limit to 1-2/day. Up to 400 mg caffeine/day is considered safe. — Mayo Clinic',
    ),

    // Blended category
    DrinkType(
      name: 'Smoothie',
      icon: Icons.blender_rounded,
      color: Color(0xFF7B1FA2),
      waterRatio: 0.90,
      category: DrinkCategory.blended,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Smoothies can be nutritious but watch added sugars. Use whole fruits, veggies, and minimal sweeteners.',
    ),
    DrinkType(
      name: 'Protein Shake',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFFF6D00),
      waterRatio: 0.85,
      category: DrinkCategory.blended,
      healthTier: HealthTier.good,
    ),

    // Sports category
    DrinkType(
      name: 'Sports Drink',
      icon: Icons.sports_handball_rounded,
      color: Color(0xFF1565C0),
      waterRatio: 0.95,
      category: DrinkCategory.sports,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Sports drinks hydrate well due to electrolytes and carbs. Best during prolonged exercise (>60 min). For casual use, water suffices.',
    ),

    // Other
    DrinkType(
      name: 'Soup',
      icon: Icons.ramen_dining_rounded,
      color: Color(0xFFD50000),
      waterRatio: 0.85,
      category: DrinkCategory.other,
      healthTier: HealthTier.good,
    ),
  ];

  /// Get drinks allowed for a specific challenge
  static List<DrinkType> forChallenge(int challengeIndex) {
    switch (challengeIndex) {
      case 0: // Nothing But Water
        return all.where((d) => d.category == DrinkCategory.water).toList();
      case 1: // Tea Time - all drinks allowed but must include tea
        return all;
      case 2: // Caffeine Cut - exclude high caffeine
        return all
            .where((d) =>
                d.category != DrinkCategory.coffee &&
                d.name != 'Energy Drink' &&
                d.name != 'Black Tea' &&
                d.name != 'Matcha')
            .toList();
      case 3: // Sugar-Free Sips
        return all
            .where((d) =>
                d.name != 'Soda' &&
                d.name != 'Juice' &&
                d.name != 'Lemonade' &&
                d.name != 'Energy Drink' &&
                d.name != 'Hot Chocolate' &&
                d.name != 'Milkshake')
            .toList();
      case 4: // Dairy-Free Refresh
        return all.where((d) => d.category != DrinkCategory.dairy).toList();
      case 5: // Vitamin Vitality - all drinks
        return all;
      default:
        return all;
    }
  }

  static DrinkType? byName(String name) {
    try {
      return all.firstWhere((d) => d.name == name);
    } catch (_) {
      return null;
    }
  }
}
