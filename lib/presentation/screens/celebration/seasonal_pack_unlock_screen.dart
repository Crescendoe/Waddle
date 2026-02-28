import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/duck_accessory.dart';
import 'package:waddle/domain/entities/seasonal_pack.dart';
import 'package:waddle/presentation/widgets/common.dart';

// ═══════════════════════════════════════════════════════════════════════
// Seasonal Pack Unlock Screen
// Shows a celebratory reveal when the user claims or purchases a
// seasonal cosmetic pack. Each item (theme + accessories) is revealed
// with staggered animations so the user feels the full value.
// ═══════════════════════════════════════════════════════════════════════

class SeasonalPackUnlockScreen extends StatefulWidget {
  final String packId;

  const SeasonalPackUnlockScreen({super.key, required this.packId});

  @override
  State<SeasonalPackUnlockScreen> createState() =>
      _SeasonalPackUnlockScreenState();
}

class _SeasonalPackUnlockScreenState extends State<SeasonalPackUnlockScreen>
    with TickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final AnimationController _pulseController;
  final List<_Sparkle> _sparkles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _generateSparkles();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        _sparkleController.repeat();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  void _generateSparkles() {
    _sparkles.clear();
    for (int i = 0; i < 50; i++) {
      _sparkles.add(_Sparkle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 3 + _random.nextDouble() * 6,
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFFFF8E1),
          Colors.white,
          const Color(0xFFFFAB40),
          const Color(0xFF80DEEA),
          const Color(0xFFB388FF),
        ][_random.nextInt(6)],
        phase: _random.nextDouble() * pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pack = SeasonalPacks.byId(widget.packId);
    if (pack == null) {
      return Scaffold(
        body: GradientBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Pack not found'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final accentColor = pack.color;
    final theme = pack.theme;
    final accessories = pack.accessories;

    // Total items: 1 theme + N accessories
    final totalItems = 1 + accessories.length;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────────────
          GradientBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // ── Subtitle chip ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SEASONAL PACK',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

                    const SizedBox(height: 16),

                    // ── Pack title ───────────────────────────────────
                    Text(
                      pack.name,
                      style: AppTextStyles.displayLarge.copyWith(fontSize: 32),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                    const SizedBox(height: 8),

                    Text(
                      pack.description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 20),

                    // ── Pack hero icon with glow ─────────────────────
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.06);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withValues(alpha: 0.6),
                              accentColor,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            pack.icon,
                            size: 52,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 900.ms,
                          delay: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .then()
                        .shimmer(
                          duration: 2000.ms,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),

                    const SizedBox(height: 20),

                    // ── Items count badge ────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        '$totalItems items unlocked!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms),

                    const SizedBox(height: 16),

                    // ── Scrollable items list ────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Theme reward card
                            _ItemCard(
                              icon: theme.icon,
                              iconColor: Colors.white,
                              gradientColors: theme.gradientColors,
                              label: theme.name,
                              sublabel: 'Theme',
                              accentColor: theme.primaryColor,
                              delay: 1000,
                            ),

                            const SizedBox(height: 10),

                            // Accessory cards
                            ...accessories.asMap().entries.map((entry) {
                              final i = entry.key;
                              final acc = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ItemCard(
                                  icon: acc.icon,
                                  iconColor: acc.color,
                                  gradientColors: null,
                                  label: acc.name,
                                  sublabel:
                                      '${acc.slot.label} · ${acc.rarity.label}',
                                  accentColor: acc.rarity.color,
                                  delay: 1100 + (i * 150),
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // ── Continue button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Awesome!'),
                      ),
                    ).animate().fadeIn(
                        delay: (1100 + accessories.length * 150 + 200).ms),

                    const SizedBox(height: 10),
                    Text(
                      'Check out your new items in the Collection!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ).animate().fadeIn(
                        delay: (1100 + accessories.length * 150 + 400).ms),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Sparkle overlay ────────────────────────────────────────
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _sparkleController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SparklePainter(
                      sparkles: _sparkles,
                      progress: _sparkleController.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Individual item card — shows one reward (theme or accessory)
// ─────────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color>? gradientColors;
  final String label;
  final String sublabel;
  final Color accentColor;
  final int delay;

  const _ItemCard({
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
    required this.label,
    required this.sublabel,
    required this.accentColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradientColors != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors!,
                    )
                  : null,
              color: gradientColors == null
                  ? accentColor.withValues(alpha: 0.12)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 24,
                color: gradientColors != null ? Colors.white : iconColor,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name & sublabel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Checkmark
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF66BB6A).withValues(alpha: 0.14),
            ),
            child: const Center(
              child: Icon(
                Icons.check_rounded,
                size: 18,
                color: Color(0xFF66BB6A),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms)
        .slideX(begin: 0.15, delay: delay.ms, duration: 500.ms)
        .then()
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.15),
        );
  }
}

// ───────────────────────────────────────────────────────────────────
// Sparkle model & painter — gentle rising twinkles
// ───────────────────────────────────────────────────────────────────

class _Sparkle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double phase;

  _Sparkle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.phase,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Sparkle> sparkles;
  final double progress;

  _SparklePainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final rawT = (progress * s.speed + s.phase / (pi * 2)) % 1.0;

      final x = s.x * size.width + sin(rawT * pi * 4 + s.phase) * 20;
      final y = s.y * size.height - rawT * size.height * 0.3;

      final twinkle = (sin(rawT * pi * 2 + s.phase) + 1) / 2;
      final opacity = (twinkle * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = s.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rawT * pi);
      final path = Path()
        ..moveTo(0, -s.size)
        ..lineTo(s.size * 0.3, 0)
        ..lineTo(0, s.size)
        ..lineTo(-s.size * 0.3, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
