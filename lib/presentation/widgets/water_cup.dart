import 'dart:math';
import 'package:flutter/material.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/drink_type.dart';
import 'package:waddle/domain/entities/water_log.dart';
import 'package:waddle/presentation/widgets/duck_avatar.dart';

/// A segment of the cup fill representing one drink type
class DrinkSegment {
  final String drinkName;
  final double amountOz;
  final Color color;
  final IconData icon;

  const DrinkSegment({
    required this.drinkName,
    required this.amountOz,
    required this.color,
    required this.icon,
  });
}

/// Build aggregated segments from today's logs (in chronological order).
/// Consecutive logs of the same drink are merged.
List<DrinkSegment> buildDrinkSegments(List<WaterLog> todayLogs) {
  if (todayLogs.isEmpty) return [];

  // Sort chronological (earliest first)
  final sorted = List<WaterLog>.from(todayLogs)
    ..sort((a, b) => a.entryTime.compareTo(b.entryTime));

  final segments = <DrinkSegment>[];
  for (final log in sorted) {
    final drink = DrinkTypes.byName(log.drinkName);
    final color = drink?.color ?? AppColors.water;
    final icon = drink?.icon ?? Icons.water_drop_rounded;

    if (segments.isNotEmpty && segments.last.drinkName == log.drinkName) {
      // Merge with previous
      final last = segments.removeLast();
      segments.add(DrinkSegment(
        drinkName: last.drinkName,
        amountOz: last.amountOz + log.amountOz,
        color: last.color,
        icon: last.icon,
      ));
    } else {
      segments.add(DrinkSegment(
        drinkName: log.drinkName,
        amountOz: log.amountOz,
        color: color,
        icon: icon,
      ));
    }
  }
  return segments;
}

/// Animated wave painter for the water cup fill effect — single color
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

    // Cap at 93% so the wave ripple is always visible at the top
    final fillHeight = size.height * fillPercent.clamp(0.0, 0.93);
    final baseY = size.height - fillHeight;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final t = x / size.width;
      final edgeFade = sin(t * pi);

      final wave1 = sin(t * 2 * pi + wavePhase) * waveAmplitude;
      final wave2 = cos(t * 3 * pi + wavePhase) * (waveAmplitude * 0.4);

      final y = baseY + (wave1 + wave2) * edgeFade;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

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

/// Segmented wave painter — draws multiple colored bands from bottom to top,
/// with the topmost segment getting the animated wave surface.
class SegmentedWavePainter extends CustomPainter {
  final List<DrinkSegment> segments;
  final double totalFillPercent; // 0..1 how full the cup is
  final double goalOz;
  final double wavePhase;
  final double waveAmplitude;

  SegmentedWavePainter({
    required this.segments,
    required this.totalFillPercent,
    required this.goalOz,
    required this.wavePhase,
    this.waveAmplitude = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || totalFillPercent <= 0) return;

    final totalOz = segments.fold<double>(0, (s, seg) => s + seg.amountOz);
    if (totalOz <= 0) return;

    // Cap at 93% so the wave ripple is always visible at the top
    final totalFillHeight = size.height * totalFillPercent.clamp(0.0, 0.93);

    // Draw each segment from bottom up
    double drawnHeight = 0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final segFraction = seg.amountOz / goalOz;
      final segHeight =
          (segFraction * size.height).clamp(0.0, totalFillHeight - drawnHeight);

      if (segHeight <= 0) continue;

      final isTop = (i == segments.length - 1);
      final segBottom = size.height - drawnHeight;
      final segTop = segBottom - segHeight;

      final path = Path();

      if (isTop) {
        // Top segment gets the wave
        path.moveTo(0, segBottom);
        for (double x = 0; x <= size.width; x++) {
          final t = x / size.width;
          final edgeFade = sin(t * pi);
          final wave1 = sin(t * 2 * pi + wavePhase) * waveAmplitude;
          final wave2 = cos(t * 3 * pi + wavePhase) * (waveAmplitude * 0.4);
          final y = segTop + (wave1 + wave2) * edgeFade;
          path.lineTo(x, y);
        }
        path.lineTo(size.width, segBottom);
        path.close();
      } else {
        // Lower segments are flat rectangles
        path.addRect(Rect.fromLTRB(0, segTop, size.width, segBottom));
      }

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            seg.color.withValues(alpha: 0.45),
            seg.color.withValues(alpha: 0.7),
            seg.color.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromLTRB(0, segTop, size.width, segBottom));

