import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// A hydration challenge definition
class Challenge extends Equatable {
  final int index;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String details;
  final List<String> healthFactoids;
  final String imagePath;
  final Color color;
  final int durationDays;

  const Challenge({
    required this.index,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.details,
    required this.healthFactoids,
    required this.imagePath,
    required this.color,
    this.durationDays = 14,
  });

  @override
  List<Object?> get props => [index, title];
}

/// All available challenges
class Challenges {
  Challenges._();

  static const List<Challenge> all = [
    Challenge(
      index: 0,
      title: 'Nothing But Water',
      shortDescription: 'Only water for 14 days',
      fullDescription:
          'Challenge yourself to drink only water, sparkling water, or coconut water for 14 consecutive days. No other beverages allowed!',
      details:
          'This challenge filters your drink options to water-based beverages only. '
          'You must meet your daily water goal each day to keep the challenge active. '
          'Missing a day will end the challenge.',
      healthFactoids: [
        'Drinking only water can help reduce sugar cravings within just a few days.',
        'Pure water is absorbed faster by the body than any other beverage.',
        'Eliminating sugary drinks for 2 weeks can reduce daily calorie intake by 200-400 calories.',
      ],
      imagePath: 'lib/assets/images/wade_nothing_but_water.png',
      color: Color(0xFF42A5F5),
    ),
    Challenge(
      index: 1,
      title: 'Tea Time',
      shortDescription: 'Drink 12+ oz tea daily',
      fullDescription:
          'Incorporate at least 12 oz of tea into your daily hydration for 14 days. Any type of tea counts!',
      details:
          'Track your tea consumption alongside your regular water intake. '
          'You must log at least 12 oz of tea each day AND meet your overall water goal.',
      healthFactoids: [
        'Green tea contains catechins, powerful antioxidants that may reduce the risk of heart disease.',
        'Herbal teas like chamomile can promote better sleep and reduce anxiety.',
        'Regular tea consumption is associated with improved gut health and metabolism.',
      ],
      imagePath: 'lib/assets/images/wade_tea_time.png',
      color: Color(0xFF66BB6A),
    ),
    Challenge(
      index: 2,
      title: 'Caffeine Cut',
      shortDescription: 'Minimize caffeine for 14 days',
      fullDescription:
          'Reduce your caffeine intake by avoiding coffee, energy drinks, black tea, and matcha for 14 days.',
      details: 'High-caffeine beverages are removed from your drink options. '
          'You can still enjoy herbal tea, green tea (in moderation), and all other non-caffeinated drinks.',
      healthFactoids: [
        'Reducing caffeine can lead to better sleep quality within 3-5 days.',
        'Caffeine withdrawal symptoms typically peak at 1-2 days and subside within a week.',
        'Lower caffeine intake can reduce anxiety and improve hydration status.',
      ],
      imagePath: 'lib/assets/images/wade_caffeine_cut.png',
      color: Color(0xFF8D6E63),
    ),
    Challenge(
      index: 3,
      title: 'Sugar-Free Sips',
      shortDescription: 'No sugary drinks for 14 days',
      fullDescription:
          'Eliminate all sugary beverages from your diet for 14 consecutive days.',
      details:
          'Sugary drinks like soda, juice, lemonade, energy drinks, hot chocolate, and milkshakes are excluded. '
          'Focus on water, tea, coffee (unsweetened), and other low-sugar options.',
      healthFactoids: [
        'Cutting sugary drinks can reduce inflammation markers in just 2 weeks.',
        'Sugar-sweetened beverages are the single largest source of added sugar in most diets.',
        'Replacing one sugary drink per day with water can reduce yearly calorie intake by 50,000+ calories.',
      ],
      imagePath: 'lib/assets/images/wade_sugar_free_sips.png',
      color: Color(0xFFEF5350),
    ),
    Challenge(
      index: 4,
      title: 'Dairy-Free Refresh',
      shortDescription: 'Replace dairy for 14 days',
      fullDescription:
          'Swap all dairy-based beverages with dairy-free alternatives for 14 days.',
      details:
          'Dairy drinks (milk, skim milk, yogurt drinks, milkshakes) are replaced with plant-based alternatives. '
          'Try almond milk, oat milk, or soy milk instead.',
      healthFactoids: [
        'Plant-based milks often contain fewer calories than whole dairy milk.',
        'Many people discover improved digestion after reducing dairy intake.',
        'Oat milk provides beta-glucan fiber that supports heart health.',
      ],
      imagePath: 'lib/assets/images/wade_dairy_free_refresh.png',
      color: Color(0xFFFFA726),
    ),
    Challenge(
      index: 5,
      title: 'Vitamin Vitality',
      shortDescription: 'Drink 12+ oz vitamin-rich drinks daily',
      fullDescription:
          'Boost your nutrition by drinking at least 12 oz of vitamin-rich beverages daily for 14 days.',
      details:
          'Vitamin-rich beverages include smoothies, juices, coconut water, and fortified plant milks. '
          'Track these alongside your regular water intake.',
      healthFactoids: [
        'Smoothies with leafy greens can provide up to 50% of your daily vitamin K needs.',
        'Coconut water is naturally rich in potassium and electrolytes.',
        'Fortified plant milks can be excellent sources of vitamin D and calcium.',
      ],
      imagePath: 'lib/assets/images/wade_vitamin_vitality.png',
      color: Color(0xFFAB47BC),
    ),
  ];

  static Challenge getByIndex(int index) => all[index.clamp(0, all.length - 1)];
}
