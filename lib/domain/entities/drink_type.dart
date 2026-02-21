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
  alcohol,
  other,
}

/// All available drink types in the app.
///
/// Water ratios based on:
/// - Maughan et al. (2016) Beverage Hydration Index (BHI), Am J Clin Nutr
///   → most beverages (cola, tea, coffee, OJ, sparkling water, sports drinks)
///     produced urine output NOT significantly different from still water.
///   → Milk (BHI ≈ 1.5) retains MORE fluid than water due to fat, protein, lactose.
/// - Mayo Clinic: "Tea, coffee and milk help keep you hydrated."
/// - Alcohol is a diuretic — beer (BHI ≈ 0.93), wine and spirits increasingly so.
/// - Small discounts applied for sugary/stimulant beverages for health guidance
///   even when BHI ≈ 1.0.
///
/// Health tiers based on:
/// - WHO dietary guidelines on sugar (< 10% kcal/day)
/// - AHA added-sugar limits (< 36 g/day men, < 25 g/day women)
/// - USDA Dietary Guidelines 2020-2025
/// - Mayo Clinic caffeine guidance (≤ 400 mg/day)
class DrinkTypes {
  DrinkTypes._();

  static const List<DrinkType> all = [
    // ─── Water ───────────────────────────────────────────────
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
      hasDisclaimer: true,
      disclaimerText:
          'Coconut water is rich in potassium and electrolytes. Great post-workout hydrator with natural sugars.',
    ),
    DrinkType(
      name: 'Mineral Water',
      icon: Icons.waves_rounded,
      color: Color(0xFF0277BD),
      waterRatio: 1.0,
      category: DrinkCategory.water,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Infused Water',
      icon: Icons.local_florist_rounded,
      color: Color(0xFF26A69A),
      waterRatio: 1.0,
      category: DrinkCategory.water,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Electrolyte Water',
      icon: Icons.bolt_rounded,
      color: Color(0xFF0091EA),
      waterRatio: 1.0,
      category: DrinkCategory.water,
      healthTier: HealthTier.excellent,
    ),

