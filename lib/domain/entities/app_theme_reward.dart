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
  raindrops,
  dust,
  sunbeams,
  blossoms,
}

// ── Unlock criteria ─────────────────────────────────────────────────

/// How a theme reward is unlocked.
enum ThemeUnlockType {
  /// Always available (default theme).
  free,

  /// Unlocked when the player reaches a certain level.
  level,

  /// Must be purchased with Drops in the market.
  purchase,
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
    required int level,
    required List<String> purchasedThemeIds,
    required String themeId,
  }) {
    switch (type) {
      case ThemeUnlockType.free:
        return true;
      case ThemeUnlockType.level:
        return level >= value;
      case ThemeUnlockType.purchase:
        return purchasedThemeIds.contains(themeId);
    }
  }

  @override
  List<Object?> get props => [type, value];
}

// ── Theme rarity tier (for UI grouping) ─────────────────────────────

enum ThemeTier {
  free,
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

// ── Theme reward entity ─────────────────────────────────────────────

/// An unlockable / purchasable background theme.
class ThemeReward extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<Color> gradientColors;
  final IconData icon;
  final ThemeUnlockCondition unlockCondition;
  final ThemeEffect effect;
  final Color primaryColor;
  final Color accentColor;

  /// Price in Drops (0 for level-unlocked / free themes).
  final int price;

  /// Rarity tier — drives sort order and visual flair in the market.
  final ThemeTier tier;

  const ThemeReward({
    required this.id,
    required this.name,
    required this.description,
    required this.gradientColors,
    required this.icon,
    required this.unlockCondition,
    this.effect = ThemeEffect.none,
    required this.primaryColor,
    required this.accentColor,
    this.price = 0,
    this.tier = ThemeTier.free,
  });

  bool get isPurchasable => unlockCondition.type == ThemeUnlockType.purchase;
  bool get isLevelUnlock => unlockCondition.type == ThemeUnlockType.level;

  @override
  List<Object?> get props => [id, name];
}

// ═══════════════════════════════════════════════════════════════════════
// ALL 48 THEMES
// ═══════════════════════════════════════════════════════════════════════

class ThemeRewards {
  ThemeRewards._();

  static const List<ThemeReward> all = [
    // ─────────────────────────────────────────────────────────────────
    // LEVEL-UNLOCKED THEMES (13)
    // ─────────────────────────────────────────────────────────────────

    // #1 — Default (free)
    ThemeReward(
      id: 'default',
      name: 'Default Pond',
      description: 'The classic Waddle look — cool and calming.',
      gradientColors: [Color(0xFFE8F4FC), Color(0xFFB8E4E8)],
      icon: Icons.water_drop_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.free,
        value: 0,
        displayText: 'Always available',
      ),
      primaryColor: Color(0xFF36708B),
      accentColor: Color(0xFF6CCCD1),
      tier: ThemeTier.free,
    ),

