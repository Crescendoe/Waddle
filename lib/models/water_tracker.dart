import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterTracker extends ChangeNotifier {
  double waterConsumed = 0;
  double waterGoal = 0;
  int _currentStreak = 0;
  bool goalMetToday = false;

  double get getWaterConsumed => waterConsumed;
  double get getWaterGoal => waterGoal;
  int get currentStreak => _currentStreak; // Add this getter
  bool get getGoalMetToday => goalMetToday;

  List<WaterLog> logs = [];

  void addLog(WaterLog log) {
    logs.add(log);
  }

  List<WaterLog> getLogsForDay(DateTime day) {
    return logs
        .where((log) =>
            log.entryTime.year == day.year &&
            log.entryTime.month == day.month &&
            log.entryTime.day == day.day)
        .toList();
  }

  void setWaterGoal(double goal) {
    waterGoal = goal;
    saveWaterData();
    notifyListeners();
  }

  void addWater(double amount) {
    waterConsumed += amount;
    if (waterConsumed > waterGoal) {
      waterConsumed = waterGoal; // Cap water consumed at the goal
    }
    /*
    if (waterConsumed >= waterGoal) {
      goalMetToday = true;
      _incrementStreak();
    }
    */
    saveWaterData();
    notifyListeners();
  }

  void incrementStreak() {
    if (!goalMetToday) {
      _currentStreak++;
    }
  }

  Future<void> loadWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    waterConsumed = prefs.getDouble('waterConsumed') ?? 0.0;
    waterGoal = prefs.getDouble('waterGoal') ?? 0.0;
    _currentStreak = prefs.getInt('currentStreak') ?? 0;
    goalMetToday = prefs.getBool('goalMetToday') ?? false;
    notifyListeners();
  }

  Future<void> saveWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('waterConsumed', waterConsumed);
    await prefs.setDouble('waterGoal', waterGoal);
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setBool('goalMetToday', goalMetToday);
  }

  void resetWater() {
    if (!goalMetToday) {
      _currentStreak = 0;
    }
    waterConsumed = 0.0;
    goalMetToday = false;
    saveWaterData();
    notifyListeners();
  }

  void setWater(double target) {}
}

class WaterLog {
  final String drinkName;
  final double amount; // in ounces or cups
  final double waterContent; // as a percentage
  final DateTime entryTime;

  WaterLog(
      {required this.drinkName,
      required this.amount,
      required this.waterContent,
      required this.entryTime});
}
