import 'dart:math';
import 'package:flutter/material.dart';
import 'package:waddle/core/theme/app_theme.dart';

/// Animated wave painter for the water cup fill effect
class WavePainter extends CustomPainter {
  final double fillPercent;
  final double wavePhase;
  final Color color;
  final double waveAmplitude;

  WavePainter({
    required this.fillPercent,
    required this.wavePhase,
    this.color = const Color(0xFF4FC3F7),
    this.waveAmplitude = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillPercent <= 0) return;

    final fillHeight = size.height * fillPercent.clamp(0.0, 1.0);
    final baseY = size.height - fillHeight;

    final path = Path();
    path.moveTo(0, size.height);

    // Draw wave — edge fade ensures amplitude→0 at cup walls
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final edgeFade = sin(t * pi); // 0 at edges, 1 in center

      final wave1 = sin(t * 2 * pi + wavePhase) * waveAmplitude;
      final wave2 = cos(t * 3 * pi + wavePhase) * (waveAmplitude * 0.4);

      final y = baseY + (wave1 + wave2) * edgeFade;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    // Gradient fill
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.7),
          color.withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromLTWH(0, baseY, size.width, fillHeight));

    canvas.drawPath(path, paint);

    // Add subtle highlight wave
    final highlightPath = Path();
    highlightPath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final edgeFade = sin(t * pi);
      final y = baseY +
          sin(t * 2 * pi + wavePhase + 1.0) * (waveAmplitude * 0.5) * edgeFade +
          3;
      highlightPath.lineTo(x, y);
    }
    highlightPath.lineTo(size.width, size.height);
    highlightPath.close();

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.fillPercent != fillPercent ||
        oldDelegate.wavePhase != wavePhase;
  }
}

/// Cup-shaped clipper for the water container
class CupClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Match the cup image outline — slightly tapered, gentle bottom curve
    final topInset = size.width * 0.13;
    final bottomInset = size.width * 0.20;
    final bottomY = size.height * 0.96;

    path.moveTo(topInset, 0);
    path.lineTo(size.width - topInset, 0);
    path.lineTo(size.width - bottomInset, bottomY);

    // Gentle bottom curve — minimal rounding to match the cup image
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 1.0,
      bottomInset,
      bottomY,
    );
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Animated water cup widget with wave fill
class AnimatedWaterCup extends StatefulWidget {
  final double? fillPercent;
  final double? waterOz;
  final double? currentOz;
  final double goalOz;
  final double size;
  final bool showCups;
  final VoidCallback? onTapToggle;

  const AnimatedWaterCup({
    super.key,
    this.fillPercent,
    this.waterOz,
    this.currentOz,
    required this.goalOz,
    this.size = 220,
    this.showCups = false,
    this.onTapToggle,
  });

  double get effectiveFillPercent {
    if (fillPercent != null) return fillPercent!;
    final oz = currentOz ?? waterOz ?? 0;
    return goalOz > 0 ? (oz / goalOz).clamp(0.0, 1.0) : 0.0;
  }

  double get effectiveWaterOz => currentOz ?? waterOz ?? 0;

  @override
  State<AnimatedWaterCup> createState() => _AnimatedWaterCupState();
}

class _AnimatedWaterCupState extends State<AnimatedWaterCup>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTapToggle,
      child: SizedBox(
        width: widget.size,
        height: widget.size * 1.36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Water fill
            ClipPath(
              clipper: CupClipper(),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size * 1.36),
                    painter: WavePainter(
                      fillPercent: widget.effectiveFillPercent,
                      wavePhase: _waveController.value * 2 * pi,
                      color: AppColors.water,
                      waveAmplitude: 4.0,
                    ),
                  );
                },
              ),
            ),

            // Cup overlay image
            Opacity(
              opacity: 0.95,
              child: Image.asset(
                'lib/assets/images/cup.png',
                width: widget.size,
                height: widget.size * 1.36,
                fit: BoxFit.contain,
              ),
            ),

            // Water amount text
            Positioned(
              top: widget.size * 0.55,
              child: Column(
                children: [
                  Text(
                    widget.showCups
                        ? (widget.effectiveWaterOz / 8).toStringAsFixed(1)
                        : widget.effectiveWaterOz.toStringAsFixed(0),
                    style: AppTextStyles.waterAmount.copyWith(
                      color: widget.showCups
                          ? AppColors.success
                          : AppColors.primary,
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.showCups ? 'cups' : 'oz',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: widget.showCups
                          ? AppColors.success
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
