import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'app_theme_reward.dart';
import 'duck_accessory.dart';

// ═══════════════════════════════════════════════════════════════════════
// SEASONAL / HOLIDAY COSMETIC PACKS
// ═══════════════════════════════════════════════════════════════════════
//
// Each pack contains themed accessories that become available in the
// Market during a specific date window. Subscribers (Waddle+) get
// every pack for free; non-subscribers can buy them with Drops.
//
// Packs repeat **every year** — the year in [availableFrom] / [availableUntil]
// is ignored at runtime; only month + day are compared.
// ═══════════════════════════════════════════════════════════════════════

/// A limited-time cosmetic pack tied to a holiday or season.
class SeasonalPack extends Equatable {
  /// Unique identifier, e.g. 'winter_wonderland'.
  final String id;

  /// Display name shown in the Market.
  final String name;

  /// Short tagline displayed below the title.
  final String description;

  /// Icon used in the Market card.
  final IconData icon;

  /// Accent colour for the pack card.
  final Color color;

  /// The accessories included in this pack.
  final List<DuckAccessory> accessories;

  /// First day the pack appears in the Market (month/day only — repeats yearly).
  final DateTime availableFrom;

  /// Last day the pack is available (month/day only — repeats yearly).
  final DateTime availableUntil;

  /// Price in Drops for non-subscribers. Waddle+ subscribers get it free.
  final int price;

  /// An exclusive theme included with this pack.
  final ThemeReward theme;

  const SeasonalPack({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.accessories,
    required this.availableFrom,
    required this.availableUntil,
    required this.price,
    required this.theme,
  });

  /// Whether the pack is currently available based on today's date.
  bool isAvailableOn(DateTime date) {
    final m = date.month;
    final d = date.day;
    final fromM = availableFrom.month;
    final fromD = availableFrom.day;
    final untilM = availableUntil.month;
    final untilD = availableUntil.day;

    final current = m * 100 + d;
    final start = fromM * 100 + fromD;
    final end = untilM * 100 + untilD;

    // Handle wrapping (e.g. Dec 15 → Jan 5)
    if (start <= end) {
      return current >= start && current <= end;
    } else {
      return current >= start || current <= end;
    }
  }

  /// Convenience — checks against [DateTime.now].
  bool get isCurrentlyAvailable => isAvailableOn(DateTime.now());

  @override
  List<Object?> get props => [id];
}

// ═══════════════════════════════════════════════════════════════════════
// SEASONAL ACCESSORY DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════
// These accessories are ONLY obtainable through their seasonal pack.
// They are NOT included in DuckAccessories.all.

class _S {
  _S._();

  // ── New Year's Bash (Dec 28 – Jan 7) ─────────────────────────────
  static const nyPartyHat = DuckAccessory(
    id: 'seasonal_ny_party_hat',
    name: 'Party Hat',
    description: 'Ring in the new year in style.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.celebration_rounded,
    color: Color(0xFFFFD54F),
  );
  static const nyNoisemaker = DuckAccessory(
    id: 'seasonal_ny_noisemaker',
    name: 'Noisemaker',
    description: 'A festive horn to welcome the new year.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.music_note_rounded,
    color: Color(0xFFFF8A65),
  );
  static const nyConfettiGlasses = DuckAccessory(
    id: 'seasonal_ny_confetti_glasses',
    name: 'Confetti Glasses',
    description: 'See the world through celebration.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFE040FB),
  );

  // ── Valentine's Day (Feb 7 – Feb 21) ─────────────────────────────
  static const valHeartCrown = DuckAccessory(
    id: 'seasonal_val_heart_crown',
    name: 'Heart Crown',
    description: 'A crown made of tiny hearts.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.favorite_rounded,
    color: Color(0xFFE91E63),
  );
  static const valRoseGlasses = DuckAccessory(
    id: 'seasonal_val_rose_glasses',
    name: 'Rose-Tinted Glasses',
    description: 'Everything looks lovelier in pink.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.visibility_rounded,
    color: Color(0xFFF48FB1),
  );
  static const valLoveLetter = DuckAccessory(
    id: 'seasonal_val_love_letter',
    name: 'Love Letter',
    description: 'A sealed letter tied with a ribbon.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.mail_rounded,
    color: Color(0xFFEF5350),
  );

  // ── St. Patrick's Day (Mar 10 – Mar 24) ──────────────────────────
  static const stpTopHat = DuckAccessory(
    id: 'seasonal_stp_top_hat',
    name: 'Leprechaun Hat',
    description: 'A lucky green top hat with a golden buckle.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.eco_rounded,
    color: Color(0xFF4CAF50),
  );
  static const stpClover = DuckAccessory(
    id: 'seasonal_stp_clover',
    name: 'Four-Leaf Clover',
    description: 'Hold it tight — luck is on your side.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.local_florist_rounded,
    color: Color(0xFF66BB6A),
  );
  static const stpGoldChain = DuckAccessory(
    id: 'seasonal_stp_gold_chain',
    name: 'Gold Chain',
    description: 'A gleaming chain from the end of the rainbow.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.link_rounded,
    color: Color(0xFFFFD54F),
  );