    // ─── Tea ─────────────────────────────────────────────────
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
    DrinkType(
      name: 'Oolong Tea',
      icon: Icons.local_cafe_outlined,
      color: Color(0xFF6D4C41),
      waterRatio: 0.97,
      category: DrinkCategory.tea,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'White Tea',
      icon: Icons.filter_vintage_rounded,
      color: Color(0xFFA5D6A7),
      waterRatio: 0.98,
      category: DrinkCategory.tea,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Chai Tea',
      icon: Icons.emoji_food_beverage_rounded,
      color: Color(0xFF8D6E63),
      waterRatio: 0.95,
      category: DrinkCategory.tea,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Iced Tea',
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF00695C),
      waterRatio: 0.95,
      category: DrinkCategory.tea,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Unsweetened iced tea hydrates well. Sweetened versions can have as much sugar as soda.',
    ),
    DrinkType(
      name: 'Sweet Tea',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFFFF8F00),
      waterRatio: 0.90,
      category: DrinkCategory.tea,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Sweet tea is high in added sugar (22–33 g per 8 oz). Try reducing sweetness gradually.',
    ),
    DrinkType(
      name: 'Bubble Tea',
      icon: Icons.circle_rounded,
      color: Color(0xFFAB47BC),
      waterRatio: 0.80,
      category: DrinkCategory.tea,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Bubble tea can contain 300+ calories and 50+ g sugar from tapioca pearls and syrup. Enjoy as an occasional treat.',
    ),
    DrinkType(
      name: 'Kombucha',
      icon: Icons.science_rounded,
      color: Color(0xFFAED581),
      waterRatio: 0.95,
      category: DrinkCategory.tea,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Kombucha contains probiotics and small amounts of alcohol (< 0.5%). Watch for added sugar in commercial brands.',
    ),

    // ─── Coffee ──────────────────────────────────────────────
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
      name: 'Espresso',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF3E2723),
      waterRatio: 0.94,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'A double espresso has ~126 mg caffeine. Hydrates well but typically small serving (2 oz).',
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
      name: 'Cappuccino',
      icon: Icons.coffee_maker_rounded,
      color: Color(0xFF8D6E63),
      waterRatio: 0.96,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Americano',
      icon: Icons.coffee_rounded,
      color: Color(0xFF4E342E),
      waterRatio: 0.96,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Cold Brew',
      icon: Icons.ac_unit_rounded,
      color: Color(0xFF37474F),
      waterRatio: 0.95,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Cold brew has ~200 mg caffeine per 8 oz (67% more than regular coffee). Great hydration but watch caffeine intake.',
    ),
    DrinkType(
      name: 'Mocha',
      icon: Icons.coffee_rounded,
      color: Color(0xFF6D4C41),
      waterRatio: 0.90,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Mochas contain chocolate syrup adding 20–30 g sugar. Ask for less syrup or sugar-free options.',
    ),
    DrinkType(
      name: 'Frappuccino',
      icon: Icons.icecream_rounded,
      color: Color(0xFFAB47BC),
      waterRatio: 0.80,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Blended coffee drinks can exceed 400 calories and 60 g sugar. Enjoy as an occasional treat.',
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
          'Hot chocolate often contains 20–30 g added sugar. Choose low-sugar or dark cocoa options when possible.',
    ),
    DrinkType(
      name: 'Macchiato',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFF5D4037),
      waterRatio: 0.95,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Flat White',
      icon: Icons.local_cafe_outlined,
      color: Color(0xFF8D6E63),
      waterRatio: 0.96,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Affogato',
      icon: Icons.icecream_outlined,
      color: Color(0xFF4E342E),
      waterRatio: 0.75,
      category: DrinkCategory.coffee,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Affogato includes ice cream — more dessert than drink. Log the liquid portion for hydration tracking.',
    ),

    // ─── Juice ───────────────────────────────────────────────
    DrinkType(
      name: 'Orange Juice',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFE65100),
      waterRatio: 0.95,
      category: DrinkCategory.juice,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'OJ is rich in vitamin C and potassium. BHI ≈ 1.0, but 8 oz has ~22 g natural sugar. Whole oranges are healthier.',
    ),
    DrinkType(
      name: 'Apple Juice',
      icon: Icons.lunch_dining_rounded,
      color: Color(0xFFFBC02D),
      waterRatio: 0.95,
      category: DrinkCategory.juice,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Apple juice has ~24 g sugar per 8 oz. Look for 100% juice with no added sugar.',
    ),
    DrinkType(
      name: 'Cranberry Juice',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFC62828),
      waterRatio: 0.93,
      category: DrinkCategory.juice,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Cranberry juice supports urinary health. Cocktail versions can have 30+ g added sugar — choose 100% juice.',
    ),
    DrinkType(
      name: 'Grape Juice',
      icon: Icons.local_bar_outlined,
      color: Color(0xFF6A1B9A),
      waterRatio: 0.94,
      category: DrinkCategory.juice,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Grape juice contains antioxidants (resveratrol) but also ~36 g sugar per 8 oz.',
    ),
    DrinkType(
      name: 'Tomato Juice',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFD32F2F),
      waterRatio: 0.97,
      category: DrinkCategory.juice,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Tomato juice is low-calorie and rich in lycopene. Watch sodium — choose low-sodium versions.',
    ),
    DrinkType(
      name: 'Vegetable Juice',
      icon: Icons.grass_rounded,
      color: Color(0xFF2E7D32),
      waterRatio: 0.97,
      category: DrinkCategory.juice,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Vegetable juice is nutrient-dense and low in sugar. Watch sodium levels in commercial brands.',
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
          'Lemonade is refreshing but typically high in added sugar (25–40 g per 8 oz). Try sparkling water with lemon instead.',
    ),
    DrinkType(
      name: 'Green Juice',
      icon: Icons.eco_rounded,
      color: Color(0xFF558B2F),
      waterRatio: 0.96,
      category: DrinkCategory.juice,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Pineapple Juice',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFFFB300),
      waterRatio: 0.94,
      category: DrinkCategory.juice,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Pineapple juice contains bromelain and vitamin C. About 25 g sugar per 8 oz — enjoy in moderation.',
    ),
    DrinkType(
      name: 'Watermelon Juice',
      icon: Icons.water_drop_outlined,
      color: Color(0xFFEF5350),
      waterRatio: 0.97,
      category: DrinkCategory.juice,
      healthTier: HealthTier.good,
    ),

    // ─── Dairy ───────────────────────────────────────────────
    DrinkType(
      name: 'Whole Milk',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF78909C),
      waterRatio: 1.0,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Milk has a BHI of ~1.5 — it retains more fluid than water due to fat, protein, and lactose. Excellent hydrator.',
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
      name: '2% Milk',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF90A4AE),
      waterRatio: 1.0,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Chocolate Milk',
      icon: Icons.local_drink_rounded,
      color: Color(0xFF6D4C41),
      waterRatio: 0.95,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Chocolate milk is an excellent post-exercise recovery drink (protein + carbs). ~24 g sugar per 8 oz.',
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
      name: 'Kefir',
      icon: Icons.science_outlined,
      color: Color(0xFFEF9A9A),
      waterRatio: 0.90,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Kefir is rich in probiotics, protein, and calcium. Supports gut and bone health.',
    ),
    DrinkType(
      name: 'Lassi',
      icon: Icons.local_drink_rounded,
      color: Color(0xFFFFF176),
      waterRatio: 0.88,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Lassi (yogurt-based) is probiotic-rich. Sweet versions can be high in sugar — mango lassi has ~30 g.',
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
          'Milkshakes average 400–800 calories with 50+ g sugar. Enjoy rarely — try a protein shake instead.',
    ),
    DrinkType(
      name: 'Eggnog',
      icon: Icons.egg_rounded,
      color: Color(0xFFFFF9C4),
      waterRatio: 0.70,
      category: DrinkCategory.dairy,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Eggnog is very calorie-dense (350+ cal/8 oz) with saturated fat and sugar. A seasonal treat.',
    ),

    // ─── Dairy-Free ──────────────────────────────────────────
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
    DrinkType(
      name: 'Cashew Milk',
      icon: Icons.nature_people_rounded,
      color: Color(0xFFBCAAA4),
      waterRatio: 0.95,
      category: DrinkCategory.dairyFree,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Rice Milk',
      icon: Icons.grain_outlined,
      color: Color(0xFFD7CCC8),
      waterRatio: 0.95,
      category: DrinkCategory.dairyFree,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Rice milk is low in protein and can be high on the glycemic index. Often fortified with calcium and vitamins.',
    ),
    DrinkType(
      name: 'Coconut Milk',
      icon: Icons.beach_access_outlined,
      color: Color(0xFF80CBC4),
      waterRatio: 0.90,
      category: DrinkCategory.dairyFree,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Hemp Milk',
      icon: Icons.park_rounded,
      color: Color(0xFF81C784),
      waterRatio: 0.95,
      category: DrinkCategory.dairyFree,
      healthTier: HealthTier.good,
    ),

    // ─── Carbonated ──────────────────────────────────────────
    DrinkType(
      name: 'Soda',
      icon: Icons.sports_bar_rounded,
      color: Color(0xFFD32F2F),
      waterRatio: 0.85,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Soda BHI ≈ 1.0, but a 12 oz can has ~39 g sugar (10 tsp). Linked to obesity, diabetes, and tooth decay. — AHA',
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
          'Diet soda hydrates well (BHI ≈ 1.0) but artificial sweeteners may impact gut microbiome and appetite. — Mayo Clinic',
    ),
    DrinkType(
      name: 'Energy Drink',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFF6D00),
      waterRatio: 0.80,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Energy drinks have 80–300 mg caffeine plus high sugar. Can cause heart palpitations and insomnia. Limit to 1/day. — Mayo Clinic',
    ),
    DrinkType(
      name: 'Tonic Water',
      icon: Icons.bubble_chart_outlined,
      color: Color(0xFF546E7A),
      waterRatio: 0.90,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Tonic water contains quinine and sugar (22 g per 8 oz). It\'s not the same as sparkling water.',
    ),
    DrinkType(
      name: 'Ginger Ale',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFFFFB74D),
      waterRatio: 0.88,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Ginger ale can soothe nausea but most brands have 20+ g sugar. Try ginger tea for a healthier alternative.',
    ),
    DrinkType(
      name: 'Club Soda',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFF90CAF9),
      waterRatio: 1.0,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.excellent,
    ),
    DrinkType(
      name: 'Root Beer',
      icon: Icons.sports_bar_outlined,
      color: Color(0xFF5D4037),
      waterRatio: 0.85,
      category: DrinkCategory.carbonated,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Root beer has ~39 g sugar per 12 oz — similar to cola. No nutritional benefit.',
    ),

    // ─── Blended ─────────────────────────────────────────────
    DrinkType(
      name: 'Smoothie',
      icon: Icons.blender_rounded,
      color: Color(0xFF7B1FA2),
      waterRatio: 0.90,
      category: DrinkCategory.blended,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Smoothies can be nutritious with whole fruits and veggies. Watch added sugars and portion size — can exceed 400 cal.',
    ),
    DrinkType(
      name: 'Green Smoothie',
      icon: Icons.eco_rounded,
      color: Color(0xFF43A047),
      waterRatio: 0.92,
      category: DrinkCategory.blended,
      healthTier: HealthTier.good,
    ),
    DrinkType(
      name: 'Protein Shake',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFFF6D00),
      waterRatio: 0.85,
      category: DrinkCategory.blended,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Protein shakes support muscle recovery. Choose options with < 5 g added sugar and 20–30 g protein.',
    ),
    DrinkType(
      name: 'Açaí Bowl Drink',
      icon: Icons.local_florist_outlined,
      color: Color(0xFF4A148C),
      waterRatio: 0.80,
      category: DrinkCategory.blended,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Açaí blends are antioxidant-rich but can be high in sugar, especially with granola and honey toppings.',
    ),
    DrinkType(
      name: 'Meal Replacement',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF757575),
      waterRatio: 0.80,
      category: DrinkCategory.blended,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Meal replacement shakes provide balanced nutrition but should not fully replace whole foods long-term.',
    ),

    // ─── Sports ──────────────────────────────────────────────
    DrinkType(
      name: 'Sports Drink',
      icon: Icons.sports_handball_rounded,
      color: Color(0xFF1565C0),
      waterRatio: 0.95,
      category: DrinkCategory.sports,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Sports drinks replenish electrolytes and carbs during intense exercise (> 60 min). For casual use, water is sufficient. — ACSM',
    ),
    DrinkType(
      name: 'Electrolyte Mix',
      icon: Icons.science_rounded,
      color: Color(0xFF0097A7),
      waterRatio: 1.0,
      category: DrinkCategory.sports,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Electrolyte mixes (Liquid IV, Nuun, etc.) improve fluid retention with minimal calories. Great for heat and exercise.',
    ),
    DrinkType(
      name: 'Pedialyte',
      icon: Icons.medical_services_rounded,
      color: Color(0xFF42A5F5),
      waterRatio: 1.0,
      category: DrinkCategory.sports,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Pedialyte is an oral rehydration solution with optimal electrolyte balance. Excellent for illness recovery.',
    ),
    DrinkType(
      name: 'Pre-Workout',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFF3D00),
      waterRatio: 0.90,
      category: DrinkCategory.sports,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Pre-workout drinks typically contain 150–300 mg caffeine, beta-alanine, and creatine. Stay within caffeine limits.',
    ),
    DrinkType(
      name: 'BCAA Drink',
      icon: Icons.fitness_center_outlined,
      color: Color(0xFF7C4DFF),
      waterRatio: 0.95,
      category: DrinkCategory.sports,
      healthTier: HealthTier.good,
    ),

    // ─── Alcohol ─────────────────────────────────────────────
    DrinkType(
      name: 'Beer',
      icon: Icons.sports_bar_rounded,
      color: Color(0xFFF57F17),
      waterRatio: 0.60,
      category: DrinkCategory.alcohol,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Beer (BHI ≈ 0.93 for low-ABV) is mildly diuretic. Higher alcohol = more dehydrating. Drink water alongside. — Maughan et al.',
    ),
    DrinkType(
      name: 'Wine',
      icon: Icons.wine_bar_rounded,
      color: Color(0xFF880E4F),
      waterRatio: 0.50,
      category: DrinkCategory.alcohol,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Wine (12–15% ABV) is a moderate diuretic. Red wine has some antioxidants, but alcohol negates hydration benefit.',
    ),
    DrinkType(
      name: 'Hard Seltzer',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFF80DEEA),
      waterRatio: 0.55,
      category: DrinkCategory.alcohol,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Hard seltzers (5% ABV) are lower calorie than beer but still diuretic. ~100 cal per 12 oz can.',
    ),
    DrinkType(
      name: 'Cocktail',
      icon: Icons.local_bar_rounded,
      color: Color(0xFFE91E63),
      waterRatio: 0.40,
      category: DrinkCategory.alcohol,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Mixed drinks combine alcohol (diuretic) with sugar. Highly dehydrating — drink a glass of water per cocktail.',
    ),
    DrinkType(
      name: 'Spirits',
      icon: Icons.liquor_rounded,
      color: Color(0xFF424242),
      waterRatio: 0.30,
      category: DrinkCategory.alcohol,
      healthTier: HealthTier.limit,
      hasDisclaimer: true,
      disclaimerText:
          'Spirits (40% ABV) are strongly diuretic. A 1.5 oz shot can cause net fluid loss. Always hydrate alongside.',
    ),

    // ─── Other ───────────────────────────────────────────────
    DrinkType(
      name: 'Soup / Broth',
      icon: Icons.ramen_dining_rounded,
      color: Color(0xFFD50000),
      waterRatio: 0.92,
      category: DrinkCategory.other,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Broth-based soups hydrate well and provide electrolytes. Bone broth adds collagen and minerals. Watch sodium.',
    ),
    DrinkType(
      name: 'Bone Broth',
      icon: Icons.soup_kitchen_rounded,
      color: Color(0xFFBF360C),
      waterRatio: 0.92,
      category: DrinkCategory.other,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'Bone broth is rich in collagen, amino acids, and minerals. Great for gut health and joint support.',
    ),
    DrinkType(
      name: 'Apple Cider Vinegar',
      icon: Icons.science_outlined,
      color: Color(0xFF827717),
      waterRatio: 0.95,
      category: DrinkCategory.other,
      healthTier: HealthTier.good,
      hasDisclaimer: true,
      disclaimerText:
          'ACV drinks may aid digestion and blood sugar. Always dilute well — undiluted can damage tooth enamel.',
    ),
    DrinkType(
      name: 'Aloe Vera Drink',
      icon: Icons.spa_outlined,
      color: Color(0xFF66BB6A),
      waterRatio: 0.95,
      category: DrinkCategory.other,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Aloe vera drinks may support digestion. Watch for added sugar in commercial brands.',
    ),
    DrinkType(
      name: 'Horchata',
      icon: Icons.local_drink_rounded,
      color: Color(0xFFD7CCC8),
      waterRatio: 0.85,
      category: DrinkCategory.other,
      healthTier: HealthTier.fair,
      hasDisclaimer: true,
      disclaimerText:
          'Horchata (rice/almond-based) is refreshing but can have 25+ g sugar per serving.',
    ),
  ];

  /// Get drinks allowed for a specific challenge
  static List<DrinkType> forChallenge(int challengeIndex) {
    switch (challengeIndex) {
      case 0: // Nothing But Water
        return all.where((d) => d.category == DrinkCategory.water).toList();
      case 1: // Tea Time - all drinks allowed but must include tea
        return all.where((d) => d.category != DrinkCategory.alcohol).toList();
      case 2: // Caffeine Cut - exclude high caffeine
        return all
            .where((d) =>
                d.category != DrinkCategory.coffee &&
                d.category != DrinkCategory.alcohol &&
                d.name != 'Energy Drink' &&
                d.name != 'Black Tea' &&
                d.name != 'Matcha' &&
                d.name != 'Pre-Workout')
            .toList();
      case 3: // Sugar-Free Sips
        return all
            .where((d) =>
                d.category != DrinkCategory.alcohol &&
                d.name != 'Soda' &&
                d.name != 'Lemonade' &&
                d.name != 'Energy Drink' &&
                d.name != 'Hot Chocolate' &&
                d.name != 'Milkshake' &&
                d.name != 'Root Beer' &&
                d.name != 'Bubble Tea' &&
                d.name != 'Sweet Tea' &&
                d.name != 'Frappuccino' &&
                d.name != 'Ginger Ale' &&
                d.name != 'Eggnog')
            .toList();
      case 4: // Dairy-Free Refresh
        return all
            .where((d) =>
                d.category != DrinkCategory.dairy &&
                d.category != DrinkCategory.alcohol)
            .toList();
      case 5: // Vitamin Vitality - all drinks
        return all.where((d) => d.category != DrinkCategory.alcohol).toList();
      default:
        return all;
    }
  }

  /// Returns the list of drinks that are RESTRICTED (not allowed) for a given
  /// challenge. This is the complement of [forChallenge].
  static List<DrinkType> restrictedForChallenge(int challengeIndex) {
    final allowed = forChallenge(challengeIndex).map((d) => d.name).toSet();
    return all.where((d) => !allowed.contains(d.name)).toList();
  }

  static DrinkType? byName(String name) {
    try {
      return all.firstWhere((d) => d.name == name);
    } catch (_) {
      return null;
    }
  }
}
