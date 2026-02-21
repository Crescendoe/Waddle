import 'dart:math';
import 'package:flutter/material.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';

/// Floating silhouettes / particles overlay for enhanced theme backgrounds.
///
/// Each [ThemeEffect] produces a different set of animated objects that drift
/// lazily across the screen — bubbles, leaves, snowflakes, stars, etc.
class FloatingObjectsOverlay extends StatefulWidget {
  final ThemeEffect effect;
  final List<Color> gradientColors;

  const FloatingObjectsOverlay({
    super.key,
    required this.effect,
    required this.gradientColors,
  });

  @override
  State<FloatingObjectsOverlay> createState() => _FloatingObjectsOverlayState();
}

class _FloatingObjectsOverlayState extends State<FloatingObjectsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingObject> _objects;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _objects = _generateObjects();
  }

  @override
  void didUpdateWidget(FloatingObjectsOverlay old) {
    super.didUpdateWidget(old);
    if (old.effect != widget.effect) {
      _objects = _generateObjects();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_FloatingObject> _generateObjects() {
    final count = _objectCount(widget.effect);
    return List.generate(
        count,
        (_) => _FloatingObject(
              x: _random.nextDouble(),
              y: _random.nextDouble(),
              size: 8 + _random.nextDouble() * 16,
              speed: 0.02 + _random.nextDouble() * 0.04,
              drift: (_random.nextDouble() - 0.5) * 0.015,
              phase: _random.nextDouble() * pi * 2,
              rotation: _random.nextDouble() * pi * 2,
              rotationSpeed: (_random.nextDouble() - 0.5) * 0.02,
            ));
  }

  int _objectCount(ThemeEffect effect) {
    switch (effect) {
      case ThemeEffect.none:
        return 0;
      case ThemeEffect.bubbles:
        return 18;
      case ThemeEffect.leaves:
        return 12;
      case ThemeEffect.snowflakes:
        return 20;
      case ThemeEffect.stars:
        return 25;
      case ThemeEffect.fireflies:
        return 15;
      case ThemeEffect.petals:
        return 14;
      case ThemeEffect.waves:
        return 10;
      case ThemeEffect.sparkles:
        return 22;
      case ThemeEffect.raindrops:
        return 18;
      case ThemeEffect.dust:
        return 14;
      case ThemeEffect.sunbeams:
        return 8;
      case ThemeEffect.blossoms:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.effect == ThemeEffect.none) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _FloatingObjectsPainter(
            objects: _objects,
            effect: widget.effect,
            progress: _controller.value,
            baseColor: widget.gradientColors.isNotEmpty
                ? widget.gradientColors.first
                : Colors.blue,
          ),
        );
      },
    );
  }
}

class _FloatingObject {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double drift;
  final double phase;
  double rotation;
  final double rotationSpeed;

  _FloatingObject({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class _FloatingObjectsPainter extends CustomPainter {
  final List<_FloatingObject> objects;
  final ThemeEffect effect;
  final double progress;
  final Color baseColor;

  _FloatingObjectsPainter({
    required this.objects,
    required this.effect,
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in objects) {
      final t = (progress + obj.phase / (pi * 2)) % 1.0;

      // Y position: drifts upward over time, wraps around
      final yPos = ((obj.y - t * obj.speed * 20) % 1.0) * size.height;
      // X position: gentle horizontal sway
      final xPos =
          (obj.x + sin(t * pi * 2 + obj.phase) * obj.drift * 10) * size.width;

      // Fade based on vertical position (fade at edges)
      final vertFade = sin((yPos / size.height) * pi);
      final alpha = (vertFade * 0.3).clamp(0.0, 0.3);

      canvas.save();
      canvas.translate(xPos, yPos);
      canvas.rotate(obj.rotation + progress * obj.rotationSpeed * pi * 2);

      switch (effect) {
        case ThemeEffect.bubbles:
          _drawBubble(canvas, obj.size, alpha);
          break;
        case ThemeEffect.leaves:
          _drawLeaf(canvas, obj.size, alpha);
          break;
        case ThemeEffect.snowflakes:
          _drawSnowflake(canvas, obj.size, alpha);
          break;
        case ThemeEffect.stars:
          _drawStar(canvas, obj.size, alpha);
          break;
        case ThemeEffect.fireflies:
          _drawFirefly(canvas, obj.size, alpha, t + obj.phase);
          break;
        case ThemeEffect.petals:
          _drawPetal(canvas, obj.size, alpha);
          break;
        case ThemeEffect.waves:
          _drawWaveDot(canvas, obj.size, alpha);
          break;
        case ThemeEffect.sparkles:
          _drawSparkle(canvas, obj.size, alpha, t + obj.phase);
          break;
        case ThemeEffect.raindrops:
          _drawRaindrop(canvas, obj.size, alpha);
          break;
        case ThemeEffect.dust:
          _drawDust(canvas, obj.size, alpha, t + obj.phase);
          break;
        case ThemeEffect.sunbeams:
          _drawSunbeam(canvas, obj.size, alpha, t + obj.phase);
          break;
        case ThemeEffect.blossoms:
          _drawBlossom(canvas, obj.size, alpha);
          break;
        case ThemeEffect.none:
          break;
      }

      canvas.restore();
    }
  }

  void _drawBubble(Canvas canvas, double size, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, size / 2, paint);

    // Highlight
    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(-size * 0.15, -size * 0.15),
      size * 0.15,
      hlPaint,
    );
  }

  void _drawLeaf(Canvas canvas, double size, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, -size / 2)
      ..quadraticBezierTo(size / 2, 0, 0, size / 2)
      ..quadraticBezierTo(-size / 2, 0, 0, -size / 2);
    canvas.drawPath(path, paint);
  }

