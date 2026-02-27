import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════
// IN-APP PURCHASE PRODUCT CATALOG
// ═══════════════════════════════════════════════════════════════════════
//
// All IAP product IDs and metadata.  These IDs must match the products
// configured in Google Play Console and App Store Connect.
//
// Product types:
//   • Drop bundles  — consumable (one-time, repeatable)
//   • Subscriptions — auto-renewable (monthly / annual)
// ═══════════════════════════════════════════════════════════════════════

// ── Drop bundles ─────────────────────────────────────────────────────

class DropBundle extends Equatable {
  final String productId;
  final String name;
  final String description;
  final int drops;
  final String displayPrice; // fallback; real price comes from store
  final IconData icon;
  final Color color;

  /// Whether to show a "Best Value" badge on this bundle.
  final bool bestValue;

  /// Whether to show a "Popular" badge.
  final bool popular;

  const DropBundle({
    required this.productId,
    required this.name,
    required this.description,
    required this.drops,
    required this.displayPrice,
    required this.icon,
    required this.color,
    this.bestValue = false,
    this.popular = false,
  });

  @override
  List<Object?> get props => [productId];
}

class DropBundles {
  DropBundles._();

  static const splash = DropBundle(
    productId: 'drops_splash_150',
    name: 'Splash',
    description: '150 Drops to get started',
    drops: 150,
    displayPrice: '\$0.99',
    icon: Icons.water_drop_outlined,
    color: Color(0xFF90CAF9),
  );

  static const stream = DropBundle(
    productId: 'drops_stream_400',
    name: 'Stream',
    description: '400 Drops — steady flow',
    drops: 400,
    displayPrice: '\$1.99',
    icon: Icons.water_rounded,
    color: Color(0xFF42A5F5),
    popular: true,
  );

  static const waterfall = DropBundle(
    productId: 'drops_waterfall_1000',
    name: 'Waterfall',
    description: '1,000 Drops — a rushing cascade',
    drops: 1000,
    displayPrice: '\$3.99',
    icon: Icons.waves_rounded,
    color: Color(0xFF1E88E5),
  );

  static const tsunami = DropBundle(
    productId: 'drops_tsunami_2500',
    name: 'Tsunami',
    description: '2,500 Drops — unstoppable wave',
    drops: 2500,
    displayPrice: '\$7.99',
    icon: Icons.tsunami_rounded,
    color: Color(0xFF0D47A1),
    bestValue: true,
  );

  static const List<DropBundle> all = [splash, stream, waterfall, tsunami];

  /// All product IDs for store queries.
  static Set<String> get productIds => all.map((b) => b.productId).toSet();

  static DropBundle? byProductId(String id) {
    try {
      return all.firstWhere((b) => b.productId == id);
    } catch (_) {
      return null;
    }
  }
}

// ── Subscription tiers ───────────────────────────────────────────────

class SubscriptionTier extends Equatable {
  final String productId;
  final String name;
  final String displayPrice;
  final String period; // 'monthly' | 'annual'
  final String? savings; // e.g. 'Save 44%'

  const SubscriptionTier({
    required this.productId,
    required this.name,
    required this.displayPrice,
    required this.period,
    this.savings,
  });

  @override
  List<Object?> get props => [productId];
}

class Subscriptions {
  Subscriptions._();

  static const monthly = SubscriptionTier(
    productId: 'waddle_plus_monthly',
    name: 'Waddle+',
    displayPrice: '\$1.49/mo',
    period: 'monthly',
  );

  static const annual = SubscriptionTier(
    productId: 'waddle_plus_annual',
    name: 'Waddle+',
    displayPrice: '\$9.99/yr',
    period: 'annual',
    savings: 'Save 44%',
  );

  static const List<SubscriptionTier> all = [monthly, annual];

  static Set<String> get productIds => all.map((s) => s.productId).toSet();

  /// All consumable + subscription product IDs for store initialization.
  static Set<String> get allProductIds => {
        ...DropBundles.productIds,
        ...productIds,
      };
}

// ── Subscription perks (displayed in UI) ─────────────────────────────

class SubscriptionPerk {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const SubscriptionPerk({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class SubscriptionPerks {
  SubscriptionPerks._();

  static const List<SubscriptionPerk> all = [
    SubscriptionPerk(
      icon: Icons.water_drop_rounded,
      title: '1.5× Drop Multiplier',
      description: 'Earn 50% more Drops from quests, goals, and challenges.',
      color: Color(0xFF42A5F5),
    ),
    SubscriptionPerk(
      icon: Icons.verified_rounded,
      title: 'Subscriber Badge',
      description:
          'A shiny badge next to your name on your profile and friend list.',
      color: Color(0xFFFFD54F),
    ),
    SubscriptionPerk(
      icon: Icons.task_alt_rounded,
      title: 'Extra Quest Slot',
      description: '4 daily quests instead of 3 — more XP and Drops each day.',
      color: Color(0xFF66BB6A),
    ),
    SubscriptionPerk(
      icon: Icons.edit_rounded,
      title: 'Name Your Duck',
      description: 'Give your active duck companion a custom nickname.',
      color: Color(0xFFAB47BC),
    ),
  ];
}
