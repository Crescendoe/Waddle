import 'package:dartz/dartz.dart';
import 'package:waddle/core/error/failures.dart';

/// Health platform integration repository contract
abstract class HealthRepository {
  /// Check if health platform is available
  Future<Either<Failure, bool>> isAvailable();

  /// Request permissions from health platform
  Future<Either<Failure, bool>> requestPermissions();

  /// Check if health sync is enabled
  Future<Either<Failure, bool>> isSyncEnabled();

  /// Enable/disable health sync
  Future<Either<Failure, void>> setSyncEnabled(bool enabled);

  /// Write water intake to health platform
  Future<Either<Failure, void>> writeWaterIntake({
    required double amountMl,
    required DateTime dateTime,
  });

  /// Read today's water intake from health platform
  Future<Either<Failure, double>> readTodayWaterIntake();

  /// Read water intake for a date range
  Future<Either<Failure, Map<DateTime, double>>> readWaterIntakeRange({
    required DateTime start,
    required DateTime end,
  });
}
