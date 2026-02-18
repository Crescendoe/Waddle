/// Water intake calculator based on personal metrics.
///
/// Grounded in:
/// - National Academies of Sciences (IOM) Adequate Intake:
///   Men ~15.5 cups (124 oz) total fluid/day, Women ~11.5 cups (92 oz).
///   About 80% comes from beverages → Men ~100 oz, Women ~74 oz drinking.
/// - The popular "half your body weight in oz" heuristic (≈ weight × 0.5).
/// - Mayo Clinic guidance on exercise, heat, and health condition adjustments.
///
/// Approach: sex-specific base multiplier on body weight, then activity & weather
/// modifiers. Age/height removed (not evidence-based for healthy adults; already
/// captured by weight). Result clamped to 48–160 oz safety range.
class WaterGoalCalculator {
  WaterGoalCalculator._();

  /// Minimum recommended daily water intake (oz)
  static const double _minGoalOz = 48.0;

  /// Maximum recommended daily water intake (oz)
  static const double _maxGoalOz = 160.0;

  /// Calculate personalized daily water goal in ounces
  static double calculate({
    required double weightLbs,
    required int ageYears,
    required int heightInches,
    required Sex sex,
    required ActivityLevel activity,
    required WeatherCondition weather,
  }) {
    // Base calculation: sex-specific multiplier on body weight.
    // Male 0.55 → 180 lb male ≈ 99 oz (matches IOM ~100 oz)
    // Female 0.50 → 150 lb female ≈ 75 oz (matches IOM ~74 oz)
    double waterIntake = weightLbs * sex.baseMultiplier;

    // Activity level modifier
    waterIntake *= activity.multiplier;

    // Weather/climate modifier
    waterIntake *= weather.multiplier;

    // Clamp to safe range
    waterIntake = waterIntake.clamp(_minGoalOz, _maxGoalOz);

    // Round to nearest whole number
    return waterIntake.roundToDouble();
  }
}

enum Sex {
  male('Male', 0.55),
  female('Female', 0.50),
  preferNotToSay('Prefer not to say', 0.525);

  final String label;
  final double baseMultiplier;
  const Sex(this.label, this.baseMultiplier);
}

enum ActivityLevel {
  sedentary('Sedentary', 1.00, 'Mostly sitting, minimal exercise'),
  light('Light', 1.05, 'Light exercise 1-3 days/week'),
  moderate('Moderate', 1.10, 'Moderate exercise 3-5 days/week'),
  high('High', 1.15, 'Hard exercise 6-7 days/week'),
  extreme('Extreme', 1.25, 'Very hard exercise, physical job');

  final String label;
  final double multiplier;
  final String description;
  const ActivityLevel(this.label, this.multiplier, this.description);
}

enum WeatherCondition {
  cold('Cold', 1.00, '❄️'),
  cool('Cool', 1.00, '🌤️'),
  mild('Mild', 1.05, '☀️'),
  warm('Warm', 1.10, '🌡️'),
  hot('Hot', 1.20, '🔥');

  final String label;
  final double multiplier;
  final String emoji;
  const WeatherCondition(this.label, this.multiplier, this.emoji);
}