  // ── Easter / Spring (Mar 28 – Apr 14) ────────────────────────────
  static const easterBunnyEars = DuckAccessory(
    id: 'seasonal_easter_bunny_ears',
    name: 'Bunny Ears',
    description: 'Soft, floppy ears for the Easter season.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.cruelty_free_rounded,
    color: Color(0xFFF48FB1),
  );
  static const easterEggBasket = DuckAccessory(
    id: 'seasonal_easter_egg_basket',
    name: 'Egg Basket',
    description: 'Overflowing with painted eggs.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.egg_rounded,
    color: Color(0xFF81C784),
  );
  static const easterFlowerLei = DuckAccessory(
    id: 'seasonal_easter_flower_lei',
    name: 'Flower Lei',
    description: 'A spring garland of daisies and tulips.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.local_florist_rounded,
    color: Color(0xFFFFF176),
  );

  // ── Earth Day (Apr 18 – Apr 28) ──────────────────────────────────
  static const earthLeafCrown = DuckAccessory(
    id: 'seasonal_earth_leaf_crown',
    name: 'Leaf Crown',
    description: 'Woven from fresh spring leaves.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.park_rounded,
    color: Color(0xFF4CAF50),
  );
  static const earthGlobe = DuckAccessory(
    id: 'seasonal_earth_globe',
    name: 'Mini Globe',
    description: 'A tiny planet Earth, just for you.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.public_rounded,
    color: Color(0xFF42A5F5),
  );

  // ── Cinco de Mayo (Apr 30 – May 10) ──────────────────────────────
  static const cincoSombrero = DuckAccessory(
    id: 'seasonal_cinco_sombrero',
    name: 'Mini Sombrero',
    description: 'A festive sombrero with colourful trim.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFFF7043),
  );
  static const cincoMaracas = DuckAccessory(
    id: 'seasonal_cinco_maracas',
    name: 'Maracas',
    description: 'Shake and celebrate!',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.music_note_rounded,
    color: Color(0xFFFFCA28),
  );

  // ── Summer Splash (Jun 1 – Aug 31) ───────────────────────────────
  static const summerSunHat = DuckAccessory(
    id: 'seasonal_summer_sun_hat',
    name: 'Sun Hat',
    description: 'Stay cool under the summer sun.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFFDD835),
  );
  static const summerBeachBall = DuckAccessory(
    id: 'seasonal_summer_beach_ball',
    name: 'Beach Ball',
    description: 'A colourful inflatable for pool days.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.sports_volleyball_rounded,
    color: Color(0xFFFF7043),
  );
  static const summerTropicalShades = DuckAccessory(
    id: 'seasonal_summer_tropical_shades',
    name: 'Tropical Shades',
    description: 'Neon frames with gradient lenses.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.visibility_rounded,
    color: Color(0xFF26C6DA),
  );
  static const summerSeashellNecklace = DuckAccessory(
    id: 'seasonal_summer_seashell_necklace',
    name: 'Seashell Necklace',
    description: 'Collected from the shore at dawn.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.catching_pokemon,
    color: Color(0xFFFFAB91),
  );

  // ── Independence Day (Jun 28 – Jul 8) ────────────────────────────
  static const julySparkler = DuckAccessory(
    id: 'seasonal_july_sparkler',
    name: 'Sparkler',
    description: 'A fizzing golden sparkler.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.flare_rounded,
    color: Color(0xFFFFD54F),
  );
  static const julyStarBandana = DuckAccessory(
    id: 'seasonal_july_star_bandana',
    name: 'Star Bandana',
    description: 'Red, white & blue with star patterns.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.star_rounded,
    color: Color(0xFF42A5F5),
  );

  // ── Back to School (Aug 15 – Sep 7) ─────────────────────────────
  static const schoolGradCap = DuckAccessory(
    id: 'seasonal_school_grad_cap',
    name: 'Grad Cap',
    description: 'Knowledge is power — wear it proudly.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.school_rounded,
    color: Color(0xFF5C6BC0),
  );
  static const schoolBookStack = DuckAccessory(
    id: 'seasonal_school_book_stack',
    name: 'Book Stack',
    description: 'A perfectly balanced tower of textbooks.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.menu_book_rounded,
    color: Color(0xFF8D6E63),
  );
  static const schoolNerdGlasses = DuckAccessory(
    id: 'seasonal_school_nerd_glasses',
    name: 'Nerd Glasses',
    description: 'Thick frames and tape in the middle.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.visibility_rounded,
    color: Color(0xFF78909C),
  );

