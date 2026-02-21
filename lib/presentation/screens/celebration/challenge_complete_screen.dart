import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/challenge.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/widgets/common.dart';

class ChallengeCompleteScreen extends StatefulWidget {
  final int challengeIndex;

  const ChallengeCompleteScreen({super.key, required this.challengeIndex});

  @override
  State<ChallengeCompleteScreen> createState() =>
      _ChallengeCompleteScreenState();
}

class _ChallengeCompleteScreenState extends State<ChallengeCompleteScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];
  final _random = Random();

  Challenge get challenge => Challenges.getByIndex(widget.challengeIndex);

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _generateParticles();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _confettiController.forward();
      }
    });
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 80; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: 0,
        speed: 0.3 + _random.nextDouble() * 0.7,
        size: 4 + _random.nextDouble() * 8,
        color: [
          challenge.color,
          AppColors.primary,
          AppColors.accent,
          const Color(0xFFFFD700),
          const Color(0xFF66BB6A),
          const Color(0xFFAB47BC),
        ][_random.nextInt(6)],
        angle: _random.nextDouble() * pi * 2,
        directionX: (_random.nextDouble() - 0.5) * 2,
      ));
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            colors: [
              challenge.color.withValues(alpha: 0.15),
              challenge.color.withValues(alpha: 0.05),
            ],
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Spacer(),

                    // Challenge mascot
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: challenge.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: challenge.color.withValues(alpha: 0.3),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          challenge.imagePath,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.emoji_events_rounded,
                            size: 64,
                            color: challenge.color,
                          ),
                        ),
                      ),
                    ).animate().scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Challenge Complete!',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 34,
                        color: challenge.color,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),

                    Text(
                      challenge.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 8),

                    Text(
                      'You crushed it! 14 days of dedication.\nYou\'ve proven your commitment to healthier hydration.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 800.ms),

                    const SizedBox(height: 36),

                    // Achievement stat
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: challenge.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: challenge.color.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: challenge.color, size: 32),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '14 Days Strong',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: challenge.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'New challenge unlocked in ducks & themes!',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 1000.ms).scale(
                          begin: const Offset(0.9, 0.9),
                          delay: 1000.ms,
                          duration: 400.ms,
                          curve: Curves.easeOut,
                        ),

                    const Spacer(),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context
                              .read<HydrationCubit>()
                              .acknowledgeChallengeResult();
                          context.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: challenge.color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Continue'),
                      ),
                    ).animate().fadeIn(delay: 1200.ms),

                    const SizedBox(height: 12),
                    Text(
                      'Your collection has been updated!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ).animate().fadeIn(delay: 1400.ms),
                  ],
                ),
              ),
            ),
          ),

          // Confetti overlay
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

// ── Confetti system ──────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double angle;
  final double directionX;

  const _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.angle,
    required this.directionX,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final opacity = t < 0.7 ? 1.0 : (1.0 - (t - 0.7) / 0.3);

      final x = p.x * size.width + p.directionX * t * size.width * 0.3;
      final y = p.y * size.height + t * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + t * 6);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
