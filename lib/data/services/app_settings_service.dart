import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight service that persists general app settings to SharedPreferences.
class AppSettingsService {
  final SharedPreferences _prefs;

  AppSettingsService({required SharedPreferences prefs}) : _prefs = prefs;

  // ── Keys ──────────────────────────────────────────────────────
  static const _kUnits = 'settings_units'; // 'oz' or 'ml'
  static const _kDefaultCupOz = 'settings_default_cup_oz';
  static const _kDailyResetHour = 'settings_daily_reset_hour';

  // ── Units ─────────────────────────────────────────────────────

  /// Returns 'oz' or 'ml'.
  String get units => _prefs.getString(_kUnits) ?? 'oz';
  bool get useMetric => units == 'ml';

  Future<void> setUnits(String value) async {
    await _prefs.setString(_kUnits, value);
  }

  /// Convert an internal oz value to the user-facing display value.
  double displayAmount(double oz) => useMetric ? oz * 29.5735 : oz;

  /// Format amount with unit label.
  String formatAmount(double oz, {int decimals = 1}) {
    final value = displayAmount(oz);
    final label = useMetric ? 'mL' : 'oz';
    return '${value.toStringAsFixed(decimals)} $label';
  }

  /// Unit label string.
  String get unitLabel => useMetric ? 'mL' : 'oz';

  // ── Default cup size ──────────────────────────────────────────

  /// Default cup size in oz (internal unit). Defaults to 8 oz.
  double get defaultCupOz => _prefs.getDouble(_kDefaultCupOz) ?? 8.0;

  Future<void> setDefaultCupOz(double oz) async {
    await _prefs.setDouble(_kDefaultCupOz, oz);
  }

  // ── Daily reset hour ──────────────────────────────────────────

  /// Hour of day (0-23) when the daily reset occurs. Default midnight (0).
  int get dailyResetHour => _prefs.getInt(_kDailyResetHour) ?? 0;

  Future<void> setDailyResetHour(int hour) async {
    await _prefs.setInt(_kDailyResetHour, hour);
  }
}
