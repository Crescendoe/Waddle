import 'dart:math';
import 'package:flutter/material.dart';

/// Overlay widget that displays up to 3 animated ducks on the home screen.
///
/// Key behaviours:
///   • Ducks never pop in/out — they always walk / fly on-screen first,
///     perform their activity, then walk / fly off-screen.
///   • Slot-0 duck has a high chance of staying in a "cup-area idle"
///     rather than roaming, tying into the cup-float feature.
///   • No background circle — just the emoji.
class HomeDuckOverlay extends StatelessWidget {
  final List<int> duckIndices;

  const HomeDuckOverlay({super.key, required this.duckIndices});

  @override
  Widget build(BuildContext context) {
    if (duckIndices.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: Stack(
        children: [
          for (int i = 0; i < duckIndices.length && i < 3; i++)
            _AnimatedDuck(
              key: ValueKey('home_duck_$i'),
              duckIndex: duckIndices[i],
              slotIndex: i,
              totalDucks: duckIndices.length.clamp(1, 3),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════
// 36 behaviours.  Every traversal enters/exits off-screen edges.
// Idle / rest behaviours keep the duck visible; the lifecycle engine
// walks the duck off-screen before picking a new behaviour.
// ═════════════════════════════════════════════════════════════════════════

enum _B {
  // fly (6)
  flyLR,
  flyRL,
  flyDiagUp,
  flyDiagDown,
  flySwoop,
  flyLoop,
  // swim (6)
  swimLR,
  swimRL,
  swimBob,
  swimZig,
  swimCircle,
  swimDrift,
  // walk (6)
  walkLR,
  walkRL,
  walkStrut,
  walkWander,
  walkBottom,
  walkTop,
  // peek (6)
  peekL,
  peekR,
  peekT,
  peekB,
  peekTL,
  peekBR,
  // idle (6)
  restBL,
  restBR,
  restTL,
  restTR,
  idleBob,
  idleNod,
  // special traversals (6)
  bounce,
  spiral,
  zigFall,
  floatUp,
  danceAcross,
  diveSwoopUp,
}

class _AnimatedDuck extends StatefulWidget {
  final int duckIndex;
  final int slotIndex;
  final int totalDucks;

  const _AnimatedDuck({
    super.key,
    required this.duckIndex,
    required this.slotIndex,
    required this.totalDucks,
  });

  @override
  State<_AnimatedDuck> createState() => _AnimatedDuckState();
}

class _AnimatedDuckState extends State<_AnimatedDuck>
    with TickerProviderStateMixin {
  late AnimationController _c;
  _B _b = _B.walkLR;
  final Random _r = Random();
  static const double _sz = 30.0;
  bool _left = false;
  bool _parked = false; // true while in idle's "rest" repeat

  // ── Lifecycle ─────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _b = _pick(first: true);
    _left = _faceLeft(_b);
    _c = AnimationController(vsync: this, duration: _dur(_b))
      ..addStatusListener(_onEnd);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onEnd(AnimationStatus s) {
    if (s != AnimationStatus.completed || !mounted) return;

    if (_parked) {
      // Walk off-screen before doing anything else
      _parked = false;
      _b = _left ? _B.walkLR : _B.walkRL;
      _left = _faceLeft(_b);
      _c.duration = _dur(_b);
      _c.reset();
      _c.forward();
      return;
    }

    if (_isIdle(_b)) {
      // Just finished one idle cycle → stay parked for another pass
      _parked = true;
      _c.duration = Duration(milliseconds: 2500 + _r.nextInt(3000));
      _c.reset();
      _c.forward();
      return;
    }

    // Traversal finished — pause, then pick next
    Future.delayed(Duration(milliseconds: 600 + _r.nextInt(2000)), () {
      if (!mounted) return;
      setState(() {
        _b = _pick();
        _left = _faceLeft(_b);
        _parked = false;
        _c.duration = _dur(_b);
        _c.reset();
        _c.forward();
      });
    });
  }

  // ── Selection ─────────────────────────────────────────────────────

  static const _idle = [
    _B.restBL,
    _B.restBR,
    _B.restTL,
    _B.restTR,
    _B.idleBob,
    _B.idleNod
  ];
  static const _trav = [
    _B.flyLR,
    _B.flyRL,
    _B.flyDiagUp,
    _B.flyDiagDown,
    _B.flySwoop,
    _B.flyLoop,
    _B.swimLR,
    _B.swimRL,
    _B.swimBob,
    _B.swimZig,
    _B.swimCircle,
    _B.swimDrift,
    _B.walkLR,
    _B.walkRL,
    _B.walkStrut,
    _B.walkWander,
    _B.walkBottom,
    _B.walkTop,
    _B.bounce,
    _B.spiral,
    _B.zigFall,
    _B.floatUp,
    _B.danceAcross,
    _B.diveSwoopUp,
  ];
  static const _peek = [
    _B.peekL,
    _B.peekR,
    _B.peekT,
    _B.peekB,
    _B.peekTL,
    _B.peekBR
  ];

  bool _isIdle(_B b) => _idle.contains(b);

  _B _pick({bool first = false}) {
    // Slot-0 has 45% chance to idle near the cup area
    if (widget.slotIndex == 0 && (_r.nextDouble() < 0.45 || first)) {
      const cupIdles = [_B.restBL, _B.restBR, _B.idleBob, _B.idleNod];
      return cupIdles[_r.nextInt(cupIdles.length)];
    }
    // Weighted pool: traversals 3×, peeks 1×, idles 1×
    final pool = <_B>[..._trav, ..._trav, ..._trav, ..._peek, ..._idle];
    return pool[_r.nextInt(pool.length)];
  }

  bool _faceLeft(_B b) {
    switch (b) {
      case _B.flyRL:
      case _B.swimRL:
      case _B.walkRL:
        return true;
      case _B.flyLR:
      case _B.swimLR:
      case _B.walkLR:
      case _B.walkStrut:
      case _B.walkBottom:
      case _B.walkTop:
      case _B.swimBob:
      case _B.swimZig:
      case _B.swimDrift:
      case _B.danceAcross:
        return false;
      default:
        return _r.nextBool();
    }
  }

  Duration _dur(_B b) {
    switch (b) {
      case _B.flyLR:
      case _B.flyRL:
      case _B.flyDiagUp:
      case _B.flyDiagDown:
        return const Duration(milliseconds: 4000);
      case _B.flySwoop:
      case _B.flyLoop:
        return const Duration(milliseconds: 5000);
      case _B.swimLR:
      case _B.swimRL:
      case _B.swimBob:
      case _B.swimZig:
      case _B.swimCircle:
      case _B.swimDrift:
        return const Duration(milliseconds: 6000);
      case _B.walkLR:
      case _B.walkRL:
      case _B.walkStrut:
      case _B.walkWander:
      case _B.walkBottom:
      case _B.walkTop:
        return const Duration(milliseconds: 6000);
      case _B.peekL:
      case _B.peekR:
      case _B.peekT:
      case _B.peekB:
      case _B.peekTL:
      case _B.peekBR:
        return const Duration(milliseconds: 3500);
      case _B.restBL:
      case _B.restBR:
      case _B.restTL:
      case _B.restTR:
      case _B.idleBob:
      case _B.idleNod:
        return const Duration(milliseconds: 5000);
      case _B.bounce:
      case _B.spiral:
      case _B.zigFall:
      case _B.floatUp:
      case _B.danceAcross:
      case _B.diveSwoopUp:
        return const Duration(milliseconds: 5000);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scr = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final p = _pos(t, scr);
        final r = _rot(t);

        return Positioned(
          left: p.dx,
          top: p.dy,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateZ(r)
              ..scale(_left ? -1.0 : 1.0, 1.0),
            child: child,
          ),
        );
      },
      child: const Text('🦆', style: TextStyle(fontSize: _sz)),
    );
  }

  // ── Position ──────────────────────────────────────────────────────

  Offset _pos(double t, Size s) {
    final w = s.width;
    final h = s.height;
    final sY = widget.slotIndex * 55.0;

    switch (_b) {
      // ── Fly ──
      case _B.flyLR:
        return Offset(
            -_sz + t * (w + _sz * 2), h * 0.15 + sY + sin(t * pi * 3) * 18);
      case _B.flyRL:
        return Offset(
            w + _sz - t * (w + _sz * 2), h * 0.12 + sY + sin(t * pi * 3) * 18);
      case _B.flyDiagUp:
        return Offset(
            -_sz + t * (w + _sz * 2), h * 0.75 - t * h * 0.6 + sY * 0.25);
      case _B.flyDiagDown:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.05 + t * h * 0.55 + sY * 0.25 + sin(t * pi * 4) * 12);
      case _B.flySwoop:
        final e = Curves.easeInOut.transform(t);
        return Offset(-_sz + e * (w + _sz * 2),
            h * 0.08 + sin(e * pi) * h * 0.4 + sY * 0.2);
      case _B.flyLoop:
        final e = Curves.easeInOut.transform(t);
        return Offset(-_sz + e * (w + _sz * 2),
            h * 0.3 + sin(t * pi * 4) * h * 0.12 + sY * 0.2);

      // ── Swim ──
      case _B.swimLR:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.70 + sY * 0.15 + sin(t * pi * 6) * 5);
      case _B.swimRL:
        return Offset(w + _sz - t * (w + _sz * 2),
            h * 0.72 + sY * 0.15 + sin(t * pi * 6) * 5);
      case _B.swimBob:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.68 + sY * 0.15 + sin(t * pi * 10) * 8);
      case _B.swimZig:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.68 + sY * 0.15 + sin(t * pi * 8) * 20);
      case _B.swimCircle:
        return Offset(-_sz + t * (w + _sz * 2) + cos(t * pi * 4) * 20,
            h * 0.70 + sY * 0.15 + sin(t * pi * 4) * 25);
      case _B.swimDrift:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.72 + sY * 0.15 + sin(t * pi * 2) * 8);

      // ── Walk ──
      case _B.walkLR:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.83 + sY * 0.08 + sin(t * pi * 16) * 2.5);
      case _B.walkRL:
        return Offset(w + _sz - t * (w + _sz * 2),
            h * 0.84 + sY * 0.08 + sin(t * pi * 16) * 2.5);
      case _B.walkStrut:
        final bob = (t * 8).floor() % 2 == 0 ? -3.0 : 0.0;
        return Offset(-_sz + t * (w + _sz * 2), h * 0.83 + sY * 0.08 + bob);
      case _B.walkWander:
        return Offset(-_sz + t * (w + _sz * 2) + sin(t * pi * 4) * 15,
            h * 0.82 + sY * 0.08 + cos(t * pi * 6) * 10 + sin(t * pi * 16) * 2);
      case _B.walkBottom:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.88 + sY * 0.05 + sin(t * pi * 16) * 2);
      case _B.walkTop:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.12 + sY * 0.15 + sin(t * pi * 16) * 2);

      // ── Peek ──
      case _B.peekL:
        final p = sin(t * pi);
        return Offset(-_sz + p * (_sz + 18), h * 0.38 + sY);
      case _B.peekR:
        final p = sin(t * pi);
        return Offset(w - p * (_sz + 18), h * 0.42 + sY);
      case _B.peekT:
        final p = sin(t * pi);
        return Offset(w * 0.4 + sY * 0.4, -_sz + p * (_sz + 12));
      case _B.peekB:
        final p = sin(t * pi);
        return Offset(w * 0.5 + sY * 0.3, h - p * (_sz + 12));
      case _B.peekTL:
        final p = sin(t * pi);
        return Offset(-_sz + p * (_sz + 10), -_sz + p * (_sz + 10));
      case _B.peekBR:
        final p = sin(t * pi);
        return Offset(w - p * (_sz + 10), h - p * (_sz + 10));

      // ── Idle / rest ──
      case _B.restBL:
        return Offset(w * 0.12, h * 0.80 + sY * 0.08 + sin(t * pi * 2) * 2);
      case _B.restBR:
        return Offset(w * 0.75, h * 0.80 + sY * 0.08 + sin(t * pi * 2) * 2);
      case _B.restTL:
        return Offset(w * 0.10, h * 0.14 + sY * 0.2 + sin(t * pi * 2) * 2);
      case _B.restTR:
        return Offset(w * 0.78, h * 0.16 + sY * 0.2 + sin(t * pi * 2) * 2);
      case _B.idleBob:
        return Offset(
            w * 0.5 - _sz / 2, h * 0.45 + sY * 0.2 + sin(t * pi * 4) * 10);
      case _B.idleNod:
        return Offset(w * 0.5 - _sz / 2 + sin(t * pi * 6) * 4,
            h * 0.50 + sY * 0.2 + sin(t * pi * 3) * 5);

      // ── Special ──
      case _B.bounce:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.5 + sin(t * pi * 6) * h * 0.18 + sY * 0.15);
      case _B.spiral:
        final r = 30.0 * (1 - t * 0.6);
        return Offset(-_sz + t * (w + _sz * 2) + cos(t * pi * 8) * r,
            h * 0.4 + sin(t * pi * 8) * r * 0.7 + sY * 0.15);
      case _B.zigFall:
        return Offset(w * 0.3 + sin(t * pi * 8) * w * 0.2,
            -_sz + t * (h + _sz * 2) + sY * 0.1);
      case _B.floatUp:
        return Offset(w * 0.5 + sin(t * pi * 4) * 25 - _sz / 2,
            h + _sz - t * (h + _sz * 2) + sY * 0.15);
      case _B.danceAcross:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.55 + sY * 0.15 + sin(t * pi * 8) * 18 + cos(t * pi * 6) * 10);
      case _B.diveSwoopUp:
        return Offset(-_sz + t * (w + _sz * 2),
            h * 0.1 + sin(t * pi) * h * 0.55 + sY * 0.15);
    }
  }

  // ── Rotation ──────────────────────────────────────────────────────

  double _rot(double t) {
    switch (_b) {
      case _B.flyDiagUp:
        return -0.18;
      case _B.flyDiagDown:
        return 0.18;
      case _B.flySwoop:
        return sin(t * pi * 2) * 0.25;
      case _B.flyLoop:
        return sin(t * pi * 4) * 0.3;
      case _B.bounce:
        return sin(t * pi * 6) * 0.15;
      case _B.spiral:
        return t * pi * 2;
      case _B.diveSwoopUp:
        return cos(t * pi) * 0.3;
      case _B.danceAcross:
        return sin(t * pi * 8) * 0.25;
      case _B.walkStrut:
        return sin(t * pi * 16) * 0.06;
      case _B.idleNod:
        return sin(t * pi * 6) * 0.1;
      default:
        return 0.0;
    }
  }
}