    // #2 — Level 5
    ThemeReward(
      id: 'morning_dew',
      name: 'Morning Dew',
      description: 'A fresh green start to every day.',
      gradientColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      icon: Icons.grass_rounded,
      effect: ThemeEffect.leaves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 5,
        displayText: 'Reach Level 5',
      ),
      primaryColor: Color(0xFF2E7D32),
      accentColor: Color(0xFF81C784),
      tier: ThemeTier.common,
    ),

    // #3 — Level 10
    ThemeReward(
      id: 'ocean_breeze',
      name: 'Ocean Breeze',
      description: 'Cool blue tones — like a walk along the coast.',
      gradientColors: [Color(0xFFE1F5FE), Color(0xFFB2EBF2)],
      icon: Icons.air_rounded,
      effect: ThemeEffect.waves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 10,
        displayText: 'Reach Level 10',
      ),
      primaryColor: Color(0xFF0277BD),
      accentColor: Color(0xFF4FC3F7),
      tier: ThemeTier.common,
    ),

    // #4 — Level 15
    ThemeReward(
      id: 'sunset_glow',
      name: 'Sunset Glow',
      description: 'Warm peach skies after a well-hydrated day.',
      gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFCCBC)],
      icon: Icons.wb_twilight_rounded,
      effect: ThemeEffect.fireflies,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 15,
        displayText: 'Reach Level 15',
      ),
      primaryColor: Color(0xFFE65100),
      accentColor: Color(0xFFFFAB91),
      tier: ThemeTier.common,
    ),

    // #5 — Level 20
    ThemeReward(
      id: 'lavender_fields',
      name: 'Lavender Fields',
      description: 'Soft purple tranquility as far as the eye can see.',
      gradientColors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
      icon: Icons.spa_rounded,
      effect: ThemeEffect.petals,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 20,
        displayText: 'Reach Level 20',
      ),
      primaryColor: Color(0xFF5E35B1),
      accentColor: Color(0xFFB39DDB),
      tier: ThemeTier.uncommon,
    ),

    // #6 — Level 30
    ThemeReward(
      id: 'golden_hour',
      name: 'Golden Hour',
      description: 'Warm amber glow for the truly dedicated.',
      gradientColors: [Color(0xFFFFFDE7), Color(0xFFFFE082)],
      icon: Icons.wb_sunny_rounded,
      effect: ThemeEffect.sunbeams,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 30,
        displayText: 'Reach Level 30',
      ),
      primaryColor: Color(0xFFF57F17),
      accentColor: Color(0xFFFFD54F),
      tier: ThemeTier.uncommon,
    ),

    // #7 — Level 40
    ThemeReward(
      id: 'forest_canopy',
      name: 'Forest Canopy',
      description: 'Exploring the full spectrum of green.',
      gradientColors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
      icon: Icons.forest_rounded,
      effect: ThemeEffect.leaves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 40,
        displayText: 'Reach Level 40',
      ),
      primaryColor: Color(0xFF33691E),
      accentColor: Color(0xFFAED581),
      tier: ThemeTier.rare,
    ),

    // #8 — Level 50
    ThemeReward(
      id: 'arctic_frost',
      name: 'Arctic Frost',
      description: 'Ice-cold blue for serious hydration volume.',
      gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      icon: Icons.ac_unit_rounded,
      effect: ThemeEffect.snowflakes,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 50,
        displayText: 'Reach Level 50',
      ),
      primaryColor: Color(0xFF1565C0),
      accentColor: Color(0xFF64B5F6),
      tier: ThemeTier.rare,
    ),

    // #9 — Level 60
    ThemeReward(
      id: 'midnight_lake',
      name: 'Midnight Lake',
      description: 'Cool indigo waters of consistent dedication.',
      gradientColors: [Color(0xFFE8EAF6), Color(0xFF9FA8DA)],
      icon: Icons.nightlight_round,
      effect: ThemeEffect.stars,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 60,
        displayText: 'Reach Level 60',
      ),
      primaryColor: Color(0xFF283593),
      accentColor: Color(0xFF7986CB),
      tier: ThemeTier.epic,
    ),

    // #10 — Level 70
    ThemeReward(
      id: 'northern_lights',
      name: 'Northern Lights',
      description: 'An aurora of green and purple — truly rare.',
      gradientColors: [Color(0xFFC8E6C9), Color(0xFFCE93D8)],
      icon: Icons.auto_awesome_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 70,
        displayText: 'Reach Level 70',
      ),
      primaryColor: Color(0xFF6A1B9A),
      accentColor: Color(0xFFAB47BC),
      tier: ThemeTier.epic,
    ),

    // #11 — Level 80
    ThemeReward(
      id: 'diamond_falls',
      name: 'Diamond Falls',
      description: 'Platinum shimmer reserved for the most dedicated.',
      gradientColors: [Color(0xFFECEFF1), Color(0xFFF5F5F5)],
      icon: Icons.diamond_rounded,
      effect: ThemeEffect.snowflakes,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 80,
        displayText: 'Reach Level 80',
      ),
      primaryColor: Color(0xFF546E7A),
      accentColor: Color(0xFF90A4AE),
      tier: ThemeTier.epic,
    ),

    // #12 — Level 90
    ThemeReward(
      id: 'cosmic_tide',
      name: 'Cosmic Tide',
      description: 'Deep space hues for a truly elite explorer.',
      gradientColors: [Color(0xFFD1C4E9), Color(0xFFBBDEFB)],
      icon: Icons.auto_awesome_rounded,
      effect: ThemeEffect.stars,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 90,
        displayText: 'Reach Level 90',
      ),
      primaryColor: Color(0xFF4527A0),
      accentColor: Color(0xFF9575CD),
      tier: ThemeTier.legendary,
    ),

    // #13 — Level 100
    ThemeReward(
      id: 'volcanic_spring',
      name: 'Volcanic Spring',
      description: 'Magma meets amber — forged at the summit.',
      gradientColors: [Color(0xFFFFCCBC), Color(0xFFFFECB3)],
      icon: Icons.local_fire_department_rounded,
      effect: ThemeEffect.fireflies,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.level,
        value: 100,
        displayText: 'Reach Level 100',
      ),
      primaryColor: Color(0xFFD84315),
      accentColor: Color(0xFFFF8A65),
      tier: ThemeTier.legendary,
    ),

    // ─────────────────────────────────────────────────────────────────
    // MARKET PURCHASES — TIER 1: COMMON (100-150 Drops)  (8 themes)
    // ─────────────────────────────────────────────────────────────────

    // #14
    ThemeReward(
      id: 'cloudy_day',
      name: 'Cloudy Day',
      description: 'Soft grey skies with gentle raindrops.',
      gradientColors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
      icon: Icons.cloud_rounded,
      effect: ThemeEffect.raindrops,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '100 Drops',
      ),
      primaryColor: Color(0xFF546E7A),
      accentColor: Color(0xFF90A4AE),
      price: 100,
      tier: ThemeTier.common,
    ),

    // #15
    ThemeReward(
      id: 'mint_fresh',
      name: 'Mint Fresh',
      description: 'Cool mint greens — clean and crisp.',
      gradientColors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      icon: Icons.eco_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '100 Drops',
      ),
      primaryColor: Color(0xFF00695C),
      accentColor: Color(0xFF80CBC4),
      price: 100,
      tier: ThemeTier.common,
    ),

    // #16
    ThemeReward(
      id: 'sandy_beach',
      name: 'Sandy Beach',
      description: 'Warm sand tones and gentle lapping waves.',
      gradientColors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
      icon: Icons.beach_access_rounded,
      effect: ThemeEffect.waves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '120 Drops',
      ),
      primaryColor: Color(0xFFFF8F00),
      accentColor: Color(0xFFFFCA28),
      price: 120,
      tier: ThemeTier.common,
    ),

    // #17
    ThemeReward(
      id: 'peach_sorbet',
      name: 'Peach Sorbet',
      description: 'Warm peach and cream vibes — sweet and smooth.',
      gradientColors: [Color(0xFFFBE9E7), Color(0xFFFFCCBC)],
      icon: Icons.icecream_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '120 Drops',
      ),
      primaryColor: Color(0xFFBF360C),
      accentColor: Color(0xFFFF8A65),
      price: 120,
      tier: ThemeTier.common,
    ),

    // #18
    ThemeReward(
      id: 'lemon_fizz',
      name: 'Lemon Fizz',
      description: 'Bright sunny yellow with tiny bubbles.',
      gradientColors: [Color(0xFFFFFDE7), Color(0xFFFFF9C4)],
      icon: Icons.local_bar_rounded,
      effect: ThemeEffect.bubbles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '130 Drops',
      ),
      primaryColor: Color(0xFFF9A825),
      accentColor: Color(0xFFFFEE58),
      price: 130,
      tier: ThemeTier.common,
    ),

    // #19
    ThemeReward(
      id: 'rainy_afternoon',
      name: 'Rainy Afternoon',
      description: 'Moody blue-grey — cozy and contemplative.',
      gradientColors: [Color(0xFFE8EAF6), Color(0xFFBBDEFB)],
      icon: Icons.umbrella_rounded,
      effect: ThemeEffect.raindrops,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '130 Drops',
      ),
      primaryColor: Color(0xFF37474F),
      accentColor: Color(0xFF78909C),
      price: 130,
      tier: ThemeTier.common,
    ),

    // #20
    ThemeReward(
      id: 'spring_meadow',
      name: 'Spring Meadow',
      description: 'Light green with scattered blossoms.',
      gradientColors: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
      icon: Icons.local_florist_rounded,
      effect: ThemeEffect.blossoms,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '150 Drops',
      ),
      primaryColor: Color(0xFF558B2F),
      accentColor: Color(0xFF9CCC65),
      price: 150,
      tier: ThemeTier.common,
    ),

    // #21
    ThemeReward(
      id: 'cotton_candy',
      name: 'Cotton Candy',
      description: 'Pink and baby blue sweetness — light and playful.',
      gradientColors: [Color(0xFFFCE4EC), Color(0xFFE1F5FE)],
      icon: Icons.cloud_queue_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '150 Drops',
      ),
      primaryColor: Color(0xFFAD1457),
      accentColor: Color(0xFFF48FB1),
      price: 150,
      tier: ThemeTier.common,
    ),

    // ─────────────────────────────────────────────────────────────────
    // MARKET PURCHASES — TIER 2: UNCOMMON (200-350 Drops)  (8 themes)
    // ─────────────────────────────────────────────────────────────────

    // #22
    ThemeReward(
      id: 'cherry_blossom',
      name: 'Cherry Blossom',
      description: 'Delicate pink petals drifting on a gentle breeze.',
      gradientColors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
      icon: Icons.filter_vintage_rounded,
      effect: ThemeEffect.petals,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '200 Drops',
      ),
      primaryColor: Color(0xFFC2185B),
      accentColor: Color(0xFFF48FB1),
      price: 200,
      tier: ThemeTier.uncommon,
    ),

    // #23
    ThemeReward(
      id: 'berry_patch',
      name: 'Berry Patch',
      description: 'Deep berry purples and magentas — rich and lush.',
      gradientColors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
      icon: Icons.local_florist_rounded,
      effect: ThemeEffect.blossoms,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '225 Drops',
      ),
      primaryColor: Color(0xFF7B1FA2),
      accentColor: Color(0xFFCE93D8),
      price: 225,
      tier: ThemeTier.uncommon,
    ),

    // #24
    ThemeReward(
      id: 'coral_reef',
      name: 'Coral Reef',
      description: 'A vibrant underwater palette of warm corals.',
      gradientColors: [Color(0xFFFBE9E7), Color(0xFFFFAB91)],
      icon: Icons.scuba_diving_rounded,
      effect: ThemeEffect.bubbles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '250 Drops',
      ),
      primaryColor: Color(0xFFBF360C),
      accentColor: Color(0xFFFF8A65),
      price: 250,
      tier: ThemeTier.uncommon,
    ),

    // #25
    ThemeReward(
      id: 'desert_oasis',
      name: 'Desert Oasis',
      description: 'Sand meeting aqua — a true hydration journey.',
      gradientColors: [Color(0xFFFFF8E1), Color(0xFFB2EBF2)],
      icon: Icons.terrain_rounded,
      effect: ThemeEffect.dust,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '250 Drops',
      ),
      primaryColor: Color(0xFF00838F),
      accentColor: Color(0xFF4DD0E1),
      price: 250,
      tier: ThemeTier.uncommon,
    ),

    // #26
    ThemeReward(
      id: 'tropical_splash',
      name: 'Tropical Splash',
      description: 'Breezy teal and emerald green paradise.',
      gradientColors: [Color(0xFFE0F2F1), Color(0xFFB2DFDB)],
      icon: Icons.emoji_nature_rounded,
      effect: ThemeEffect.raindrops,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '275 Drops',
      ),
      primaryColor: Color(0xFF00796B),
      accentColor: Color(0xFF80CBC4),
      price: 275,
      tier: ThemeTier.uncommon,
    ),

    // #27
    ThemeReward(
      id: 'autumn_harvest',
      name: 'Autumn Harvest',
      description: 'Rich amber, burnt orange, and crimson leaves.',
      gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
      icon: Icons.park_rounded,
      effect: ThemeEffect.leaves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '300 Drops',
      ),
      primaryColor: Color(0xFFE65100),
      accentColor: Color(0xFFFFB74D),
      price: 300,
      tier: ThemeTier.uncommon,
    ),

    // #28
    ThemeReward(
      id: 'moonlit_garden',
      name: 'Moonlit Garden',
      description: 'Silver moonlight on deep indigo — peaceful and mysterious.',
      gradientColors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
      icon: Icons.nightlight_round,
      effect: ThemeEffect.fireflies,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '325 Drops',
      ),
      primaryColor: Color(0xFF1A237E),
      accentColor: Color(0xFF7986CB),
      price: 325,
      tier: ThemeTier.uncommon,
    ),

    // #29
    ThemeReward(
      id: 'rose_gold',
      name: 'Rose Gold',
      description: 'Luxurious rose gold and blush tones — elegant and warm.',
      gradientColors: [Color(0xFFFCE4EC), Color(0xFFFFECB3)],
      icon: Icons.favorite_rounded,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '350 Drops',
      ),
      primaryColor: Color(0xFFBF360C),
      accentColor: Color(0xFFFFAB91),
      price: 350,
      tier: ThemeTier.uncommon,
    ),

    // ─────────────────────────────────────────────────────────────────
    // MARKET PURCHASES — TIER 3: RARE (400-600 Drops)  (7 themes)
    // ─────────────────────────────────────────────────────────────────

    // #30
    ThemeReward(
      id: 'emerald_spring',
      name: 'Emerald Spring',
      description: 'Lush deep greens and teal — nature in full bloom.',
      gradientColors: [Color(0xFFC8E6C9), Color(0xFF80CBC4)],
      icon: Icons.eco_rounded,
      effect: ThemeEffect.leaves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '400 Drops',
      ),
      primaryColor: Color(0xFF00695C),
      accentColor: Color(0xFF80CBC4),
      price: 400,
      tier: ThemeTier.rare,
    ),

    // #31
    ThemeReward(
      id: 'neon_depths',
      name: 'Neon Depths',
      description:
          'Electric cyan and hot pink from the deepest ocean trenches.',
      gradientColors: [Color(0xFF1A237E), Color(0xFF00BCD4)],
      icon: Icons.flash_on_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '450 Drops',
      ),
      primaryColor: Color(0xFF00BCD4),
      accentColor: Color(0xFFFF4081),
      price: 450,
      tier: ThemeTier.rare,
    ),

    // #32
    ThemeReward(
      id: 'stormy_seas',
      name: 'Stormy Seas',
      description: 'Dark grey-blue with lightning flashes on the horizon.',
      gradientColors: [Color(0xFF37474F), Color(0xFF546E7A)],
      icon: Icons.thunderstorm_rounded,
      effect: ThemeEffect.raindrops,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '450 Drops',
      ),
      primaryColor: Color(0xFF90A4AE),
      accentColor: Color(0xFFE0E0E0),
      price: 450,
      tier: ThemeTier.rare,
    ),

    // #33
    ThemeReward(
      id: 'crimson_dusk',
      name: 'Crimson Dusk',
      description: 'Deep red meeting dark purple on the horizon.',
      gradientColors: [Color(0xFF880E4F), Color(0xFF4A148C)],
      icon: Icons.wb_twilight_rounded,
      effect: ThemeEffect.dust,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '500 Drops',
      ),
      primaryColor: Color(0xFFF8BBD0),
      accentColor: Color(0xFFCE93D8),
      price: 500,
      tier: ThemeTier.rare,
    ),

    // #34
    ThemeReward(
      id: 'frozen_tundra',
      name: 'Frozen Tundra',
      description: 'Icy white and pale blue — the silence of deep winter.',
      gradientColors: [Color(0xFFE3F2FD), Color(0xFFE1F5FE)],
      icon: Icons.ac_unit_rounded,
      effect: ThemeEffect.snowflakes,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '500 Drops',
      ),
      primaryColor: Color(0xFF0288D1),
      accentColor: Color(0xFF81D4FA),
      price: 500,
      tier: ThemeTier.rare,
    ),

    // #35
    ThemeReward(
      id: 'bamboo_forest',
      name: 'Bamboo Forest',
      description: 'Deep jade greens with golden accents — serene and ancient.',
      gradientColors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
      icon: Icons.park_rounded,
      effect: ThemeEffect.leaves,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '550 Drops',
      ),
      primaryColor: Color(0xFFC8E6C9),
      accentColor: Color(0xFFFFD54F),
      price: 550,
      tier: ThemeTier.rare,
    ),

    // #36
    ThemeReward(
      id: 'amethyst_cave',
      name: 'Amethyst Cave',
      description: 'Rich purple crystals and deep violet shadows.',
      gradientColors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
      icon: Icons.diamond_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '600 Drops',
      ),
      primaryColor: Color(0xFFE1BEE7),
      accentColor: Color(0xFFCE93D8),
      price: 600,
      tier: ThemeTier.rare,
    ),

    // ─────────────────────────────────────────────────────────────────
    // MARKET PURCHASES — TIER 4: EPIC (800-1200 Drops)  (6 themes)
    // ─────────────────────────────────────────────────────────────────

    // #37
    ThemeReward(
      id: 'dragons_breath',
      name: 'Dragon\'s Breath',
      description: 'Fiery orange, red, and black — feel the heat.',
      gradientColors: [Color(0xFFB71C1C), Color(0xFFFF6F00)],
      icon: Icons.local_fire_department_rounded,
      effect: ThemeEffect.fireflies,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '800 Drops',
      ),
      primaryColor: Color(0xFFFFCDD2),
      accentColor: Color(0xFFFFAB91),
      price: 800,
      tier: ThemeTier.epic,
    ),

    // #38
    ThemeReward(
      id: 'bioluminescence',
      name: 'Bioluminescence',
      description: 'Glowing cyan organisms in the deep ocean darkness.',
      gradientColors: [Color(0xFF0D1B2A), Color(0xFF006064)],
      icon: Icons.blur_on_rounded,
      effect: ThemeEffect.bubbles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '900 Drops',
      ),
      primaryColor: Color(0xFF00E5FF),
      accentColor: Color(0xFF18FFFF),
      price: 900,
      tier: ThemeTier.epic,
    ),

    // #39
    ThemeReward(
      id: 'solar_eclipse',
      name: 'Solar Eclipse',
      description: 'Dark corona with a brilliant golden rim — awe-inspiring.',
      gradientColors: [Color(0xFF212121), Color(0xFF424242)],
      icon: Icons.brightness_3_rounded,
      effect: ThemeEffect.sunbeams,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '1,000 Drops',
      ),
      primaryColor: Color(0xFFFFD54F),
      accentColor: Color(0xFFFFC107),
      price: 1000,
      tier: ThemeTier.epic,
    ),

    // #40
    ThemeReward(
      id: 'nebula_drift',
      name: 'Nebula Drift',
      description: 'Swirling purple and blue space dust among the stars.',
      gradientColors: [Color(0xFF1A237E), Color(0xFF6A1B9A)],
      icon: Icons.auto_awesome_rounded,
      effect: ThemeEffect.stars,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '1,000 Drops',
      ),
      primaryColor: Color(0xFFB39DDB),
      accentColor: Color(0xFF82B1FF),
      price: 1000,
      tier: ThemeTier.epic,
    ),

    // #41
    ThemeReward(
      id: 'crystal_cavern',
      name: 'Crystal Cavern',
      description: 'Shimmering diamond formations in an icy underground lake.',
      gradientColors: [Color(0xFF263238), Color(0xFF4FC3F7)],
      icon: Icons.diamond_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '1,100 Drops',
      ),
      primaryColor: Color(0xFFB2EBF2),
      accentColor: Color(0xFFE0F7FA),
      price: 1100,
      tier: ThemeTier.epic,
    ),

    // #42
    ThemeReward(
      id: 'aurora_borealis',
      name: 'Aurora Borealis',
      description: 'Dancing curtains of green and purple light.',
      gradientColors: [Color(0xFF1B5E20), Color(0xFF6A1B9A)],
      icon: Icons.auto_awesome_mosaic_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '1,200 Drops',
      ),
      primaryColor: Color(0xFFA5D6A7),
      accentColor: Color(0xFFCE93D8),
      price: 1200,
      tier: ThemeTier.epic,
    ),

    // ─────────────────────────────────────────────────────────────────
    // MARKET PURCHASES — TIER 5: LEGENDARY (1500-3000 Drops) (6 themes)
    // ─────────────────────────────────────────────────────────────────

    // #43
    ThemeReward(
      id: 'void_walker',
      name: 'Void Walker',
      description: 'Near-black with faint purple stars — the edge of nothing.',
      gradientColors: [Color(0xFF0D0D0D), Color(0xFF1A0033)],
      icon: Icons.blur_circular_rounded,
      effect: ThemeEffect.stars,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '1,500 Drops',
      ),
      primaryColor: Color(0xFFE0E0E0),
      accentColor: Color(0xFFB388FF),
      price: 1500,
      tier: ThemeTier.legendary,
    ),

    // #44
    ThemeReward(
      id: 'supernova',
      name: 'Supernova',
      description: 'An explosive burst of gold, orange, and white-hot light.',
      gradientColors: [Color(0xFFFF6F00), Color(0xFFFFD54F)],
      icon: Icons.flare_rounded,
      effect: ThemeEffect.sunbeams,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '1,800 Drops',
      ),
      primaryColor: Color(0xFFFF6F00),
      accentColor: Color(0xFFFFECB3),
      price: 1800,
      tier: ThemeTier.legendary,
    ),

    // #45
    ThemeReward(
      id: 'abyssal_depths',
      name: 'Abyssal Depths',
      description: 'Pitch black ocean floor with bioluminescent specks.',
      gradientColors: [Color(0xFF000000), Color(0xFF0D1B2A)],
      icon: Icons.water_rounded,
      effect: ThemeEffect.bubbles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '2,000 Drops',
      ),
      primaryColor: Color(0xFF0097A7),
      accentColor: Color(0xFF26C6DA),
      price: 2000,
      tier: ThemeTier.legendary,
    ),

    // #46
    ThemeReward(
      id: 'paradise_lost',
      name: 'Paradise Lost',
      description: 'Lush emerald jungle with exotic pink flowers — untouched.',
      gradientColors: [Color(0xFF1B5E20), Color(0xFFF06292)],
      icon: Icons.spa_rounded,
      effect: ThemeEffect.petals,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '2,200 Drops',
      ),
      primaryColor: Color(0xFFA5D6A7),
      accentColor: Color(0xFFF48FB1),
      price: 2200,
      tier: ThemeTier.legendary,
    ),

    // #47
    ThemeReward(
      id: 'chromatic_dream',
      name: 'Chromatic Dream',
      description: 'Iridescent rainbow shimmer — every color at once.',
      gradientColors: [Color(0xFFF48FB1), Color(0xFF82B1FF)],
      icon: Icons.palette_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '2,500 Drops',
      ),
      primaryColor: Color(0xFFAB47BC),
      accentColor: Color(0xFF64B5F6),
      price: 2500,
      tier: ThemeTier.legendary,
    ),

    // #48
    ThemeReward(
      id: 'the_final_splash',
      name: 'The Final Splash',
      description: 'Legendary golden water with sparkles — '
          'the crown jewel of Waddle\'s collection.',
      gradientColors: [Color(0xFFFFD700), Color(0xFFFFF8E1)],
      icon: Icons.emoji_events_rounded,
      effect: ThemeEffect.sparkles,
      unlockCondition: ThemeUnlockCondition(
        type: ThemeUnlockType.purchase,
        value: 0,
        displayText: '3,000 Drops',
      ),
      primaryColor: Color(0xFFFF8F00),
      accentColor: Color(0xFFFFD54F),
      price: 3000,
      tier: ThemeTier.legendary,
    ),
  ];

  /// Look up a theme by its ID.
  static ThemeReward? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// All purchasable themes (sorted cheapest-first by default).
  static List<ThemeReward> get purchasable =>
      all.where((t) => t.isPurchasable).toList();

  /// How many themes the player has unlocked.
  static int countUnlocked({
    required int level,
    required List<String> purchasedThemeIds,
  }) {
    return all
        .where((t) => t.unlockCondition.isUnlocked(
              level: level,
              purchasedThemeIds: purchasedThemeIds,
              themeId: t.id,
            ))
        .length;
  }
}
