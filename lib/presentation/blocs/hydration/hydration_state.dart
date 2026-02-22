import 'package:equatable/equatable.dart';
import 'package:waddle/domain/entities/drink_type.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/water_log.dart';

abstract class HydrationBlocState extends Equatable {
  const HydrationBlocState();

  @override
  List<Object?> get props => [];
}

class HydrationInitial extends HydrationBlocState {
  const HydrationInitial();
}

class HydrationLoading extends HydrationBlocState {
  const HydrationLoading();
}

class HydrationLoaded extends HydrationBlocState {
  final HydrationState hydration;
  final List<WaterLog> todayLogs;
  final bool isAnimating;
  final double animatedWaterOz;
  final Map<DateTime, bool> calendarDays;
  final List<WaterLog> selectedDayLogs;
  final DateTime? selectedCalendarDay;

  const HydrationLoaded({
    required this.hydration,
    this.todayLogs = const [],
    this.isAnimating = false,
    this.animatedWaterOz = 0.0,
    this.calendarDays = const {},
    this.selectedDayLogs = const [],
    this.selectedCalendarDay,
  });

  double get displayedWater =>
      isAnimating ? animatedWaterOz : hydration.waterConsumedOz;

  /// Count of healthy picks (excellent or good tier) logged today.
  /// Always additive — never penalizes, only rewards.
  int get healthyPicksToday => todayLogs.where((log) {
        final drink = DrinkTypes.byName(log.drinkName);
        final tier = drink?.healthTier ?? HealthTier.good;
        return tier == HealthTier.excellent || tier == HealthTier.good;
      }).length;

  HydrationLoaded copyWith({
    HydrationState? hydration,
    List<WaterLog>? todayLogs,
    bool? isAnimating,
    double? animatedWaterOz,
    Map<DateTime, bool>? calendarDays,
    List<WaterLog>? selectedDayLogs,
    DateTime? selectedCalendarDay,
    bool clearSelectedDay = false,
  }) {
    return HydrationLoaded(
      hydration: hydration ?? this.hydration,
      todayLogs: todayLogs ?? this.todayLogs,
      isAnimating: isAnimating ?? this.isAnimating,
      animatedWaterOz: animatedWaterOz ?? this.animatedWaterOz,
      calendarDays: calendarDays ?? this.calendarDays,
      selectedDayLogs: selectedDayLogs ?? this.selectedDayLogs,
      selectedCalendarDay: clearSelectedDay
          ? null
          : (selectedCalendarDay ?? this.selectedCalendarDay),
    );
  }

  @override
  List<Object?> get props => [
        hydration,
        todayLogs,
        isAnimating,
        animatedWaterOz,
        calendarDays,
        selectedDayLogs,
        selectedCalendarDay,
      ];
}

class HydrationError extends HydrationBlocState {
  final String message;
  const HydrationError(this.message);

  @override
  List<Object?> get props => [message];
}

class GoalReached extends HydrationBlocState {
  final HydrationState hydration;
  final int oldStreak;
  final int newStreak;
  const GoalReached(this.hydration,
      {required this.oldStreak, required this.newStreak});

  @override
  List<Object?> get props => [hydration, oldStreak, newStreak];
}

class ChallengeCompleted extends HydrationBlocState {
  final int challengeIndex;
  final HydrationState hydration;
  const ChallengeCompleted(
      {required this.challengeIndex, required this.hydration});

  @override
  List<Object?> get props => [challengeIndex, hydration];
}

class ChallengeFailed extends HydrationBlocState {
  final int challengeIndex;
  final HydrationState hydration;
  const ChallengeFailed(
      {required this.challengeIndex, required this.hydration});

  @override
  List<Object?> get props => [challengeIndex, hydration];
}

/// Emitted when a duck or theme is newly unlocked.
class RewardUnlocked extends HydrationBlocState {
  final HydrationState hydration;

  /// Indices of newly-unlocked ducks (may be empty).
  final List<int> newDuckIndices;

  /// IDs of newly-unlocked themes (may be empty).
  final List<String> newThemeIds;

  const RewardUnlocked({
    required this.hydration,
    this.newDuckIndices = const [],
    this.newThemeIds = const [],
  });

  @override
  List<Object?> get props => [hydration, newDuckIndices, newThemeIds];
}
