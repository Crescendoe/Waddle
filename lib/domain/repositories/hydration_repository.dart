import 'package:dartz/dartz.dart';
import 'package:waddle/core/error/failures.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/water_log.dart';

/// Hydration data repository contract
abstract class HydrationRepository {
  /// Load hydration state for a user
  Future<Either<Failure, HydrationState>> loadHydrationState(String userId);

  /// Save hydration state
  Future<Either<Failure, void>> saveHydrationState(
      String userId, HydrationState state);

  /// Add a water log entry
  Future<Either<Failure, void>> addWaterLog(String userId, WaterLog log,
      {bool isHealthyPick = false});

  /// Remove a water log entry
  Future<Either<Failure, void>> removeWaterLog(String userId, WaterLog log);

  /// Clear all water logs for a specific date
  Future<Either<Failure, void>> clearLogsForDate(String userId, DateTime date);

  /// Get water logs for a specific date
  Future<Either<Failure, List<WaterLog>>> getLogsForDate(
      String userId, DateTime date);

  /// Get all water logs (for stats/history)
  Future<Either<Failure, List<WaterLog>>> getAllLogs(String userId);

  /// Get logged days map (date → goalMet)
  Future<Either<Failure, Map<DateTime, bool>>> getLoggedDays(String userId);

  /// Get total water consumed all time
  Future<Either<Failure, double>> getTotalWaterConsumed(String userId);

  /// Get total days logged
  Future<Either<Failure, int>> getTotalDaysLogged(String userId);

  /// Update water goal
  Future<Either<Failure, void>> updateWaterGoal(String userId, double goalOz);

  /// Reset daily data (called at midnight)
  Future<Either<Failure, void>> resetDailyData(
      String userId, HydrationState currentState);

  /// Update challenge state
  Future<Either<Failure, void>> updateChallengeState(
    String userId, {
    int? activeChallengeIndex,
    List<bool>? challengeActive,
    bool? challengeFailed,
    bool? challengeCompleted,
    int? challengeDaysLeft,
    int? completedChallenges,
  });
}
