import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/data/services/notification_service.dart';
import 'package:waddle/domain/entities/drink_type.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/water_log.dart';
import 'package:waddle/domain/repositories/health_repository.dart';
import 'package:waddle/domain/repositories/hydration_repository.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';

class HydrationCubit extends Cubit<HydrationBlocState> {
  final HydrationRepository _hydrationRepository;
  final HealthRepository? _healthRepository;
  String _userId = '';
  Timer? _dailyResetTimer;
  Timer? _resetWatchdog;
  Timer? _animationTimer;

  HydrationCubit({
    required HydrationRepository hydrationRepository,
    HealthRepository? healthRepository,
  })  : _hydrationRepository = hydrationRepository,
        _healthRepository = healthRepository,
        super(const HydrationInitial());

  String get userId => _userId;

  /// Load hydration data for a user
  Future<void> loadData(String userId) async {
    _userId = userId;
    emit(const HydrationLoading());

    final result = await _hydrationRepository.loadHydrationState(userId);

    await result.fold(
      (failure) async => emit(HydrationError(failure.message)),
      (hydrationState) async {
        // Check if daily reset needed
        final checkedState = _checkDailyReset(hydrationState);

        // Load today's logs
        final logsResult = await _hydrationRepository.getLogsForDate(
          userId,
          DateTime.now(),
        );
        final todayLogs = logsResult.fold((_) => <WaterLog>[], (logs) => logs);

        emit(HydrationLoaded(
          hydration: checkedState,
          todayLogs: todayLogs,
        ));

        // Check challenge status
        _checkChallengeStatus(checkedState);

        // Schedule daily reset
        _scheduleDailyReset();

        // Start periodic watchdog that catches missed resets
        _startResetWatchdog();
      },
    );
  }

  /// Add water intake
  Future<void> addWater(
      double amountOz, String drinkName, double waterRatio) async {
    // Block during debug mode to prevent corrupted data persistence
    if (_realState != null) return;

    // Safety: ensure the day has been reset before accepting new input
    _applyResetIfNeeded();

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final waterContent = amountOz * waterRatio;
    final now = DateTime.now();

    // Create log entry
    final log = WaterLog(
      drinkName: drinkName,
      amountOz: amountOz,
      waterContentOz: waterContent,
      entryTime: now,
    );

    // Determine if this is a healthy pick (excellent or good tier)
    final drink = DrinkTypes.byName(drinkName);
    final isHealthy = drink != null &&
        (drink.healthTier == HealthTier.excellent ||
            drink.healthTier == HealthTier.good);

    // Optimistic update with animation
    final newConsumed = currentState.hydration.waterConsumedOz + waterContent;
    final goalMet = newConsumed >= currentState.hydration.waterGoalOz;

    // Update lifetime stats locally
    final updatedUnique =
        currentState.hydration.uniqueDrinksLogged.contains(drinkName)
            ? currentState.hydration.uniqueDrinksLogged
            : [...currentState.hydration.uniqueDrinksLogged, drinkName];

    final newState = currentState.hydration.copyWith(
      waterConsumedOz: newConsumed,
      goalMetToday: goalMet,
      nextEntryTime:
          now.add(const Duration(minutes: AppConstants.entryTimerMinutes)),
      totalWaterConsumedOz:
          currentState.hydration.totalWaterConsumedOz + waterContent,
      totalDrinksLogged: currentState.hydration.totalDrinksLogged + 1,
      totalHealthyPicks: isHealthy
          ? currentState.hydration.totalHealthyPicks + 1
          : currentState.hydration.totalHealthyPicks,
      uniqueDrinksLogged: updatedUnique,
    );

    // Start fill animation
    _animateWaterFill(
      from: currentState.hydration.waterConsumedOz,
      to: newConsumed,
      currentState: currentState,
      finalHydration: newState,
      newLog: log,
    );

    // Persist
    await _hydrationRepository.addWaterLog(_userId, log,
        isHealthyPick: isHealthy);
    await _hydrationRepository.saveHydrationState(_userId, newState);

    // Sync with health platform
    if (_healthRepository != null) {
      await _healthRepository.writeWaterIntake(
        amountMl: waterContent * 29.5735,
        dateTime: now,
      );
    }

    // Check halfway milestone (crossing 50%)
    final goal = currentState.hydration.waterGoalOz;
    final prevConsumed = currentState.hydration.waterConsumedOz;
    if (prevConsumed < goal * 0.5 && newConsumed >= goal * 0.5 && !goalMet) {
      try {
        getIt<NotificationService>().showHalfwayNotification();
      } catch (_) {}
    }

    // Check goal
    if (goalMet && !currentState.hydration.goalMetToday) {
      // Increment streak and total goals met
      final streakState = newState.copyWith(
        currentStreak: newState.currentStreak + 1,
        recordStreak: (newState.currentStreak + 1) > newState.recordStreak
            ? newState.currentStreak + 1
            : newState.recordStreak,
        totalGoalsMet: newState.totalGoalsMet + 1,
      );
      await _hydrationRepository.saveHydrationState(_userId, streakState);

      // Brief delay then emit goal reached
      await Future.delayed(const Duration(milliseconds: 1500));
      emit(GoalReached(streakState));

      // Fire goal-reached local notification
      try {
        getIt<NotificationService>().showGoalReachedNotification();
      } catch (_) {}

      // Then return to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      final updatedLogs = [...currentState.todayLogs, log];
      emit(HydrationLoaded(
        hydration: streakState,
        todayLogs: updatedLogs,
      ));
    }
  }