  // ── Halloween (Oct 1 – Nov 3) ────────────────────────────────────
  static const halloweenWitchHat = DuckAccessory(
    id: 'seasonal_hw_witch_hat',
    name: 'Witch Hat',
    description: 'Pointy, crooked, and slightly spooky.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.auto_fix_high_rounded,
    color: Color(0xFF7E57C2),
  );
  static const halloweenPumpkinBucket = DuckAccessory(
    id: 'seasonal_hw_pumpkin_bucket',
    name: 'Pumpkin Bucket',
    description: 'Trick or treat — fill it with candy!',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFFF7043),
  );
  static const halloweenSpiderwebBoa = DuckAccessory(
    id: 'seasonal_hw_spiderweb_boa',
    name: 'Spiderweb Boa',
    description: 'Draped in delicate webs — fashionably creepy.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.pest_control_rounded,
    color: Color(0xFFBDBDBD),
  );
  static const halloweenGhostGoggles = DuckAccessory(
    id: 'seasonal_hw_ghost_goggles',
    name: 'Ghost Goggles',
    description: 'See spirits (or just look adorable).',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.visibility_off_rounded,
    color: Color(0xFFB0BEC5),
  );

  // ── Thanksgiving (Nov 10 – Nov 30) ──────────────────────────────
  static const thanksgivingPilgrimHat = DuckAccessory(
    id: 'seasonal_tg_pilgrim_hat',
    name: 'Pilgrim Hat',
    description: 'A classic buckle hat for the grateful duck.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.agriculture_rounded,
    color: Color(0xFF8D6E63),
  );
  static const thanksgivingCornucopia = DuckAccessory(
    id: 'seasonal_tg_cornucopia',
    name: 'Cornucopia',
    description: 'A horn of plenty, overflowing with goodies.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.restaurant_rounded,
    color: Color(0xFFFF8F00),
  );
  static const thanksgivingAutumnScarf = DuckAccessory(
    id: 'seasonal_tg_autumn_scarf',
    name: 'Autumn Scarf',
    description: 'Warm oranges and deep reds for fall vibes.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.dry_cleaning_rounded,
    color: Color(0xFFFF7043),
  );

  // ── Winter Wonderland (Dec 1 – Dec 31) ──────────────────────────
  static const winterSantaHat = DuckAccessory(
    id: 'seasonal_winter_santa_hat',
    name: 'Santa Hat',
    description: 'Ho ho ho — tis the season!',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.ac_unit_rounded,
    color: Color(0xFFEF5350),
  );
  static const winterCandyCane = DuckAccessory(
    id: 'seasonal_winter_candy_cane',
    name: 'Candy Cane',
    description: 'A sweet peppermint treat.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.restaurant_rounded,
    color: Color(0xFFE57373),
  );
  static const winterSnowflakeChoker = DuckAccessory(
    id: 'seasonal_winter_snowflake_choker',
    name: 'Snowflake Choker',
    description: 'A delicate chain with a crystal snowflake.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.ac_unit_rounded,
    color: Color(0xFF90CAF9),
  );
  static const winterFrostedGoggles = DuckAccessory(
    id: 'seasonal_winter_frosted_goggles',
    name: 'Frosted Goggles',
    description: 'Ski-ready goggles with icy lenses.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.visibility_rounded,
    color: Color(0xFF80DEEA),
  );

  // ── Lunar New Year (Jan 20 – Feb 10) ─────────────────────────────
  static const lunarDragonMask = DuckAccessory(
    id: 'seasonal_lunar_dragon_mask',
    name: 'Dragon Mask',
    description: 'Celebrate the Year of the Dragon.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.epic,
    price: 0,
    icon: Icons.whatshot_rounded,
    color: Color(0xFFEF5350),
  );
  static const lunarRedEnvelope = DuckAccessory(
    id: 'seasonal_lunar_red_envelope',
    name: 'Red Envelope',
    description: 'Good luck and prosperity!',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.card_giftcard_rounded,
    color: Color(0xFFD32F2F),
  );
  static const lunarLanternNecklace = DuckAccessory(
    id: 'seasonal_lunar_lantern_necklace',
    name: 'Lantern Necklace',
    description: 'A miniature paper lantern on a silk cord.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.light_rounded,
    color: Color(0xFFFFB300),
  );

  // ── Spring Equinox (Mar 18 – Mar 24) ─────────────────────────────
  static const springButterflyBow = DuckAccessory(
    id: 'seasonal_spring_butterfly_bow',
    name: 'Butterfly Bow',
    description: 'A silk bow with embroidered butterflies.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.flutter_dash,
    color: Color(0xFFAB47BC),
  );
  static const springWateringCan = DuckAccessory(
    id: 'seasonal_spring_watering_can',
    name: 'Watering Can',
    description: 'Time to help the flowers bloom.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.water_drop_rounded,
    color: Color(0xFF66BB6A),
  );

  // ── Pride Month (Jun 1 – Jun 30) ─────────────────────────────────
  static const prideRainbowHat = DuckAccessory(
    id: 'seasonal_pride_rainbow_hat',
    name: 'Rainbow Hat',
    description: 'All the colours — all the love.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.palette_rounded,
    color: Color(0xFFE040FB),
  );
  static const prideFlag = DuckAccessory(
    id: 'seasonal_pride_flag',
    name: 'Mini Flag',
    description: 'Wave it high and proud.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.flag_rounded,
    color: Color(0xFFFF7043),
  );
  static const prideRainbowScarf = DuckAccessory(
    id: 'seasonal_pride_rainbow_scarf',
    name: 'Rainbow Scarf',
    description: 'A flowing scarf in every colour.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.dry_cleaning_rounded,
    color: Color(0xFF42A5F5),
  );

  // ── Autumn Harvest (Sep 15 – Oct 15) ─────────────────────────────
  static const autumnLeafCrown = DuckAccessory(
    id: 'seasonal_autumn_leaf_crown',
    name: 'Maple Crown',
    description: 'Red and golden maple leaves woven together.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.park_rounded,
    color: Color(0xFFFF8F00),
  );
  static const autumnLantern = DuckAccessory(
    id: 'seasonal_autumn_lantern',
    name: 'Harvest Lantern',
    description: 'A warm glow for chilly evenings.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.light_rounded,
    color: Color(0xFFFFA726),
  );
  static const autumnKnitScarf = DuckAccessory(
    id: 'seasonal_autumn_knit_scarf',
    name: 'Knit Scarf',
    description: 'Hand-knitted with love and autumn colours.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.dry_cleaning_rounded,
    color: Color(0xFFBF360C),
  );

  // ── World Water Day (Mar 18 – Mar 26) ────────────────────────────
  static const waterDayDropletHat = DuckAccessory(
    id: 'seasonal_wwd_droplet_hat',
    name: 'Droplet Hat',
    description: 'Shaped like a giant raindrop.',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.water_drop_rounded,
    color: Color(0xFF42A5F5),
  );
  static const waterDayWaveGoggles = DuckAccessory(
    id: 'seasonal_wwd_wave_goggles',
    name: 'Wave Goggles',
    description: 'Lenses tinted like ocean waves.',
    slot: AccessorySlot.eyewear,
    rarity: AccessoryRarity.uncommon,
    price: 0,
    icon: Icons.waves_rounded,
    color: Color(0xFF0288D1),
  );

  // ── Waddle Anniversary (May 1 – May 14) ─────────────────────────
  static const anniPartyCrown = DuckAccessory(
    id: 'seasonal_anni_party_crown',
    name: 'Anniversary Crown',
    description: 'Celebrate another year of staying hydrated!',
    slot: AccessorySlot.hat,
    rarity: AccessoryRarity.epic,
    price: 0,
    icon: Icons.emoji_events_rounded,
    color: Color(0xFFFFD54F),
  );
  static const anniConfettiWand = DuckAccessory(
    id: 'seasonal_anni_confetti_wand',
    name: 'Confetti Wand',
    description: 'Wave it for instant celebration.',
    slot: AccessorySlot.held,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFFE040FB),
  );
  static const anniBadgeChain = DuckAccessory(
    id: 'seasonal_anni_badge_chain',
    name: 'Badge Chain',
    description: 'A chain of tiny Waddle badges.',
    slot: AccessorySlot.neckwear,
    rarity: AccessoryRarity.rare,
    price: 0,
    icon: Icons.verified_rounded,
    color: Color(0xFF66BB6A),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// SEASONAL THEME DEFINITIONS
// ═══════════════════════════════════════════════════════════════════════
// Each pack includes one exclusive theme only obtainable from that pack.

class _T {
  _T._();

  static const lunarNewYear = ThemeReward(
    id: 'seasonal_lunar_new_year',
    name: 'Lantern Festival',
    description: 'Red and gold lanterns light up the night sky.',
    gradientColors: [Color(0xFFB71C1C), Color(0xFFFF8F00)],
    icon: Icons.light_rounded,
    effect: ThemeEffect.fireflies,
    primaryColor: Color(0xFFD32F2F),
    accentColor: Color(0xFFFFB300),
    tier: ThemeTier.rare,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Lunar New Year Pack',
    ),
  );

  static const newYearsBash = ThemeReward(
    id: 'seasonal_new_years_bash',
    name: 'Midnight Countdown',
    description: 'A glittering sky of confetti and fireworks.',
    gradientColors: [Color(0xFF1A237E), Color(0xFFFFD54F)],
    icon: Icons.celebration_rounded,
    effect: ThemeEffect.sparkles,
    primaryColor: Color(0xFF283593),
    accentColor: Color(0xFFFFD54F),
    tier: ThemeTier.rare,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: "New Year's Bash Pack",
    ),
  );

  static const valentinesDay = ThemeReward(
    id: 'seasonal_valentines_day',
    name: 'Love Bloom',
    description: 'Soft pinks and floating rose petals.',
    gradientColors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    icon: Icons.favorite_rounded,
    effect: ThemeEffect.petals,
    primaryColor: Color(0xFFC62828),
    accentColor: Color(0xFFF48FB1),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: "Valentine's Day Pack",
    ),
  );

  static const stPatricksDay = ThemeReward(
    id: 'seasonal_st_patricks_day',
    name: 'Emerald Isle',
    description: 'Lush green hills under a lucky rainbow.',
    gradientColors: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
    icon: Icons.eco_rounded,
    effect: ThemeEffect.leaves,
    primaryColor: Color(0xFF2E7D32),
    accentColor: Color(0xFF66BB6A),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: "St. Patrick's Day Pack",
    ),
  );

  static const worldWaterDay = ThemeReward(
    id: 'seasonal_world_water_day',
    name: 'Crystal Current',
    description: 'Pure, flowing water in sparkling blue.',
    gradientColors: [Color(0xFFE1F5FE), Color(0xFF81D4FA)],
    icon: Icons.water_drop_rounded,
    effect: ThemeEffect.raindrops,
    primaryColor: Color(0xFF0277BD),
    accentColor: Color(0xFF4FC3F7),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'World Water Day Pack',
    ),
  );

  static const springEquinox = ThemeReward(
    id: 'seasonal_spring_equinox',
    name: 'Cherry Blossom',
    description: 'Pink petals drifting through a warm breeze.',
    gradientColors: [Color(0xFFFCE4EC), Color(0xFFF3E5F5)],
    icon: Icons.local_florist_rounded,
    effect: ThemeEffect.blossoms,
    primaryColor: Color(0xFFAD1457),
    accentColor: Color(0xFFCE93D8),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Spring Equinox Pack',
    ),
  );

  static const easterSpring = ThemeReward(
    id: 'seasonal_easter_spring',
    name: 'Egg Hunt Meadow',
    description: 'A sunlit field dotted with colourful eggs.',
    gradientColors: [Color(0xFFF1F8E9), Color(0xFFC8E6C9)],
    icon: Icons.egg_rounded,
    effect: ThemeEffect.petals,
    primaryColor: Color(0xFF558B2F),
    accentColor: Color(0xFFAED581),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Easter & Spring Pack',
    ),
  );

  static const earthDay = ThemeReward(
    id: 'seasonal_earth_day',
    name: 'Planet Blue',
    description: 'Earth from orbit — oceans, clouds & continents.',
    gradientColors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
    icon: Icons.public_rounded,
    effect: ThemeEffect.waves,
    primaryColor: Color(0xFF1565C0),
    accentColor: Color(0xFF64B5F6),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Earth Day Pack',
    ),
  );

  static const cincoDeMayo = ThemeReward(
    id: 'seasonal_cinco_de_mayo',
    name: 'Fiesta Sunset',
    description: 'Warm oranges and magentas — a vibrant celebration.',
    gradientColors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
    icon: Icons.wb_sunny_rounded,
    effect: ThemeEffect.sparkles,
    primaryColor: Color(0xFFE65100),
    accentColor: Color(0xFFFFAB40),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Cinco de Mayo Pack',
    ),
  );

  static const waddleAnniversary = ThemeReward(
    id: 'seasonal_waddle_anniversary',
    name: 'Birthday Bash',
    description: 'Confetti streamers and party sparkles!',
    gradientColors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    icon: Icons.emoji_events_rounded,
    effect: ThemeEffect.sparkles,
    primaryColor: Color(0xFFF57F17),
    accentColor: Color(0xFFFFD54F),
    tier: ThemeTier.epic,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Waddle Anniversary Pack',
    ),
  );

  static const prideMonth = ThemeReward(
    id: 'seasonal_pride_month',
    name: 'Rainbow Sky',
    description: 'Every colour of the rainbow, shining bright.',
    gradientColors: [Color(0xFFFCE4EC), Color(0xFFE1F5FE)],
    icon: Icons.palette_rounded,
    effect: ThemeEffect.sparkles,
    primaryColor: Color(0xFF6A1B9A),
    accentColor: Color(0xFFE040FB),
    tier: ThemeTier.rare,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Pride Month Pack',
    ),
  );

  static const summerSplash = ThemeReward(
    id: 'seasonal_summer_splash',
    name: 'Tropical Paradise',
    description: 'Turquoise waters under a blazing sun.',
    gradientColors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
    icon: Icons.pool_rounded,
    effect: ThemeEffect.bubbles,
    primaryColor: Color(0xFF00838F),
    accentColor: Color(0xFF26C6DA),
    tier: ThemeTier.rare,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Summer Splash Pack',
    ),
  );

  static const independenceDay = ThemeReward(
    id: 'seasonal_independence_day',
    name: 'Firework Night',
    description: 'Red, white & blue bursts across a dark sky.',
    gradientColors: [Color(0xFF1A237E), Color(0xFFE53935)],
    icon: Icons.flare_rounded,
    effect: ThemeEffect.sparkles,
    primaryColor: Color(0xFF283593),
    accentColor: Color(0xFFEF5350),
    tier: ThemeTier.rare,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Independence Day Pack',
    ),
  );

  static const backToSchool = ThemeReward(
    id: 'seasonal_back_to_school',
    name: 'Chalkboard',
    description: 'Green board, white chalk & doodle equations.',
    gradientColors: [Color(0xFF263238), Color(0xFF37474F)],
    icon: Icons.school_rounded,
    effect: ThemeEffect.dust,
    primaryColor: Color(0xFF78909C),
    accentColor: Color(0xFFB0BEC5),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Back to School Pack',
    ),
  );

  static const autumnHarvest = ThemeReward(
    id: 'seasonal_autumn_harvest',
    name: 'Golden Canopy',
    description: 'Amber leaves falling through dappled sunlight.',
    gradientColors: [Color(0xFFFFF8E1), Color(0xFFFFCC80)],
    icon: Icons.park_rounded,
    effect: ThemeEffect.leaves,
    primaryColor: Color(0xFFE65100),
    accentColor: Color(0xFFFFA726),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Autumn Harvest Pack',
    ),
  );

  static const halloween = ThemeReward(
    id: 'seasonal_halloween',
    name: 'Haunted Hollow',
    description: 'Spooky purple mist and flickering jack-o\'-lanterns.',
    gradientColors: [Color(0xFF1A0033), Color(0xFF4A148C)],
    icon: Icons.auto_fix_high_rounded,
    effect: ThemeEffect.fireflies,
    primaryColor: Color(0xFF6A1B9A),
    accentColor: Color(0xFFCE93D8),
    tier: ThemeTier.epic,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Halloween Pack',
    ),
  );

  static const thanksgiving = ThemeReward(
    id: 'seasonal_thanksgiving',
    name: 'Harvest Table',
    description: 'Warm candlelight over a rustic wooden spread.',
    gradientColors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
    icon: Icons.restaurant_rounded,
    effect: ThemeEffect.sunbeams,
    primaryColor: Color(0xFF5D4037),
    accentColor: Color(0xFFA1887F),
    tier: ThemeTier.uncommon,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Thanksgiving Pack',
    ),
  );

  static const winterWonderland = ThemeReward(
    id: 'seasonal_winter_wonderland',
    name: 'Frosted Cabin',
    description: 'Snowflakes drifting past a warm cabin glow.',
    gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    icon: Icons.ac_unit_rounded,
    effect: ThemeEffect.snowflakes,
    primaryColor: Color(0xFF1565C0),
    accentColor: Color(0xFF90CAF9),
    tier: ThemeTier.epic,
    unlockCondition: ThemeUnlockCondition(
      type: ThemeUnlockType.purchase,
      value: 0,
      displayText: 'Winter Wonderland Pack',
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════
// FULL SEASONAL PACK SCHEDULE — 18 packs across the year
// ═══════════════════════════════════════════════════════════════════════

class SeasonalPacks {
  SeasonalPacks._();

  // ── Individual packs ─────────────────────────────────────────────

  static final lunarNewYear = SeasonalPack(
    id: 'lunar_new_year',
    name: 'Lunar New Year',
    description: 'Red envelopes, dragons & good fortune.',
    icon: Icons.whatshot_rounded,
    color: const Color(0xFFD32F2F),
    price: 200,
    availableFrom: DateTime(2026, 1, 20),
    availableUntil: DateTime(2026, 2, 9),
    accessories: [
      _S.lunarDragonMask,
      _S.lunarRedEnvelope,
      _S.lunarLanternNecklace
    ],
    theme: _T.lunarNewYear,
  );

  static final newYearsBash = SeasonalPack(
    id: 'new_years_bash',
    name: "New Year's Bash",
    description: 'Confetti, sparklers & midnight magic.',
    icon: Icons.celebration_rounded,
    color: const Color(0xFFFFD54F),
    price: 175,
    availableFrom: DateTime(2026, 12, 28),
    availableUntil: DateTime(2026, 1, 19),
    accessories: [_S.nyPartyHat, _S.nyNoisemaker, _S.nyConfettiGlasses],
    theme: _T.newYearsBash,
  );

  static final valentinesDay = SeasonalPack(
    id: 'valentines_day',
    name: "Valentine's Day",
    description: 'Hearts, roses & love letters.',
    icon: Icons.favorite_rounded,
    color: const Color(0xFFE91E63),
    price: 175,
    availableFrom: DateTime(2026, 2, 10),
    availableUntil: DateTime(2026, 2, 28),
    accessories: [_S.valHeartCrown, _S.valRoseGlasses, _S.valLoveLetter],
    theme: _T.valentinesDay,
  );

  static final stPatricksDay = SeasonalPack(
    id: 'st_patricks_day',
    name: "St. Patrick's Day",
    description: 'Lucky clovers & pots of gold.',
    icon: Icons.eco_rounded,
    color: const Color(0xFF4CAF50),
    price: 175,
    availableFrom: DateTime(2026, 3, 1),
    availableUntil: DateTime(2026, 3, 27),
    accessories: [_S.stpTopHat, _S.stpClover, _S.stpGoldChain],
    theme: _T.stPatricksDay,
  );

  static final worldWaterDay = SeasonalPack(
    id: 'world_water_day',
    name: 'World Water Day',
    description: 'Celebrate the source of life.',
    icon: Icons.water_drop_rounded,
    color: const Color(0xFF42A5F5),
    price: 150,
    availableFrom: DateTime(2026, 3, 18),
    availableUntil: DateTime(2026, 3, 26),
    accessories: [_S.waterDayDropletHat, _S.waterDayWaveGoggles],
    theme: _T.worldWaterDay,
  );

  static final springEquinox = SeasonalPack(
    id: 'spring_equinox',
    name: 'Spring Equinox',
    description: 'Butterflies, blossoms & fresh beginnings.',
    icon: Icons.local_florist_rounded,
    color: const Color(0xFF66BB6A),
    price: 125,
    availableFrom: DateTime(2026, 3, 18),
    availableUntil: DateTime(2026, 3, 24),
    accessories: [_S.springButterflyBow, _S.springWateringCan],
    theme: _T.springEquinox,
  );

  static final easterSpring = SeasonalPack(
    id: 'easter_spring',
    name: 'Easter & Spring',
    description: 'Bunny ears, painted eggs & flower leis.',
    icon: Icons.egg_rounded,
    color: const Color(0xFF81C784),
    price: 175,
    availableFrom: DateTime(2026, 3, 28),
    availableUntil: DateTime(2026, 4, 17),
    accessories: [_S.easterBunnyEars, _S.easterEggBasket, _S.easterFlowerLei],
    theme: _T.easterSpring,
  );

  static final earthDay = SeasonalPack(
    id: 'earth_day',
    name: 'Earth Day',
    description: 'Protect the planet — one sip at a time.',
    icon: Icons.public_rounded,
    color: const Color(0xFF42A5F5),
    price: 125,
    availableFrom: DateTime(2026, 4, 18),
    availableUntil: DateTime(2026, 4, 29),
    accessories: [_S.earthLeafCrown, _S.earthGlobe],
    theme: _T.earthDay,
  );

  static final cincoDeMayo = SeasonalPack(
    id: 'cinco_de_mayo',
    name: 'Cinco de Mayo',
    description: 'Sombreros, maracas & fiesta vibes.',
    icon: Icons.wb_sunny_rounded,
    color: const Color(0xFFFF7043),
    price: 125,
    availableFrom: DateTime(2026, 4, 30),
    availableUntil: DateTime(2026, 5, 10),
    accessories: [_S.cincoSombrero, _S.cincoMaracas],
    theme: _T.cincoDeMayo,
  );

  static final waddleAnniversary = SeasonalPack(
    id: 'waddle_anniversary',
    name: 'Waddle Anniversary',
    description: 'Celebrate another year of Waddle!',
    icon: Icons.emoji_events_rounded,
    color: const Color(0xFFFFD54F),
    price: 200,
    availableFrom: DateTime(2026, 5, 1),
    availableUntil: DateTime(2026, 5, 31),
    accessories: [_S.anniPartyCrown, _S.anniConfettiWand, _S.anniBadgeChain],
    theme: _T.waddleAnniversary,
  );

  static final prideMonth = SeasonalPack(
    id: 'pride_month',
    name: 'Pride Month',
    description: 'Love is love — celebrate with colour.',
    icon: Icons.flag_rounded,
    color: const Color(0xFFE040FB),
    price: 175,
    availableFrom: DateTime(2026, 6, 1),
    availableUntil: DateTime(2026, 6, 30),
    accessories: [_S.prideRainbowHat, _S.prideFlag, _S.prideRainbowScarf],
    theme: _T.prideMonth,
  );

  static final summerSplash = SeasonalPack(
    id: 'summer_splash',
    name: 'Summer Splash',
    description: 'Shades, beach balls & poolside vibes.',
    icon: Icons.pool_rounded,
    color: const Color(0xFFFDD835),
    price: 200,
    availableFrom: DateTime(2026, 6, 1),
    availableUntil: DateTime(2026, 9, 7),
    accessories: [
      _S.summerSunHat,
      _S.summerBeachBall,
      _S.summerTropicalShades,
      _S.summerSeashellNecklace,
    ],
    theme: _T.summerSplash,
  );

  static final independenceDay = SeasonalPack(
    id: 'independence_day',
    name: 'Independence Day',
    description: 'Sparklers & stars — fourth of July style.',
    icon: Icons.flare_rounded,
    color: const Color(0xFF42A5F5),
    price: 125,
    availableFrom: DateTime(2026, 6, 28),
    availableUntil: DateTime(2026, 7, 8),
    accessories: [_S.julySparkler, _S.julyStarBandana],
    theme: _T.independenceDay,
  );

  static final backToSchool = SeasonalPack(
    id: 'back_to_school',
    name: 'Back to School',
    description: 'Books, brains & brainy glasses.',
    icon: Icons.school_rounded,
    color: const Color(0xFF5C6BC0),
    price: 175,
    availableFrom: DateTime(2026, 8, 15),
    availableUntil: DateTime(2026, 9, 14),
    accessories: [_S.schoolGradCap, _S.schoolBookStack, _S.schoolNerdGlasses],
    theme: _T.backToSchool,
  );

  static final autumnHarvest = SeasonalPack(
    id: 'autumn_harvest',
    name: 'Autumn Harvest',
    description: 'Golden leaves, warm lanterns & cosy vibes.',
    icon: Icons.park_rounded,
    color: const Color(0xFFFF8F00),
    price: 175,
    availableFrom: DateTime(2026, 9, 15),
    availableUntil: DateTime(2026, 10, 15),
    accessories: [_S.autumnLeafCrown, _S.autumnLantern, _S.autumnKnitScarf],
    theme: _T.autumnHarvest,
  );

  static final halloween = SeasonalPack(
    id: 'halloween',
    name: 'Halloween',
    description: "Witches, ghosts & jack-o'-lanterns.",
    icon: Icons.auto_fix_high_rounded,
    color: const Color(0xFF7E57C2),
    price: 200,
    availableFrom: DateTime(2026, 10, 1),
    availableUntil: DateTime(2026, 11, 9),
    accessories: [
      _S.halloweenWitchHat,
      _S.halloweenPumpkinBucket,
      _S.halloweenSpiderwebBoa,
      _S.halloweenGhostGoggles,
    ],
    theme: _T.halloween,
  );

  static final thanksgiving = SeasonalPack(
    id: 'thanksgiving',
    name: 'Thanksgiving',
    description: 'Gratitude, harvest & cosy autumn warmth.',
    icon: Icons.restaurant_rounded,
    color: const Color(0xFF8D6E63),
    price: 175,
    availableFrom: DateTime(2026, 11, 10),
    availableUntil: DateTime(2026, 11, 30),
    accessories: [
      _S.thanksgivingPilgrimHat,
      _S.thanksgivingCornucopia,
      _S.thanksgivingAutumnScarf,
    ],
    theme: _T.thanksgiving,
  );

  static final winterWonderland = SeasonalPack(
    id: 'winter_wonderland',
    name: 'Winter Wonderland',
    description: 'Snowflakes, candy canes & holiday cheer.',
    icon: Icons.ac_unit_rounded,
    color: const Color(0xFF90CAF9),
    price: 200,
    availableFrom: DateTime(2026, 12, 1),
    availableUntil: DateTime(2026, 12, 31),
    accessories: [
      _S.winterSantaHat,
      _S.winterCandyCane,
      _S.winterSnowflakeChoker,
      _S.winterFrostedGoggles,
    ],
    theme: _T.winterWonderland,
  );

  // ── Master list ──────────────────────────────────────────────────

  static final List<SeasonalPack> all = [
    lunarNewYear,
    newYearsBash,
    valentinesDay,
    stPatricksDay,
    worldWaterDay,
    springEquinox,
    easterSpring,
    earthDay,
    cincoDeMayo,
    waddleAnniversary,
    prideMonth,
    summerSplash,
    independenceDay,
    backToSchool,
    autumnHarvest,
    halloween,
    thanksgiving,
    winterWonderland,
  ];

  /// All packs currently available based on today's date.
  static List<SeasonalPack> get currentlyAvailable =>
      all.where((p) => p.isCurrentlyAvailable).toList();

  /// Look up a pack by ID.
  static SeasonalPack? byId(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// All seasonal theme IDs across every pack.
  static Set<String> get allThemeIds => all.map((p) => p.theme.id).toSet();

  /// All seasonal accessory IDs across every pack (for validation).
  static Set<String> get allAccessoryIds =>
      all.expand((p) => p.accessories).map((a) => a.id).toSet();

  /// Look up a seasonal accessory by ID (across all packs).
  static DuckAccessory? accessoryById(String id) {
    for (final pack in all) {
      for (final acc in pack.accessories) {
        if (acc.id == id) return acc;
      }
    }
    return null;
  }
}
