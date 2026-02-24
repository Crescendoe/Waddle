import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';

// ═══════════════════════════════════════════════════════════════════════
// Level Up Screen
// Celebration shown when the user reaches a new XP level.
// ═══════════════════════════════════════════════════════════════════════

class LevelUpScreen extends StatefulWidget {
  final int oldLevel;
  final int newLevel;
  final int dropsAwarded;

  const LevelUpScreen({
    super.key,
    required this.oldLevel,
    required this.newLevel,
    this.dropsAwarded = 30,
  });

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringsController;
  late final AnimationController _counterController;
  late final Animation<int> _levelCount;
  final List<_Ring> _rings = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    _ringsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _counterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _levelCount = IntTween(
      begin: widget.oldLevel,
      end: widget.newLevel,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.easeOutCubic,
    ));

    _generateRings();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _ringsController.repeat();
        _counterController.forward();
      }
    });
  }

  void _generateRings() {
    for (int i = 0; i < 6; i++) {
      _rings.add(_Ring(
        delay: i * 0.15,
        maxRadius: 120 + _random.nextDouble() * 80,
        strokeWidth: 2 + _random.nextDouble() * 2,
        color: [
          const Color(0xFFFFD700),
          const Color(0xFFFFC107),
          const Color(0xFFFF9800),
          const Color(0xFFFFEB3B),
          const Color(0xFFFFF176),
          const Color(0xFFFFCC02),
        ][i],
      ));
    }
  }

  @override
  void dispose() {
    _ringsController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          GradientBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Spacer(),

                    // ── Subtitle chip ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'LEVEL UP!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFFF8F00),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

                    const SizedBox(height: 20),

                    // ── Title ────────────────────────────────────────
                    Text(
                      'You leveled up!',
                      style: AppTextStyles.displayLarge.copyWith(fontSize: 34),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                    const SizedBox(height: 36),

                    // ── Level badge with expanding rings ─────────────
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated rings
                          AnimatedBuilder(
                            animation: _ringsController,
                            builder: (context, _) {
                              return CustomPaint(
                                size: const Size(240, 240),
                                painter: _RingsPainter(
                                  rings: _rings,
                                  progress: _ringsController.value,
                                ),
                              );
                            },
                          ),

                          // Level number
                          AnimatedBuilder(
                            animation: _levelCount,
                            builder: (context, _) {
                              return Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFFD54F),
                                      Color(0xFFFF8F00),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 28,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${_levelCount.value}',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                              .animate()
                              .scale(
                                begin: const Offset(0, 0),
                                end: const Offset(1, 1),
                                duration: 800.ms,
                                delay: 600.ms,
                                curve: Curves.elasticOut,
                              )
                              .then()
                              .shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Drops reward ─────────────────────────────────
                    if (widget.dropsAwarded > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.water_drop_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+${widget.dropsAwarded} drops',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.15),

                    const SizedBox(height: 16),

                    // ── Description ──────────────────────────────────
                    Text(
                      'Keep hydrating to earn more XP\nand reach the next level!',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 1400.ms),

                    const Spacer(),

                    // ── Continue button ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8F00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Awesome!'),
                      ),
                    ).animate().fadeIn(delay: 1600.ms),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // ── Ring overlay ───────────────────────────────────────────
          // (rings are already painted inside the Stack above)
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────
// Expanding ring model & painter
// ───────────────────────────────────────────────────────────────────

class _Ring {
  final double delay;
  final double maxRadius;
  final double strokeWidth;
  final Color color;

  _Ring({
    required this.delay,
    required this.maxRadius,
    required this.strokeWidth,
    required this.color,
  });
}

class _RingsPainter extends CustomPainter {
  final List<_Ring> rings;
  final double progress;

  _RingsPainter({required this.rings, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final ring in rings) {
      final t = ((progress - ring.delay) % 1.0).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final radius = t * ring.maxRadius;
      // Fade out as ring expands
      final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.6;

      final paint = Paint()
        ..color = ring.color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring.strokeWidth * (1.0 - t * 0.5);

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