  /// Remove a water log entry
  Future<void> removeLog(WaterLog log) async {
    // Block during debug mode
    if (_realState != null) return;

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final newConsumed =
        (currentState.hydration.waterConsumedOz - log.waterContentOz)
            .clamp(0.0, double.infinity);
    final goalMet = newConsumed >= currentState.hydration.waterGoalOz;

    // Determine if this was a healthy pick for lifetime stat decrement
    final drink = DrinkTypes.byName(log.drinkName);
    final isHealthy = drink != null &&
        (drink.healthTier == HealthTier.excellent ||
            drink.healthTier == HealthTier.good);

    final newState = currentState.hydration.copyWith(
      waterConsumedOz: newConsumed,
      goalMetToday: goalMet,
      totalWaterConsumedOz:
          (currentState.hydration.totalWaterConsumedOz - log.waterContentOz)
              .clamp(0.0, double.infinity),
      totalDrinksLogged:
          (currentState.hydration.totalDrinksLogged - 1).clamp(0, 999999),
      totalHealthyPicks: isHealthy
          ? (currentState.hydration.totalHealthyPicks - 1).clamp(0, 999999)
          : currentState.hydration.totalHealthyPicks,
    );

    final updatedLogs = currentState.todayLogs.where((l) => l != log).toList();

    emit(HydrationLoaded(
      hydration: newState,
      todayLogs: updatedLogs,
    ));

    await _hydrationRepository.removeWaterLog(_userId, log);
    await _hydrationRepository.saveHydrationState(_userId, newState);
  }

  /// Load calendar data (which days had logs and whether goal was met)
  Future<void> loadCalendarData() async {
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final result = await _hydrationRepository.getLoggedDays(_userId);
    result.fold(
      (_) {}, // Ignore errors silently
      (days) {
        if (state is HydrationLoaded) {
          emit((state as HydrationLoaded).copyWith(calendarDays: days));
        }
      },
    );
  }

  /// Select a day in the calendar and load its logs
  Future<void> selectCalendarDay(DateTime day) async {
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    emit(currentState.copyWith(
      selectedCalendarDay: day,
      selectedDayLogs: const [],
    ));

    final result = await _hydrationRepository.getLogsForDate(_userId, day);
    result.fold(
      (_) {},
      (logs) {
        if (state is HydrationLoaded) {
          emit((state as HydrationLoaded).copyWith(selectedDayLogs: logs));
        }
      },
    );
  }

  /// Set water goal
  Future<void> setWaterGoal(double goalOz) async {
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final newState = currentState.hydration.copyWith(waterGoalOz: goalOz);
    emit(currentState.copyWith(hydration: newState));

    await _hydrationRepository.updateWaterGoal(_userId, goalOz);
  }

