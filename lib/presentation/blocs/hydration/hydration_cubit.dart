import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/data/services/notification_service.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';
import 'package:waddle/domain/entities/challenge.dart';
import 'package:waddle/domain/entities/daily_quest.dart';
import 'package:waddle/domain/entities/drink_type.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/shop_item.dart';
import 'package:waddle/domain/entities/water_log.dart';
import 'package:waddle/domain/entities/xp_level.dart';
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

        // Persist to Firestore if the reset changed the state (e.g.
        // totalDaysLogged incremented, daily water zeroed, quests refreshed)
        if (checkedState != hydrationState) {
          _hydrationRepository.saveHydrationState(userId, checkedState);
        }

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

    // ── XP calculation ──────────────────────────────────────────────
    final isFirstDrink = currentState.todayLogs.isEmpty;
    final xpMultiplier =
        currentState.hydration.inventory.doubleXpActive ? 2 : 1;
    int earnedXp = XpEvent.logDrink.xp * xpMultiplier;
    if (isHealthy) earnedXp += XpEvent.healthyPick.xp * xpMultiplier;
    if (isFirstDrink) earnedXp += XpEvent.firstDrinkOfDay.xp * xpMultiplier;

    // ── Daily quest progress ────────────────────────────────────────
    final questState = _ensureDailyQuests(currentState.hydration, now);
    final updatedQuests = _advanceQuests(
      quests: questState.dailyQuests,
      todayLogs: [...currentState.todayLogs, log],
      hydration: questState,
      newDrinkName: drinkName,
      isHealthy: isHealthy,
      goalMet: goalMet,
      logTime: now,
    );

    // NOTE: Quest rewards are now claimed manually on the challenges screen.
    // Only base XP from the drink itself is awarded here.
    final totalEarnedXp = earnedXp;

    // ── Check level-up for drops reward ─────────────────────────────
    final prevLevel = XpLevel.levelForXp(questState.totalXp);
    final newTotalXp = questState.totalXp + totalEarnedXp;
    final newLevel = XpLevel.levelForXp(newTotalXp);
    int levelUpDrops = 0;
    if (newLevel > prevLevel) {
      levelUpDrops = (newLevel - prevLevel) * 30;
    }

    final newState = questState.copyWith(
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
      totalXp: newTotalXp,
      drops: questState.drops + levelUpDrops,
      dailyQuests: updatedQuests,
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
    HydrationState latestState = newState;
    if (goalMet && !currentState.hydration.goalMetToday) {
      final oldStreak = currentState.hydration.currentStreak;
      final xpMul = currentState.hydration.inventory.doubleXpActive ? 2 : 1;

      // XP + Drops for meeting goal
      int goalXp = XpEvent.dailyGoalMet.xp * xpMul;
      int goalDrops = 5;

      // Increment streak and total goals met
      final newStreakVal = newState.currentStreak + 1;
      final streakState = newState.copyWith(
        currentStreak: newStreakVal,
        recordStreak: newStreakVal > newState.recordStreak
            ? newStreakVal
            : newState.recordStreak,
        totalGoalsMet: newState.totalGoalsMet + 1,
      );

      // Check streak milestone bonus
      if (StreakMilestones.isMilestone(newStreakVal)) {
        goalXp += XpEvent.streakMilestone.xp * xpMul;
        goalDrops += 30;
      }

      // Update quest progress for meetGoal type
      final goalQuests = _advanceQuests(
        quests: streakState.dailyQuests,
        todayLogs: [...currentState.todayLogs, log],
        hydration: streakState,
        goalMet: true,
        logTime: now,
      );

      final goalState = streakState.copyWith(
        totalXp: streakState.totalXp + goalXp,
        drops: streakState.drops + goalDrops,
        dailyQuests: goalQuests,
      );

      await _hydrationRepository.saveHydrationState(_userId, goalState);

      // Brief delay for fill animation to finish, then show congrats
      await Future.delayed(const Duration(milliseconds: 1500));
      final updatedLogs = [...currentState.todayLogs, log];
      emit(GoalReached(
        goalState,
        oldStreak: oldStreak,
        newStreak: goalState.currentStreak,
      ));

      // Fire goal-reached local notification
      try {
        getIt<NotificationService>().showGoalReachedNotification();
      } catch (_) {}

      // Immediately return to loaded state so the home screen rebuilds
      // correctly when the user pops the congrats screen.
      emit(HydrationLoaded(
        hydration: goalState,
        todayLogs: updatedLogs,
      ));

      latestState = goalState;
    }

    // Check for level-up celebration
    if (newLevel > prevLevel) {
      await Future.delayed(const Duration(milliseconds: 500));
      emit(LeveledUp(
        hydration: latestState,
        oldLevel: prevLevel,
        newLevel: newLevel,
        dropsAwarded: levelUpDrops,
      ));
      emit(HydrationLoaded(
        hydration: latestState,
        todayLogs: [...currentState.todayLogs, log],
      ));
    }

    // Check for new duck / theme unlocks after every drink
    await _checkNewUnlocks(latestState, [...currentState.todayLogs, log]);
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

  /// Set the active duck badge (shown on profile avatar).
  Future<void> setActiveDuck(int? duckIndex) async {
    if (_realState != null) return;

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final newState = currentState.hydration.copyWith(
      activeDuckIndex: duckIndex,
      clearActiveDuckIndex: duckIndex == null,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
  }

  /// Set the duck that floats in the water cup.
  Future<void> setCupDuck(int? duckIndex) async {
    if (_realState != null) return;

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final newState = currentState.hydration.copyWith(
      cupDuckIndex: duckIndex,
      clearCupDuckIndex: duckIndex == null,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
  }

  /// Toggle a duck on/off from the home-screen overlay (max 3).
  Future<void> toggleHomeDuck(int duckIndex) async {
    if (_realState != null) return;

    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final current = List<int>.from(currentState.hydration.homeDuckIndices);
    if (current.contains(duckIndex)) {
      current.remove(duckIndex);
    } else {
      if (current.length >= 3) return; // max 3 ducks
      current.add(duckIndex);
    }

    final newState = currentState.hydration.copyWith(
      homeDuckIndices: current,
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
      totalXp: 25000,
      drops: 999,
      inventory: const UserInventory(
        streakFreezes: 3,
        doubleXpTokens: 2,
        cooldownSkips: 5,
      ),
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

  /// Override individual fields while in debug mode.
  /// Does nothing if debug mode is not active.
  void debugOverrideState({
    int? currentStreak,
    int? recordStreak,
    double? waterConsumedOz,
    double? waterGoalOz,
    bool? goalMetToday,
    int? completedChallenges,
    double? totalWaterConsumedOz,
    int? totalDaysLogged,
    int? totalDrinksLogged,
    int? totalGoalsMet,
    int? totalXp,
    int? drops,
    bool clearNextEntryTime = false,
  }) {
    if (_realState == null) return; // not in debug mode
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final patched = currentState.hydration.copyWith(
      currentStreak: currentStreak,
      recordStreak: recordStreak,
      waterConsumedOz: waterConsumedOz,
      waterGoalOz: waterGoalOz,
      goalMetToday: goalMetToday,
      completedChallenges: completedChallenges,
      totalWaterConsumedOz: totalWaterConsumedOz,
      totalDaysLogged: totalDaysLogged,
      totalDrinksLogged: totalDrinksLogged,
      totalGoalsMet: totalGoalsMet,
      totalXp: totalXp,
      drops: drops,
      clearNextEntryTime: clearNextEntryTime,
    );

    emit(currentState.copyWith(hydration: patched));
  }

  /// Re-schedule the daily reset timer (call after changing reset hour).
  void rescheduleDailyReset() => _scheduleDailyReset();

  // ── Private helpers ────────────────────────────────────────────────

  /// Checks whether any duck companions or themes have just become unlocked
  /// that the user hasn't seen yet. If so, emits [RewardUnlocked] followed by
  /// [HydrationLoaded] and persists the updated seen-lists.
  Future<void> _checkNewUnlocks(
      HydrationState hydration, List<WaterLog> todayLogs) async {
    final newDuckIndices = <int>[];
    for (final duck in DuckCompanions.all) {
      if (duck.unlockCondition.isUnlocked(
            currentStreak: hydration.currentStreak,
            recordStreak: hydration.recordStreak,
            completedChallenges: hydration.completedChallenges,
            totalWaterConsumed: hydration.totalWaterConsumedOz,
            totalDaysLogged: hydration.totalDaysLogged,
            totalHealthyPicks: hydration.totalHealthyPicks,
            totalGoalsMet: hydration.totalGoalsMet,
            totalDrinksLogged: hydration.totalDrinksLogged,
            uniqueDrinks: hydration.uniqueDrinksLogged.length,
            challengeActive: hydration.challengeActive,
          ) &&
          !hydration.seenDuckIndices.contains(duck.index)) {
        newDuckIndices.add(duck.index);
      }
    }

    final newThemeIds = <String>[];
    for (final theme in ThemeRewards.all) {
      if (theme.unlockCondition.isUnlocked(
            level: hydration.level,
            purchasedThemeIds: hydration.purchasedThemeIds,
            themeId: theme.id,
          ) &&
          !hydration.seenThemeIds.contains(theme.id)) {
        newThemeIds.add(theme.id);
      }
    }

    if (newDuckIndices.isEmpty && newThemeIds.isEmpty) return;

    final updated = hydration.copyWith(
      seenDuckIndices: [...hydration.seenDuckIndices, ...newDuckIndices],
      seenThemeIds: [...hydration.seenThemeIds, ...newThemeIds],
    );

    await _hydrationRepository.saveHydrationState(_userId, updated);

    emit(RewardUnlocked(
      hydration: updated,
      newDuckIndices: newDuckIndices,
      newThemeIds: newThemeIds,
    ));

    // Return to loaded state so the home screen can rebuild correctly.
    emit(HydrationLoaded(
      hydration: updated,
      todayLogs: todayLogs,
    ));
  }

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
      bool usedFreeze = false;

      // Count the previous day as a logged day if any water was consumed
      final int addDay = state.waterConsumedOz > 0 ? 1 : 0;

      if (state.goalMetToday) {
        // Keep streak (already incremented when goal met)
      } else if (state.waterConsumedOz > 0) {
        // Didn't meet goal — try streak freeze
        if (state.inventory.streakFreezes > 0) {
          usedFreeze = true;
          // Streak preserved, freeze consumed
        } else {
          newStreak = 0; // Didn't meet goal
        }
      }

      // Reset daily quests + doubleXp flag for new day
      final newQuests = DailyQuests.pickForDay(now);
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final questProgress =
          newQuests.map((q) => DailyQuestProgress(questId: q.id)).toList();

      return state.copyWith(
        waterConsumedOz: 0.0,
        goalMetToday: false,
        lastResetDate: now,
        clearNextEntryTime: true,
        currentStreak: newStreak,
        totalDaysLogged: state.totalDaysLogged + addDay,
        dailyQuests: questProgress,
        dailyQuestsDate: todayStr,
        inventory: usedFreeze
            ? state.inventory.copyWith(
                streakFreezes: state.inventory.streakFreezes - 1,
                doubleXpActive: false,
              )
            : state.inventory.copyWith(doubleXpActive: false),
      );
    }

    return state;
  }

  void _checkChallengeStatus(HydrationState hydrationState) {
    if (hydrationState.challengeCompleted &&
        hydrationState.activeChallengeIndex != null) {
      // Award challenge completion XP + drops
      final challenge =
          Challenges.getByIndex(hydrationState.activeChallengeIndex!);
      final xpMul = hydrationState.inventory.doubleXpActive ? 2 : 1;
      final rewardedState = hydrationState.copyWith(
        totalXp: hydrationState.totalXp + challenge.xpReward * xpMul,
        drops: hydrationState.drops + challenge.dropsReward,
      );
      _hydrationRepository.saveHydrationState(_userId, rewardedState);
      emit(ChallengeCompleted(
        challengeIndex: hydrationState.activeChallengeIndex!,
        hydration: rewardedState,
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

  // ── Shop & Inventory ──────────────────────────────────────────────

  /// Purchase a shop item. Returns false if insufficient drops or at max.
  Future<bool> purchaseShopItem(ShopItem item) async {
    if (_realState != null) return false;

    final currentState = state;
    if (currentState is! HydrationLoaded) return false;

    final hydration = currentState.hydration;
    if (hydration.drops < item.price) return false;
    if (!hydration.inventory.canPurchase(item)) return false;

    UserInventory newInventory;
    switch (item.id) {
      case 'streak_freeze':
        newInventory = hydration.inventory.copyWith(
          streakFreezes: hydration.inventory.streakFreezes + 1,
        );
        break;
      case 'double_xp':
        newInventory = hydration.inventory.copyWith(
          doubleXpTokens: hydration.inventory.doubleXpTokens + 1,
        );
        break;
      case 'cooldown_skip':
        newInventory = hydration.inventory.copyWith(
          cooldownSkips: hydration.inventory.cooldownSkips + 1,
        );
        break;
      default:
        return false;
    }

    final newState = hydration.copyWith(
      drops: hydration.drops - item.price,
      inventory: newInventory,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
    return true;
  }

  /// Purchase a market theme with Drops. Returns false if insufficient drops
  /// or already purchased.
  Future<bool> purchaseTheme(ThemeReward theme) async {
    if (_realState != null) return false;

    final currentState = state;
    if (currentState is! HydrationLoaded) return false;

    final hydration = currentState.hydration;
    if (!theme.isPurchasable) return false;
    if (hydration.purchasedThemeIds.contains(theme.id)) return false;
    if (hydration.drops < theme.price) return false;

    final newState = hydration.copyWith(
      drops: hydration.drops - theme.price,
      purchasedThemeIds: [...hydration.purchasedThemeIds, theme.id],
      seenThemeIds: [...hydration.seenThemeIds, theme.id],
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
    return true;
  }

  /// Activate a Double-XP token (consumed immediately, lasts until midnight).
  Future<bool> activateDoubleXp() async {
    if (_realState != null) return false;

    final currentState = state;
    if (currentState is! HydrationLoaded) return false;

    final hydration = currentState.hydration;
    if (hydration.inventory.doubleXpTokens <= 0) return false;
    if (hydration.inventory.doubleXpActive) return false;

    final newInventory = hydration.inventory.copyWith(
      doubleXpTokens: hydration.inventory.doubleXpTokens - 1,
      doubleXpActive: true,
    );

    final newState = hydration.copyWith(inventory: newInventory);
    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
    return true;
  }

  /// Use a cooldown-skip item to clear the drink-logging timer.
  Future<bool> useCooldownSkip() async {
    if (_realState != null) return false;

    final currentState = state;
    if (currentState is! HydrationLoaded) return false;

    final hydration = currentState.hydration;
    if (hydration.inventory.cooldownSkips <= 0) return false;

    final newInventory = hydration.inventory.copyWith(
      cooldownSkips: hydration.inventory.cooldownSkips - 1,
    );

    final newState = hydration.copyWith(
      clearNextEntryTime: true,
      inventory: newInventory,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);
    return true;
  }

  // ── Daily Quests helpers ──────────────────────────────────────────

  /// Ensures daily quests are initialised for today. If the stored
  /// `dailyQuestsDate` differs from today, picks new quests.
  HydrationState _ensureDailyQuests(HydrationState h, DateTime now) {
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (h.dailyQuestsDate == todayStr && h.dailyQuests.isNotEmpty) return h;

    final quests = DailyQuests.pickForDay(now);
    final progress =
        quests.map((q) => DailyQuestProgress(questId: q.id)).toList();
    return h.copyWith(
      dailyQuests: progress,
      dailyQuestsDate: todayStr,
    );
  }

  /// Recompute progress for each quest slot given updated state.
  List<DailyQuestProgress> _advanceQuests({
    required List<DailyQuestProgress> quests,
    required List<WaterLog> todayLogs,
    required HydrationState hydration,
    String? newDrinkName,
    bool isHealthy = false,
    bool goalMet = false,
    DateTime? logTime,
  }) {
    return quests.map((qp) {
      if (qp.completed) return qp; // already done

      final tmpl = DailyQuests.byId(qp.questId);
      if (tmpl == null) return qp;

      int progress;
      switch (tmpl.type) {
        case DailyQuestType.logDrinks:
          progress = todayLogs.length;
          break;
        case DailyQuestType.drinkOz:
          progress = hydration.waterConsumedOz.round();
          break;
        case DailyQuestType.healthyPicks:
          progress = todayLogs.where((l) {
            final d = DrinkTypes.byName(l.drinkName);
            return d != null &&
                (d.healthTier == HealthTier.excellent ||
                    d.healthTier == HealthTier.good);
          }).length;
          break;
        case DailyQuestType.earlyBird:
          // target is hour threshold — progress is 1 if any log before that hour
          final hasBefore =
              todayLogs.any((l) => l.entryTime.hour < tmpl.target);
          progress = hasBefore ? 1 : 0;
          break;
        case DailyQuestType.uniqueDrinks:
          progress = todayLogs.map((l) => l.drinkName).toSet().length;
          break;
        case DailyQuestType.meetGoal:
          progress = goalMet ? 1 : 0;
          break;
        case DailyQuestType.spreadHydration:
          progress = todayLogs.map((l) => l.entryTime.hour).toSet().length;
          break;
      }

      final isNowComplete = progress >= tmpl.target;
      return qp.copyWith(
        current: progress,
        completed: isNowComplete,
        completedAt: isNowComplete && !qp.completed ? DateTime.now() : null,
      );
    }).toList();
  }

  /// Public method to refresh quest display (e.g. when opening quests UI).
  void refreshDailyQuests() {
    final currentState = state;
    if (currentState is! HydrationLoaded) return;

    final now = DateTime.now();
    final updated = _ensureDailyQuests(currentState.hydration, now);

    if (updated != currentState.hydration) {
      emit(currentState.copyWith(hydration: updated));
      _hydrationRepository.saveHydrationState(_userId, updated);
    }
  }

  /// Manually claim a completed daily quest reward.
  /// Returns true if the claim was successful.
  Future<bool> claimQuest(int questIndex) async {
    if (_realState != null) return false;

    final currentState = state;
    if (currentState is! HydrationLoaded) return false;

    final quests = currentState.hydration.dailyQuests;
    if (questIndex < 0 || questIndex >= quests.length) return false;

    final quest = quests[questIndex];
    if (!quest.completed || quest.claimed) return false;

    final tmpl = DailyQuests.byId(quest.questId);
    if (tmpl == null) return false;

    final xpMul = currentState.hydration.inventory.doubleXpActive ? 2 : 1;
    int claimedXp = tmpl.xpReward * xpMul;
    int claimedDrops = tmpl.dropsReward;

    // Mark this quest as claimed
    final updatedQuests = List<DailyQuestProgress>.from(quests);
    updatedQuests[questIndex] = quest.copyWith(claimed: true);

    // Check if ALL quests are now claimed → bonus
    final allClaimed = updatedQuests.every((q) => q.claimed);
    if (allClaimed) {
      claimedXp += XpEvent.allDailyQuests.xp * xpMul;
      claimedDrops += 20; // bonus drops
    }

    final newState = currentState.hydration.copyWith(
      totalXp: currentState.hydration.totalXp + claimedXp,
      drops: currentState.hydration.drops + claimedDrops,
      dailyQuests: updatedQuests,
    );

    emit(currentState.copyWith(hydration: newState));
    await _hydrationRepository.saveHydrationState(_userId, newState);

    // Check level-up after claim
    final prevLevel = XpLevel.levelForXp(currentState.hydration.totalXp);
    final newLevel = XpLevel.levelForXp(newState.totalXp);
    if (newLevel > prevLevel) {
      final levelUpDrops = (newLevel - prevLevel) * 30;
      final levelState = newState.copyWith(
        drops: newState.drops + levelUpDrops,
      );
      await _hydrationRepository.saveHydrationState(_userId, levelState);
      emit(LeveledUp(
        hydration: levelState,
        oldLevel: prevLevel,
        newLevel: newLevel,
        dropsAwarded: levelUpDrops,
      ));
      emit(HydrationLoaded(
        hydration: levelState,
        todayLogs: currentState.todayLogs,
      ));
    }

    return true;
  }

  @override
  Future<void> close() {
    _dailyResetTimer?.cancel();
    _resetWatchdog?.cancel();
    _animationTimer?.cancel();
    return super.close();
  }
}
