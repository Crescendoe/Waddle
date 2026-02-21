import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';

class CongratsScreen extends StatefulWidget {
  final int oldStreak;
  final int newStreak;

  const CongratsScreen({
    super.key,
    required this.oldStreak,
    required this.newStreak,
  });

  @override
  State<CongratsScreen> createState() => _CongratsScreenState();
}

class _CongratsScreenState extends State<CongratsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  late final AnimationController _streakController;
  late final Animation<int> _streakAnimation;
  final List<_ConfettiParticle> _particles = [];
  final _random = Random();
  final GlobalKey _streakKey = GlobalKey();

  bool _confettiFired = false;

  @override
  void initState() {
    super.initState();

    // --- Confetti (3 seconds, does NOT start yet) ---
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _generateParticles();

    // --- Streak count-up (fires after intro animations settle) ---
    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _streakAnimation = IntTween(
      begin: widget.oldStreak,
      end: widget.newStreak,
    ).animate(CurvedAnimation(
      parent: _streakController,
      curve: Curves.easeOutCubic,
    ));

    // When the count-up finishes → fire confetti burst
    _streakController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_confettiFired) {
        _confettiFired = true;
        _regenerateParticlesFromStreak();
        _confettiController.forward();
      }
    });

    // Start the streak count-up after a delay so the intro text is visible
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _streakController.forward();
    });
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 60; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: 0,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 4 + _random.nextDouble() * 8,
        color: [
          AppColors.primary,
          AppColors.accent,
          const Color(0xFFFFD700),
          const Color(0xFFFF6B6B),
          const Color(0xFF66BB6A),
          const Color(0xFFAB47BC),
        ][_random.nextInt(6)],
        angle: _random.nextDouble() * pi * 2,
        directionX: (_random.nextDouble() - 0.5) * 2, // spread left/right
      ));
    }
  }

  /// Regenerate particles so they originate from the streak number's position.
  void _regenerateParticlesFromStreak() {
    final box = _streakKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final screenSize = MediaQuery.of(context).size;
    final pos =
        box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));
    final normX = pos.dx / screenSize.width;
    final normY = pos.dy / screenSize.height;

    _particles.clear();
    for (int i = 0; i < 80; i++) {
      _particles.add(_ConfettiParticle(
        x: normX,
        y: normY,
        speed: 0.4 + _random.nextDouble() * 0.6,
        size: 5 + _random.nextDouble() * 9,
        color: [
          AppColors.primary,
          AppColors.accent,
          const Color(0xFFFFD700),
          const Color(0xFFFF6B6B),
          const Color(0xFF66BB6A),
          const Color(0xFFAB47BC),
          const Color(0xFF42A5F5),
          const Color(0xFFFF8A65),
        ][_random.nextInt(8)],
        angle: _random.nextDouble() * pi * 2,
        directionX: (_random.nextDouble() - 0.5) * 2,
      ));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Spacer(),

                    // Trophy icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          size: 56, color: Colors.white),
                    ).animate().scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 32),

                    // "Goal Reached!" title
                    Text(
                      'Goal Reached!',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 36,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),

                    Text(
                      'You\'ve hit your daily water goal! 🎉\nKeep up the great work!',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 36),

                    // ── Streak count-up ──
                    AnimatedBuilder(
                      animation: _streakAnimation,
                      builder: (context, _) {
                        return Row(
                          key: _streakKey,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                color: Color(0xFFFF6B35), size: 40),
                            const SizedBox(width: 8),
                            Text(
                              '${_streakAnimation.value}',
                              style: AppTextStyles.displayLarge.copyWith(
                                fontSize: 52,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF6B35),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _streakAnimation.value == 1
                                  ? 'day streak'
                                  : 'day streak',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        );
                      },
                    ).animate().fadeIn(delay: 1000.ms).scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          delay: 1000.ms,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),

                    const SizedBox(height: 32),

                    // Duck mascot celebration
                    MascotImage(
                      assetPath: AppConstants.mascotFlying,
                      size: 120,
                    )
                        .animate()
                        .fadeIn(delay: 800.ms)
                        .slideY(begin: 0.3, end: 0)
                        .then()
                        .shimmer(duration: 1500.ms),

                    const Spacer(),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Continue'),
                      ),
                    ).animate().fadeIn(delay: 1400.ms),

                    const SizedBox(height: 12),
                    Text(
                      'Your streak has been updated!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ).animate().fadeIn(delay: 1600.ms),
                  ],
                ),
              ),
            ),
          ),

          // Confetti overlay – bursts from streak number
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _confettiController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
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

// ───────────────────────────────────────────────────────────────────
// Confetti particle model & painter (burst from origin point)
// ───────────────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x; // normalised origin X (0..1)
  final double y; // normalised origin Y (0..1)
  final double speed;
  final double size;
  final Color color;
  final double angle;
  final double directionX; // -1..1 horizontal spread

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.angle,
    this.directionX = 0,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);

      // Burst outward from origin, then fall with gravity
      final originX = p.x * size.width;
      final originY = p.y * size.height;
      final burstRadius = t * size.height * 0.6;
      final x = originX +
          cos(p.angle) * burstRadius * 0.5 +
          sin(p.angle + progress * 6) * 20 +
          p.directionX * burstRadius * 0.3;
      final y = originY +
          sin(p.angle) * burstRadius * 0.3 +
          t * t * size.height * 0.5; // gravity curve
      final opacity = (1.0 - t).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + progress * 4);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
