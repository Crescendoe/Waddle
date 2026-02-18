import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Tracks which screens have already played their intro animations
/// during the current app session (in-memory only, resets on restart).
class SessionAnimationTracker {
  SessionAnimationTracker._();

  static final Set<String> _played = {};

  /// Returns `true` the first time a screen is visited this session,
  /// and `false` for every subsequent visit.
  /// Call this once when building the screen UI.
  static bool shouldAnimate(String screenKey) {
    if (_played.contains(screenKey)) return false;
    _played.add(screenKey);
    return true;
  }

  /// Screen keys for the 5 main tabs.
  static const home = 'home';
  static const streaks = 'streaks';
  static const challenges = 'challenges';
  static const duckCollection = 'duckCollection';
  static const profile = 'profile';
}

/// Extension that replaces `.animate()` with a once-per-session variant.
/// When [shouldAnimate] is true, the animation plays normally.
/// When false, the widget jumps straight to its final state (no motion).
extension AnimateOnce on Widget {
  Animate animateOnce(bool shouldAnimate) {
    return animate(
      autoPlay: shouldAnimate,
      target: shouldAnimate ? null : 1,
    );
  }
}