  void _drawSnowflake(Canvas canvas, double size, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 1.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, size * 0.3, paint);

    // Cross arms
    final armPaint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      canvas.drawLine(
        Offset.zero,
        Offset(cos(angle) * size * 0.45, sin(angle) * size * 0.45),
        armPaint,
      );
    }
  }

  void _drawStar(Canvas canvas, double size, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 1.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    final r = size * 0.4;
    final ir = r * 0.4;
    for (int i = 0; i < 5; i++) {
      final outerAngle = -pi / 2 + i * 2 * pi / 5;
      final innerAngle = outerAngle + pi / 5;
      if (i == 0) {
        path.moveTo(cos(outerAngle) * r, sin(outerAngle) * r);
      } else {
        path.lineTo(cos(outerAngle) * r, sin(outerAngle) * r);
      }
      path.lineTo(cos(innerAngle) * ir, sin(innerAngle) * ir);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFirefly(Canvas canvas, double size, double alpha, double t) {
    final glow = (sin(t * pi * 4) * 0.5 + 0.5);
    final paint = Paint()
      ..color = const Color(0xFFFFEB3B)
          .withValues(alpha: (alpha * glow * 2).clamp(0.0, 0.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset.zero, size * 0.3, paint);

    // Core
    final core = Paint()
      ..color = const Color(0xFFFFF176)
          .withValues(alpha: (alpha * glow * 3).clamp(0.0, 0.7));
    canvas.drawCircle(Offset.zero, size * 0.12, core);
  }

  void _drawPetal(Canvas canvas, double size, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFFF8BBD0).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, -size * 0.4)
      ..quadraticBezierTo(size * 0.3, -size * 0.1, 0, size * 0.4)
      ..quadraticBezierTo(-size * 0.3, -size * 0.1, 0, -size * 0.4);
    canvas.drawPath(path, paint);
  }

  void _drawWaveDot(Canvas canvas, double size, double alpha) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero, width: size * 0.8, height: size * 0.3),
      paint,
    );
  }

  void _drawSparkle(Canvas canvas, double size, double alpha, double t) {
    final pulse = (sin(t * pi * 3) * 0.5 + 0.5);
    final paint = Paint()
      ..color =
          Colors.white.withValues(alpha: (alpha * pulse * 2).clamp(0.0, 0.5))
      ..style = PaintingStyle.fill;

    // 4-point sparkle
    final r = size * 0.35 * (0.7 + pulse * 0.3);
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * pi / 2;
      final nextAngle = angle + pi / 4;
      path.moveTo(0, 0);
      path.lineTo(cos(angle) * r, sin(angle) * r);
      path.lineTo(cos(nextAngle) * r * 0.3, sin(nextAngle) * r * 0.3);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRaindrop(Canvas canvas, double size, double alpha) {
    // Elongated teardrop shape
    final paint = Paint()
      ..color = const Color(0xFF81D4FA)
          .withValues(alpha: (alpha * 1.2).clamp(0.0, 0.35))
      ..style = PaintingStyle.fill;
    final r = size * 0.2;
    final path = Path()
      ..moveTo(0, -r * 2.5)
      ..quadraticBezierTo(r * 1.2, -r * 0.5, 0, r)
      ..quadraticBezierTo(-r * 1.2, -r * 0.5, 0, -r * 2.5);
    canvas.drawPath(path, paint);

    // Subtle highlight
    final hl = Paint()..color = Colors.white.withValues(alpha: alpha * 0.4);
    canvas.drawCircle(Offset(-r * 0.2, -r * 0.3), r * 0.25, hl);
  }

  void _drawDust(Canvas canvas, double size, double alpha, double t) {
    // Warm drifting dust mote with gentle pulse
    final pulse = (sin(t * pi * 2) * 0.3 + 0.7);
    final paint = Paint()
      ..color = const Color(0xFFD7CCC8)
          .withValues(alpha: (alpha * pulse * 1.5).clamp(0.0, 0.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset.zero, size * 0.22 * pulse, paint);

    // Bright core
    final core = Paint()
      ..color = const Color(0xFFFFE0B2)
          .withValues(alpha: (alpha * pulse * 2).clamp(0.0, 0.25));
    canvas.drawCircle(Offset.zero, size * 0.08, core);
  }

  void _drawSunbeam(Canvas canvas, double size, double alpha, double t) {
    // Long diagonal ray of light
    final pulse = (sin(t * pi * 1.5) * 0.5 + 0.5);
    final length = size * 2.5;
    final width = size * 0.3 * (0.6 + pulse * 0.4);
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
          .withValues(alpha: (alpha * pulse * 1.5).clamp(0.0, 0.2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final path = Path()
      ..moveTo(-width / 2, -length / 2)
      ..lineTo(width / 2, -length / 2)
      ..lineTo(width * 0.2, length / 2)
      ..lineTo(-width * 0.2, length / 2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawBlossom(Canvas canvas, double size, double alpha) {
    // 5-petal flower
    final petalSize = size * 0.28;
    final paint = Paint()
      ..color = const Color(0xFFF8BBD0)
          .withValues(alpha: (alpha * 1.2).clamp(0.0, 0.35))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * pi / 5 - pi / 2;
      final cx = cos(angle) * petalSize;
      final cy = sin(angle) * petalSize;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: petalSize * 1.2,
          height: petalSize * 0.7,
        ),
        paint,
      );
    }

    // Centre dot
    final centre = Paint()
      ..color = const Color(0xFFFFF176)
          .withValues(alpha: (alpha * 1.5).clamp(0.0, 0.4));
    canvas.drawCircle(Offset.zero, petalSize * 0.35, centre);
  }

  @override
  bool shouldRepaint(covariant _FloatingObjectsPainter old) =>
      old.progress != progress || old.effect != effect;
}