      canvas.drawPath(path, paint);

      // Subtle highlight on top segment
      if (isTop) {
        final hPath = Path();
        hPath.moveTo(0, segBottom);
        for (double x = 0; x <= size.width; x++) {
          final t = x / size.width;
          final edgeFade = sin(t * pi);
          final y = segTop +
              sin(t * 2 * pi + wavePhase + 1.0) *
                  (waveAmplitude * 0.5) *
                  edgeFade +
              3;
          hPath.lineTo(x, y);
        }
        hPath.lineTo(size.width, segBottom);
        hPath.close();
        canvas.drawPath(
            hPath, Paint()..color = Colors.white.withValues(alpha: 0.12));
      }

      // Draw thin separator line between segments
      if (i > 0) {
        canvas.drawLine(
          Offset(0, segBottom),
          Offset(size.width, segBottom),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..strokeWidth = 0.8,
        );
      }

      drawnHeight += segHeight;
    }
  }

  @override
  bool shouldRepaint(covariant SegmentedWavePainter old) {
    return old.totalFillPercent != totalFillPercent ||
        old.wavePhase != wavePhase ||
        old.segments.length != segments.length;
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

/// Animated water cup widget with segmented drink-color fill
class AnimatedWaterCup extends StatefulWidget {
  final double? fillPercent;
  final double? waterOz;
  final double? currentOz;
  final double goalOz;
  final double size;
  final bool showDetails;
  final VoidCallback? onTapToggle;
  final List<WaterLog> todayLogs;
  final int cupDuckCount;
  final List<int> cupDuckIndices;

  const AnimatedWaterCup({
    super.key,
    this.fillPercent,
    this.waterOz,
    this.currentOz,
    required this.goalOz,
    this.size = 220,
    this.showDetails = false,
    this.onTapToggle,
    this.todayLogs = const [],
    this.cupDuckCount = 0,
    this.cupDuckIndices = const [],
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
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _detailsController;
  late Animation<double> _detailsFade;
  late Animation<double> _detailsSlide;
  late Animation<double> _defaultFade;
  final Stopwatch _duckStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _duckStopwatch.start();

    _detailsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _detailsFade = CurvedAnimation(
      parent: _detailsController,
      curve: Curves.easeOut,
    );
    _detailsSlide = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _detailsController, curve: Curves.easeOutCubic),
    );
    _defaultFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _detailsController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    if (widget.showDetails) _detailsController.value = 1.0;
  }

  @override
  void didUpdateWidget(AnimatedWaterCup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showDetails != oldWidget.showDetails) {
      if (widget.showDetails) {
        _detailsController.forward();
      } else {
        _detailsController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  List<DrinkSegment> get _segments => buildDrinkSegments(widget.todayLogs);

  @override
  Widget build(BuildContext context) {
    final cupHeight = widget.size * 1.36;
    final segments = _segments;
    final hasSegments = segments.isNotEmpty;

    return GestureDetector(
      onTap: widget.onTapToggle,
      child: SizedBox(
        width: widget.size,
        height: cupHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Water fill — segmented or single-color
            ClipPath(
              clipper: CupClipper(),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  if (hasSegments) {
                    return CustomPaint(
                      size: Size(widget.size, cupHeight),
                      painter: SegmentedWavePainter(
                        segments: segments,
                        totalFillPercent: widget.effectiveFillPercent,
                        goalOz: widget.goalOz,
                        wavePhase: _waveController.value * 2 * pi,
                        waveAmplitude: 4.0,
                      ),
                    );
                  }
                  return CustomPaint(
                    size: Size(widget.size, cupHeight),
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

            // Floating ducks on water surface — rendered UNDER the cup image
            // Up to 3 ducks, each with a different horizontal position & phase
            for (int duckI = 0;
                duckI < widget.cupDuckCount.clamp(0, 3);
                duckI++)
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  final elapsedSec =
                      _duckStopwatch.elapsedMilliseconds / 1000.0;
                  final baseFreq = 2 * pi / 4.0;
                  // Offset each duck's phase so they don't bob in sync
                  final phaseOffset = duckI * 2.1;
                  final phase = elapsedSec * baseFreq + phaseOffset;

                  final fillH =
                      cupHeight * widget.effectiveFillPercent.clamp(0.0, 0.93);
                  final waterSurfaceY = cupHeight - fillH;
                  final bobOffset = sin(phase) * 3.0;
                  final tilt = sin(phase * 0.7 + 0.5) * 0.12;
                  final driftX = sin(phase * 0.3) * 5.0;
                  final duckSize = widget.size * 0.13;

                  // Spread ducks horizontally:
                  // 1 duck  → centre-right
                  // 2 ducks → left-of-centre, right-of-centre
                  // 3 ducks → left, centre, right
                  final double hBias;
                  final count = widget.cupDuckCount.clamp(1, 3);
                  if (count == 1) {
                    hBias = widget.size * 0.18;
                  } else if (count == 2) {
                    hBias =
                        duckI == 0 ? -widget.size * 0.12 : widget.size * 0.18;
                  } else {
                    // 3 ducks: -0.16, 0.04, 0.22
                    hBias = widget.size * (-0.16 + duckI * 0.19);
                  }

                  return Positioned(
                    top: waterSurfaceY + bobOffset - duckSize * 0.55,
                    left: (widget.size / 2) - (duckSize / 2) + driftX + hBias,
                    child: Transform.rotate(
                      angle: tilt,
                      child: duckI < widget.cupDuckIndices.length
                          ? DuckAvatar.fromIndex(
                              index: widget.cupDuckIndices[duckI],
                              size: duckSize,
                            )
                          : Image.asset(
                              'lib/assets/images/wade_floating.png',
                              width: duckSize,
                              height: duckSize,
                              fit: BoxFit.contain,
                            ),
                    ),
                  );
                },
              ),

            // Cup overlay image — on top of both water and duck
            Opacity(
              opacity: 0.95,
              child: Image.asset(
                'lib/assets/images/cup.png',
                width: widget.size,
                height: cupHeight,
                fit: BoxFit.contain,
              ),
            ),

            // Default label (fades out when details shown)
            // Positioned must be a direct child of Stack, so keep it outside
            // any RenderObjectWidget wrappers (Opacity, Transform, etc.)
            Positioned.fill(
              child: hasSegments
                  ? AnimatedBuilder(
                      animation: _defaultFade,
                      builder: (context, child) => Opacity(
                        opacity: _defaultFade.value,
                        child: child,
                      ),
                      child: _buildDefaultLabelContent(),
                    )
                  : _buildDefaultLabelContent(),
            ),

            // Segment labels (fades + scales in)
            if (hasSegments)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _detailsController,
                  builder: (context, _) {
                    if (_detailsFade.value <= 0.01) {
                      return const SizedBox.shrink();
                    }
                    return Opacity(
                      opacity: _detailsFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _detailsSlide.value),
                        child: _buildSegmentLabelsInner(segments, cupHeight),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Default centre label content — total oz at the visual centre of the cup.
  /// Text colour adapts to whatever drink segment is behind it.
  /// Returns content only (no Positioned) — the caller wraps in Positioned.
  Widget _buildDefaultLabelContent() {
    final cupHeight = widget.size * 1.36;
    final segments = _segments;
    final labelColor = _adaptiveLabelColor(segments, cupHeight);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.effectiveWaterOz.toStringAsFixed(0),
            style: AppTextStyles.waterAmount.copyWith(
              color: labelColor,
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.6), blurRadius: 4),
                Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 1,
                    offset: const Offset(0.5, 0.5)),
                Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 1,
                    offset: const Offset(-0.5, -0.5)),
              ],
            ),
          ),
          Text(
            'oz',
            style: AppTextStyles.labelLarge.copyWith(
              fontSize: 18,
              color: labelColor,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                    color: Colors.black.withValues(alpha: 0.6), blurRadius: 4),
                Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 1,
                    offset: const Offset(0.5, 0.5)),
                Shadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 1,
                    offset: const Offset(-0.5, -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pick white or dark text depending on what's behind the cup centre.
  Color _adaptiveLabelColor(List<DrinkSegment> segments, double cupHeight) {
    final fillH = cupHeight * widget.effectiveFillPercent.clamp(0.0, 0.93);
    final cupCenterFromBottom = cupHeight / 2;

    // If the liquid doesn't reach the centre, text is over the empty cup
    if (cupCenterFromBottom > fillH) return AppColors.primary;

    // Walk segments from bottom up to find which one covers the centre
    double y = 0;
    for (final seg in segments) {
      final segH = (seg.amountOz / widget.goalOz) * cupHeight;
      if (y + segH >= cupCenterFromBottom) {
        // This segment is behind the label
        return seg.color.computeLuminance() < 0.45
            ? Colors.white.withValues(alpha: 0.85)
            : const Color(0xFF1A1A2E);
      }
      y += segH;
    }

    return AppColors.primary;
  }

  /// Segment labels content without outer Positioned — caller wraps it.
  Widget _buildSegmentLabelsInner(
      List<DrinkSegment> segments, double cupHeight) {
    final totalFillHeight =
        cupHeight * widget.effectiveFillPercent.clamp(0.0, 0.93);
    if (totalFillHeight <= 0) return const SizedBox.shrink();

    final segHeights = <double>[];
    double remaining = totalFillHeight;
    for (final seg in segments) {
      final h =
          ((seg.amountOz / widget.goalOz) * cupHeight).clamp(0.0, remaining);
      segHeights.add(h);
      remaining -= h;
    }

    final labels = <Widget>[];
    double yFromBottom = 0;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final segH = segHeights[i];
      if (segH < 1) continue;

      final segTop = cupHeight - yFromBottom - segH;

      if (segH >= 14) {
        labels.add(
          Positioned(
            top: segTop,
            left: 0,
            right: 0,
            height: segH,
            child: Center(
              child: _SegmentLabel(
                drinkName: seg.drinkName,
                amountOz: seg.amountOz,
                icon: seg.icon,
                color: seg.color,
                segmentHeight: segH,
              ),
            ),
          ),
        );
      }

      yFromBottom += segH;
    }

    // Return just the Stack (no outer Positioned) — caller provides Positioned
    return Stack(children: labels);
  }
}

/// A single segment label — consistent stacked layout, scaled to fit
class _SegmentLabel extends StatelessWidget {
  final String drinkName;
  final double amountOz;
  final IconData icon;
  final Color color;
  final double segmentHeight;

  const _SegmentLabel({
    required this.drinkName,
    required this.amountOz,
    required this.icon,
    required this.color,
    required this.segmentHeight,
  });

  @override
  Widget build(BuildContext context) {
    Widget _iconCircle(double size) {
      final pad = size * 0.3;
      return Container(
        width: size + pad * 2,
        height: size + pad * 2,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size, color: Colors.white, shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 2)
        ]),
      );
    }

    TextStyle _textStyle(double fontSize, FontWeight weight) => TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: weight,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 3),
          ],
        );

    // Large segments (≥ 80px): stacked vertically — icon / name / oz
    if (segmentHeight >= 80) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconCircle(16),
          const SizedBox(height: 3),
          Text(drinkName, style: _textStyle(10, FontWeight.w600)),
          Text('${amountOz.toStringAsFixed(0)} oz',
              style: _textStyle(14, FontWeight.bold)),
        ],
      );
    }

    // Medium & small segments (< 80px): icon left, name+oz stacked right
    // Text scales with segment height but stays bigger than stacked version
    final hScale = (segmentHeight / 70).clamp(0.5, 1.0);
    final hIconSize = (14.0 * hScale).clamp(8.0, 14.0);
    final hNameSize = (10.0 * hScale).clamp(7.5, 10.0);
    final hOzSize = (14.0 * hScale).clamp(10.0, 14.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconCircle(hIconSize),
        SizedBox(width: 4 * hScale + 2),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(drinkName, style: _textStyle(hNameSize, FontWeight.w600)),
            Text('${amountOz.toStringAsFixed(0)} oz',
                style: _textStyle(hOzSize, FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