  /// Start a challenge
  Future<void> startChallenge(int challengeIndex) async {
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final challengeActive =
        List<bool>.from(currentState.hydration.challengeActive);
    challengeActive[challengeIndex] = true;

    final newState = currentState.hydration.copyWith(
      activeChallengeIndex: challengeIndex,
      challengeActive: challengeActive,
      challengeFailed: false,
      challengeCompleted: false,
      challengeDaysLeft: AppConstants.challengeDurationDays,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
  }

  /// Give up current challenge — resets the active flag so it is NOT
  /// shown as completed.
  Future<void> giveUpChallenge() async {
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    // Undo the challengeActive flag for this challenge
    final activeIdx = currentState.hydration.activeChallengeIndex;
    final challengeActive =
        List<bool>.from(currentState.hydration.challengeActive);
    if (activeIdx != null && activeIdx < challengeActive.length) {
      challengeActive[activeIdx] = false;
    }

    final newState = currentState.hydration.copyWith(
      clearActiveChallengeIndex: true,
      challengeActive: challengeActive,
      challengeFailed: false,
      challengeCompleted: false,
      challengeDaysLeft: 14,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
  }

  /// Acknowledge challenge result (failure/completion) and return to normal.
  /// On failure, revert the challengeActive flag so the challenge is not
  /// shown as completed.
  Future<void> acknowledgeChallengeResult() async {
    final currentState = state;
    HydrationState? hydration;
    bool wasFailed = false;

    if (currentState is ChallengeFailed) {
      hydration = currentState.hydration;
      wasFailed = true;
    } else if (currentState is ChallengeCompleted) {
      hydration = currentState.hydration;
    } else if (currentState is HydrationLoaded) {
      hydration = currentState.hydration;
      // If the persisted flags indicate failure, treat as failed
      wasFailed = hydration.challengeFailed;
    }

    if (hydration == null) return;

    // On failure: undo the challengeActive flag so it shows as "not completed"
    final challengeActive = List<bool>.from(hydration.challengeActive);
    if (wasFailed && hydration.activeChallengeIndex != null) {
      final idx = hydration.activeChallengeIndex!;
      if (idx < challengeActive.length) challengeActive[idx] = false;
    }

    final newState = hydration.copyWith(
      clearActiveChallengeIndex: true,
      challengeActive: challengeActive,
      challengeFailed: false,
      challengeCompleted: false,
      challengeDaysLeft: 14,
    );

    final todayLogs =
        currentState is HydrationLoaded ? currentState.todayLogs : <WaterLog>[];

    emit(HydrationLoaded(hydration: newState, todayLogs: todayLogs));
    await _hydrationRepository.saveHydrationState(_userId, newState);
  }

  /// Clear today's water data (reset to zero without breaking streak)
  Future<void> clearTodayData() async {
    // Block during debug mode
    if (_realState != null) return;

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final newState = currentState.hydration.copyWith(
      waterConsumedOz: 0.0,
      goalMetToday: false,
      clearNextEntryTime: true,
    );

    emit(HydrationLoaded(
      hydration: newState,
      todayLogs: const [],
    ));

    await _hydrationRepository.saveHydrationState(_userId, newState);
    // Remove today's log documents
    await _hydrationRepository.clearLogsForDate(_userId, DateTime.now());
  }

  /// Reset entry cooldown timer (debug)
  void resetEntryTimer() {
    if (_realState != null) return; // Block during debug mode

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final newState = currentState.hydration.copyWith(clearNextEntryTime: true);
    emit(currentState.copyWith(hydration: newState));
    _hydrationRepository.saveHydrationState(_userId, newState);
  }

  /// Apply an unlocked theme (or reset to default with null).
  Future<void> setActiveTheme(String? themeId) async {
    if (_realState != null) return; // Block during debug mode

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final newState = currentState.hydration.copyWith(
      activeThemeId: themeId,
      clearActiveThemeId: themeId == null,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
  }

  // ── Debug mode ────────────────────────────────────────────────────

  /// Saved copy of real state before debug mode was activated.
  HydrationState? _realState;

  /// Activate debug mode — overrides stats so everything appears unlocked.
  /// Does NOT persist to Firestore. Pauses background saves.
  void activateDebugMode() {
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    _realState = currentState.hydration;

    // Pause background timers that could trigger saves
    _resetWatchdog?.cancel();
    _dailyResetTimer?.cancel();

    // All drink names for uniqueDrinksLogged
    final allDrinks = [
      'Water',
      'Sparkling Water',
      'Coconut Water',
      'Green Tea',
      'Black Tea',
      'Herbal Tea',
      'Coffee',
      'Espresso',
      'Latte',
      'Cappuccino',
      'Matcha',
      'Orange Juice',
      'Apple Juice',
      'Cranberry Juice',
      'Lemonade',
      'Smoothie',
      'Protein Shake',
      'Milk',
      'Oat Milk',
      'Almond Milk',
      'Hot Chocolate',
      'Kombucha',
      'Energy Drink',
      'Sports Drink',
      'Soda',
    ];

    final debugState = currentState.hydration.copyWith(
      waterConsumedOz: 70.0,
      waterGoalOz: 80.0,
      currentStreak: 365,
      recordStreak: 365,
      goalMetToday: false,
      completedChallenges: 6,
      challengeActive: const [true, true, true, true, true, true],
      totalWaterConsumedOz: 15000.0,
      totalDaysLogged: 365,
      totalDrinksLogged: 2000,
      totalHealthyPicks: 500,
      uniqueDrinksLogged: allDrinks,
      totalGoalsMet: 300,
      clearNextEntryTime: true,
    );

    emit(currentState.copyWith(hydration: debugState));
  }

  /// Deactivate debug mode — restore the real state.
  void deactivateDebugMode() {
    final currentState = state;
    if (currentState is! HydrationLoaded || _realState == null) return;

    emit(currentState.copyWith(hydration: _realState!));
    _realState = null;

    // Resume background timers
    _startResetWatchdog();
    _scheduleDailyReset();
  }

  /// Re-schedule the daily reset timer (call after changing reset hour).
  void rescheduleDailyReset() => _scheduleDailyReset();

  // ── Private helpers ────────────────────────────────────────────────

  void _animateWaterFill({
    required double from,
    required double to,
    required HydrationLoaded currentState,
    required HydrationState finalHydration,
    required WaterLog newLog,
  }) {
    _animationTimer?.cancel();

    double current = from;
    final increment = (to - from) / 30; // 30 steps
    int step = 0;

    // Include the new log in todayLogs from the start so the segmented
    // painter knows about the new drink and can grow it as fill rises.
    final logsWithNew = [...currentState.todayLogs, newLog];

    emit(currentState.copyWith(
      isAnimating: true,
      animatedWaterOz: from,
      todayLogs: logsWithNew,
    ));

    _animationTimer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      step++;
      current += increment;

      if (step >= 30 || current >= to) {
        timer.cancel();
        emit(HydrationLoaded(
          hydration: finalHydration,
          todayLogs: logsWithNew,
          isAnimating: false,
          animatedWaterOz: to,
        ));
      } else {
        emit(currentState.copyWith(
          isAnimating: true,
          animatedWaterOz: current,
          hydration: finalHydration,
          todayLogs: logsWithNew,
        ));
      }
    });
  }

  HydrationState _checkDailyReset(HydrationState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If lastResetDate was never set, initialise it to now so future
    // checks have a baseline. No data to clear on first run.
    if (state.lastResetDate == null) {
      return state.copyWith(lastResetDate: now);
    }

    final lastReset = DateTime(
      state.lastResetDate!.year,
      state.lastResetDate!.month,
      state.lastResetDate!.day,
    );

    if (lastReset.isBefore(today)) {
      // New day — reset
      int newStreak = state.currentStreak;
      if (state.goalMetToday) {
        // Keep streak (already incremented when goal met)
      } else if (state.waterConsumedOz > 0) {
        newStreak = 0; // Didn't meet goal
      }

      return state.copyWith(
        waterConsumedOz: 0.0,
        goalMetToday: false,
        lastResetDate: now,
        clearNextEntryTime: true,
        currentStreak: newStreak,
      );
    }

    return state;
  }

  void _checkChallengeStatus(HydrationState hydrationState) {
    if (hydrationState.challengeCompleted &&
        hydrationState.activeChallengeIndex != null) {
      emit(ChallengeCompleted(
        challengeIndex: hydrationState.activeChallengeIndex!,
        hydration: hydrationState,
      ));
    } else if (hydrationState.challengeFailed &&
        hydrationState.activeChallengeIndex != null) {
      emit(ChallengeFailed(
        challengeIndex: hydrationState.activeChallengeIndex!,
        hydration: hydrationState,
      ));
    }
  }

  /// Synchronously apply daily reset to in-memory state if a day boundary
  /// has been crossed. Called before every addWater and by the watchdog.
  void _applyResetIfNeeded() {
    // Don't touch state during debug mode
    if (_realState != null) return;

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final checked = _checkDailyReset(currentState.hydration);
    if (checked != currentState.hydration) {
      emit(HydrationLoaded(
        hydration: checked,
        todayLogs: const [], // new day → no logs yet
      ));
      _hydrationRepository.saveHydrationState(_userId, checked);
    }
  }

  /// Periodic 60-second watchdog that catches day-boundary crossings the
  /// main timer might miss (e.g. after the app returns from background).
  void _startResetWatchdog() {
    _resetWatchdog?.cancel();
    _resetWatchdog = Timer.periodic(
        const Duration(seconds: 60), (_) => _applyResetIfNeeded());
  }

  void _scheduleDailyReset() {
    _dailyResetTimer?.cancel();

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    _dailyResetTimer = Timer(timeUntilMidnight, () async {
      final currentState = state;
      if (currentState is HydrationLoaded) {
        await _hydrationRepository.resetDailyData(
          _userId,
          currentState.hydration,
        );
        await loadData(_userId);
      }
      _scheduleDailyReset(); // Reschedule
    });
  }

  @override
  Future<void> close() {
    _dailyResetTimer?.cancel();
    _resetWatchdog?.cancel();
    _animationTimer?.cancel();
    return super.close();
  }
}
