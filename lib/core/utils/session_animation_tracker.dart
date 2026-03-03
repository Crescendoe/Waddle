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

  /// Screen keys for secondary screens.
  static const settings = 'settings';
  static const notifications = 'notifications';
  static const healthSync = 'healthSync';
  static const duckDetail = 'duckDetail';
  static const friends = 'friends';
  static const friendProfile = 'friendProfile';
}

/// Extension that replaces `.animate()` with a once-per-session variant.
/// When [shouldAnimate] is true, the animation plays normally.
/// When false, the widget snaps to its final state instantly (no motion).
extension AnimateOnce on Widget {
  Animate animateOnce(bool shouldAnimate) {
    if (shouldAnimate) return animate();
    // Snap the controller to the end so all chained effects
    // (fadeIn, slideY, etc.) render at their final values immediately.
    return animate(
      autoPlay: false,
      onInit: (controller) => controller.value = 1.0,
    );
  }
}
