import 'package:flutter/foundation.dart';

/// Hidden debug mode that overrides all unlock conditions.
///
/// Activated via a secret gesture (5-tap on version text in Settings).
/// Does NOT persist — resets when the app restarts.
class DebugModeService extends ChangeNotifier {
  bool _active = false;

  bool get isActive => _active;

  void toggle() {
    _active = !_active;
    notifyListeners();
  }

  void activate() {
    if (!_active) {
      _active = true;
      notifyListeners();
    }
  }

  void deactivate() {
    if (_active) {
      _active = false;
      notifyListeners();
    }
  }
}
