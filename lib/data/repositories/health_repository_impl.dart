import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waddle/core/error/failures.dart';
import 'package:waddle/domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  final SharedPreferences _prefs;
  static const String _syncEnabledKey = 'health_sync_enabled';
  // 1 oz = 29.5735 mL
  static const double _mlPerOz = 29.5735;

  HealthRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    try {
      // Health plugin is available on iOS and Android
      if (!Platform.isAndroid && !Platform.isIOS) {
        return const Right(false);
      }
      return const Right(true);
    } catch (e) {
      return Left(HealthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestPermissions() async {
    try {
      final types = [HealthDataType.WATER];
      final permissions = [HealthDataAccess.READ_WRITE];

      final health = Health();
      await health.configure();
      final granted =
          await health.requestAuthorization(types, permissions: permissions);
      return Right(granted);
    } catch (e) {
      return Left(HealthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isSyncEnabled() async {
    try {
      return Right(_prefs.getBool(_syncEnabledKey) ?? false);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setSyncEnabled(bool enabled) async {
    try {
      await _prefs.setBool(_syncEnabledKey, enabled);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> writeWaterIntake({
    required double amountMl,
    required DateTime dateTime,
  }) async {
    try {
      final syncEnabled = _prefs.getBool(_syncEnabledKey) ?? false;
      if (!syncEnabled) return const Right(null);

      final health = Health();
      await health.configure();

      final success = await health.writeHealthData(
        value: amountMl,
        type: HealthDataType.WATER,
        startTime: dateTime,
        endTime: dateTime.add(const Duration(minutes: 1)),
        unit: HealthDataUnit.MILLILITER,
      );

      if (!success) {
        return const Left(HealthFailure(message: 'Failed to write to Health'));
      }
      return const Right(null);
    } catch (e) {
      return Left(HealthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> readTodayWaterIntake() async {
    try {
      final health = Health();
      await health.configure();

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final data = await health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: startOfDay,
        endTime: now,
      );

      double totalMl = 0;
      for (var point in data) {
        if (point.value is NumericHealthValue) {
          totalMl +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      // Convert mL to oz
      return Right(totalMl / _mlPerOz);
    } catch (e) {
      return Left(HealthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, double>>> readWaterIntakeRange({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final health = Health();
      await health.configure();

      final data = await health.getHealthDataFromTypes(
        types: [HealthDataType.WATER],
        startTime: start,
        endTime: end,
      );

      final Map<DateTime, double> dailyIntake = {};
      for (var point in data) {
        final dayKey = DateTime(
          point.dateFrom.year,
          point.dateFrom.month,
          point.dateFrom.day,
        );
        if (point.value is NumericHealthValue) {
          final ml =
              (point.value as NumericHealthValue).numericValue.toDouble();
          dailyIntake[dayKey] = (dailyIntake[dayKey] ?? 0) + (ml / _mlPerOz);
        }
      }

      return Right(dailyIntake);
    } catch (e) {
      return Left(HealthFailure(message: e.toString()));
    }
  }

  /// Convert oz to mL for health platform
  static double ozToMl(double oz) => oz * _mlPerOz;
}
