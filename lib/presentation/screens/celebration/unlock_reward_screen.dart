import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';
import 'package:waddle/domain/entities/duck_accessory.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/presentation/widgets/duck_avatar.dart';

// ═══════════════════════════════════════════════════════════════════════
// Unlock Reward Screen
// Shows when the user earns a new duck companion or app theme.
// Similar to CongratsScreen but with a distinct shimmer + glow vibe.
// ═══════════════════════════════════════════════════════════════════════

enum UnlockRewardType { duck, theme, accessory }

class UnlockRewardScreen extends StatefulWidget {
  final UnlockRewardType type;

  /// For [UnlockRewardType.duck]: the duck's index in [DuckCompanions.all].
  final int? duckIndex;

  /// For [UnlockRewardType.theme]: the [ThemeReward.id].
  final String? themeId;

  /// For [UnlockRewardType.accessory]: the [DuckAccessory.id].
  final String? accessoryId;

  const UnlockRewardScreen({
    super.key,
    required this.type,
    this.duckIndex,
    this.themeId,
    this.accessoryId,
  });

  @override
  State<UnlockRewardScreen> createState() => _UnlockRewardScreenState();
}

class _UnlockRewardScreenState extends State<UnlockRewardScreen>
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

    // Start sparkles after the reveal animation
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
    final isDuck = widget.type == UnlockRewardType.duck;
    final isTheme = widget.type == UnlockRewardType.theme;
    final isAccessory = widget.type == UnlockRewardType.accessory;
    final duck = isDuck && widget.duckIndex != null
        ? DuckCompanions.all[widget.duckIndex!]
        : null;
    final theme = isTheme && widget.themeId != null
        ? ThemeRewards.all.where((t) => t.id == widget.themeId).firstOrNull
        : null;
    final accessory = isAccessory && widget.accessoryId != null
        ? DuckAccessories.byId(widget.accessoryId!)
        : null;

    final accentColor = isDuck
        ? (duck?.rarity.color ?? AppColors.accent)
        : isAccessory
            ? (accessory?.rarity.color ?? AppColors.accent)
            : (theme?.primaryColor ?? AppColors.accent);

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

                    // ── Subtitle chips ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isDuck
                            ? 'NEW COMPANION'
                            : isAccessory
                                ? 'NEW ACCESSORY'
                                : 'NEW THEME',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

                    const SizedBox(height: 24),

                    // ── Title ────────────────────────────────────────
                    Text(
                      'Unlocked!',
                      style: AppTextStyles.displayLarge.copyWith(fontSize: 38),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                    const SizedBox(height: 32),

                    // ── Reward icon with glow ────────────────────────
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.06);
                        return Transform.scale(
                          scale: scale,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isDuck || isAccessory
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: theme?.gradientColors ??
                                      [
                                        accentColor.withValues(alpha: 0.3),
                                        accentColor
                                      ],
                                ),
                          color: isDuck
                              ? duck!.rarity.color.withValues(alpha: 0.12)
                              : isAccessory
                                  ? accentColor.withValues(alpha: 0.12)
                                  : null,
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: isDuck
                              ? DuckAvatar(duck: duck!, size: 100)
                              : isAccessory
                                  ? Icon(
                                      accessory?.icon ??
                                          Icons.checkroom_rounded,
                                      size: 60,
                                      color: accessory?.color ?? accentColor,
                                    )
                                  : Icon(
                                      theme?.icon ?? Icons.palette_rounded,
                                      size: 60,
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

                    const SizedBox(height: 28),

                    // ── Name ─────────────────────────────────────────
                    Text(
                      isDuck
                          ? (duck?.name ?? '')
                          : isAccessory
                              ? (accessory?.name ?? '')
                              : (theme?.name ?? ''),
                      style: AppTextStyles.headlineSmall.copyWith(fontSize: 26),
                    ).animate().fadeIn(delay: 1000.ms),

                    const SizedBox(height: 8),

                    // ── Rarity / unlock text ─────────────────────────
                    if (isDuck && duck != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: duck.rarity.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          duck.rarity.label,
                          style: TextStyle(
                            color: duck.rarity.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ).animate().fadeIn(delay: 1100.ms),

                    if (isAccessory && accessory != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: accessory.rarity.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${accessory.slot.label} · ${accessory.rarity.label}',
                          style: TextStyle(
                            color: accessory.rarity.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ).animate().fadeIn(delay: 1100.ms),

                    const SizedBox(height: 16),

                    // ── Description ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        isDuck
                            ? (duck?.description ?? '')
                            : isAccessory
                                ? (accessory?.description ?? '')
                                : (theme?.description ?? ''),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(delay: 1200.ms),

                    const Spacer(),

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
                    ).animate().fadeIn(delay: 1400.ms),

                    const SizedBox(height: 12),
                    Text(
                      isDuck
                          ? 'Check it out in your Collection!'
                          : isAccessory
                              ? 'Equip it from the Accessories tab!'
                              : 'Apply it from the Themes tab!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ).animate().fadeIn(delay: 1600.ms),
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

      // Rise slowly upward
      final x = s.x * size.width + sin(rawT * pi * 4 + s.phase) * 20;
      final y = s.y * size.height - rawT * size.height * 0.3;

      // Twinkle: fade in and out
      final twinkle = (sin(rawT * pi * 2 + s.phase) + 1) / 2;
      final opacity = (twinkle * 0.8).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = s.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw a small diamond star shape
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
