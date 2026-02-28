import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// ACCESSORY SLOTS
// ═══════════════════════════════════════════════════════════════════════

/// Equipment slots on a duck.
enum AccessorySlot {
  hat,
  eyewear,
  neckwear,
  held,
}

extension AccessorySlotExtension on AccessorySlot {
  String get label {
    switch (this) {
      case AccessorySlot.hat:
        return 'Hat';
      case AccessorySlot.eyewear:
        return 'Eyewear';
      case AccessorySlot.neckwear:
        return 'Neckwear';
      case AccessorySlot.held:
        return 'Held Item';
    }
  }

  IconData get icon {
    switch (this) {
      case AccessorySlot.hat:
        return Icons.checkroom_rounded;
      case AccessorySlot.eyewear:
        return Icons.visibility_rounded;
      case AccessorySlot.neckwear:
        return Icons.dry_cleaning_rounded;
      case AccessorySlot.held:
        return Icons.back_hand_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSORY MODEL
// ═══════════════════════════════════════════════════════════════════════

/// Rarity tiers for accessories (affects visual flair in the shop).
enum AccessoryRarity { common, uncommon, rare, epic }

extension AccessoryRarityExtension on AccessoryRarity {
  Color get color {
    switch (this) {
      case AccessoryRarity.common:
        return const Color(0xFF90CAF9);
      case AccessoryRarity.uncommon:
        return const Color(0xFF66BB6A);
      case AccessoryRarity.rare:
        return const Color(0xFF42A5F5);
      case AccessoryRarity.epic:
        return const Color(0xFFAB47BC);
    }
  }

  String get label {
    switch (this) {
      case AccessoryRarity.common:
        return 'Common';
      case AccessoryRarity.uncommon:
        return 'Uncommon';
      case AccessoryRarity.rare:
        return 'Rare';
      case AccessoryRarity.epic:
        return 'Epic';
    }
  }
}

/// A cosmetic accessory that can be equipped on a duck.
class DuckAccessory extends Equatable {
  final String id;
  final String name;
  final String description;
  final AccessorySlot slot;
  final AccessoryRarity rarity;

  /// Price in Drops. 0 = subscriber-exclusive (free with Waddle+).
  final int price;

  /// If true, requires an active Waddle+ subscription to purchase.
  final bool subscriberOnly;

  /// The icon displayed as the visual representation of this accessory.
  final IconData icon;

  /// Tint color used when rendering the accessory overlay.
  final Color color;

  const DuckAccessory({
    required this.id,
    required this.name,
    required this.description,
    required this.slot,
    required this.rarity,
    required this.price,
    this.subscriberOnly = false,
    required this.icon,
    required this.color,
  });

  @override
  List<Object?> get props => [id];
}

// ═══════════════════════════════════════════════════════════════════════
// FULL ACCESSORY CATALOG — 24 accessories (6 per slot)
// ═══════════════════════════════════════════════════════════════════════

class DuckAccessories {
  DuckAccessories._();

  // ── HATS ───────────────────────────────────────────────────────────
  static const beanie = DuckAccessory(
    id: 'hat_beanie',
    name: 'Beanie',
    description: 'A cozy knit beanie for chilly pond mornings.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.common,
    price: 50,
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF90CAF9),
  );

  static const topHat = DuckAccessory(
    id: 'hat_top_hat',
    name: 'Top Hat',
    description: 'A distinguished topper for the most refined ducks.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.uncommon,
    price: 100,
    icon: Icons.straighten_rounded,
    color: Color(0xFF263238),
  );

  static const crown = DuckAccessory(
    id: 'hat_crown',
    name: 'Crown',
    description: 'A golden crown befitting pond royalty.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 200,
    icon: Icons.diamond_rounded,
    color: Color(0xFFFFD54F),
  );

  static const flowerCrown = DuckAccessory(
    id: 'hat_flower_crown',
    name: 'Flower Crown',
    description: 'Woven from the finest water lilies.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.uncommon,
    price: 100,
    icon: Icons.local_florist_rounded,
    color: Color(0xFFF48FB1),
  );

  static const wizardHat = DuckAccessory(
    id: 'hat_wizard',
    name: 'Wizard Hat',
    description: 'Channel ancient hydration magic.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 200,
    icon: Icons.auto_fix_high_rounded,
    color: Color(0xFF7E57C2),
  );

  static const halo = DuckAccessory(
    id: 'hat_halo',
    name: 'Halo',
    description: 'An angelic glow for a truly devoted duck.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.epic,
    price: 350,
    subscriberOnly: true,
    icon: Icons.brightness_7_rounded,
    color: Color(0xFFFFE082),
  );

  // ── EYEWEAR ────────────────────────────────────────────────────────
  static const sunglasses = DuckAccessory(
    id: 'eye_sunglasses',
    name: 'Sunglasses',
    description: 'Cool shades for a cool duck.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.common,
    price: 50,
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFF263238),
  );

  static const roundGlasses = DuckAccessory(
    id: 'eye_round_glasses',
    name: 'Round Glasses',
    description: 'Scholarly frames for a studious quacker.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.common,
    price: 50,
    icon: Icons.circle_outlined,
    color: Color(0xFF8D6E63),
  );

  static const aviators = DuckAccessory(
    id: 'eye_aviators',
    name: 'Aviators',
    description: 'Top-gun style for high-flying ducks.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.uncommon,
    price: 100,
    icon: Icons.flight_rounded,
    color: Color(0xFFBDBDBD),
  );

  static const monocle = DuckAccessory(
    id: 'eye_monocle',
    name: 'Monocle',
    description: 'For ducks of distinguished taste.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.rare,
    price: 150,
    icon: Icons.search_rounded,
    color: Color(0xFFFFD54F),
  );

  static const swimGoggles = DuckAccessory(
    id: 'eye_swim_goggles',
    name: 'Swim Goggles',
    description: 'Ready for a deep dive into hydration.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.common,
    price: 75,
    icon: Icons.pool_rounded,
    color: Color(0xFF29B6F6),
  );

  static const starShades = DuckAccessory(
    id: 'eye_star_shades',
    name: 'Star Shades',
    description: 'Superstar frames that shimmer and shine.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.epic,
    price: 300,
    subscriberOnly: true,
    icon: Icons.star_rounded,
    color: Color(0xFFFFD54F),
  );

  // ── NECKWEAR ───────────────────────────────────────────────────────
  static const bowTie = DuckAccessory(
    id: 'neck_bow_tie',
    name: 'Bow Tie',
    description: 'Dapper and delightful.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.common,
    price: 50,
    icon: Icons.style_rounded,
    color: Color(0xFFE53935),
  );

  static const scarf = DuckAccessory(
    id: 'neck_scarf',
    name: 'Scarf',
    description: 'A warm wrap for cold-weather waddling.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.common,
    price: 50,
    icon: Icons.waves_rounded,
    color: Color(0xFF42A5F5),
  );

  static const bandana = DuckAccessory(
    id: 'neck_bandana',
    name: 'Bandana',
    description: 'A rugged bandana for adventurous ducks.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.common,
    price: 75,
    icon: Icons.flag_rounded,
    color: Color(0xFFFF7043),
  );

  static const pearlNecklace = DuckAccessory(
    id: 'neck_pearl',
    name: 'Pearl Necklace',
    description: 'Elegant pearls from the deepest pond.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 100,
    icon: Icons.lens_rounded,
    color: Color(0xFFF5F5F5),
  );

  static const medal = DuckAccessory(
    id: 'neck_medal',
    name: 'Medal',
    description: 'A shining medal for hydration excellence.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.rare,
    price: 150,
    icon: Icons.military_tech_rounded,
    color: Color(0xFFFFD54F),
  );

  static const cape = DuckAccessory(
    id: 'neck_cape',
    name: 'Cape',
    description: 'Every duck deserves a hero moment.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.epic,
    price: 300,
    subscriberOnly: true,
    icon: Icons.shield_rounded,
    color: Color(0xFF7E57C2),
  );

  // ── HELD ITEMS ─────────────────────────────────────────────────────
  static const umbrella = DuckAccessory(
    id: 'held_umbrella',
    name: 'Umbrella',
    description: 'Stay dry — or don\'t! Either way it looks great.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.common,
    price: 75,
    icon: Icons.umbrella_rounded,
    color: Color(0xFF42A5F5),
  );

  static const waterBottle = DuckAccessory(
    id: 'held_water_bottle',
    name: 'Water Bottle',
    description: 'A duck that practices what it preaches.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.common,
    price: 50,
    icon: Icons.water_drop_rounded,
    color: Color(0xFF29B6F6),
  );

  static const magicWand = DuckAccessory(
    id: 'held_magic_wand',
    name: 'Magic Wand',
    description: 'One flick and hydration goals are met!',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.rare,
    price: 200,
    icon: Icons.auto_fix_high_rounded,
    color: Color(0xFFCE93D8),
  );

  static const fishingRod = DuckAccessory(
    id: 'held_fishing_rod',
    name: 'Fishing Rod',
    description: 'Catching compliments left and right.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 100,
    icon: Icons.phishing_rounded,
    color: Color(0xFF8D6E63),
  );

  static const surfboard = DuckAccessory(
    id: 'held_surfboard',
    name: 'Surfboard',
    description: 'Ride the hydration wave!',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.rare,
    price: 150,
    icon: Icons.surfing_rounded,
    color: Color(0xFF26C6DA),
  );

  static const trophy = DuckAccessory(
    id: 'held_trophy',
    name: 'Trophy',
    description: 'A gleaming trophy for the ultimate champion.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.epic,
    price: 350,
    subscriberOnly: true,
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFFFD54F),
  );

  // ── ALL ────────────────────────────────────────────────────────────
  static const List<DuckAccessory> all = [
    // Hats
    beanie, topHat, crown, flowerCrown, wizardHat, halo,
    // Eyewear
    sunglasses, roundGlasses, aviators, monocle, swimGoggles, starShades,
    // Neckwear
    bowTie, scarf, bandana, pearlNecklace, medal, cape,
    // Held
    umbrella, waterBottle, magicWand, fishingRod, surfboard, trophy,
  ];

  /// Look up an accessory by its ID.
  static DuckAccessory? byId(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all accessories for a given slot.
  static List<DuckAccessory> forSlot(AccessorySlot slot) =>
      all.where((a) => a.slot == slot).toList();
}
