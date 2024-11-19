import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterTracker extends ChangeNotifier {
  double waterConsumed = 0;
  double waterGoal = 0;

  double get getWaterConsumed => waterConsumed;
  double get getWaterGoal => waterGoal;

  get unit => null;

  List<WaterLog> _logs = [];

  void addLog(WaterLog log) {
    _logs.add(log);
  }

  List<WaterLog> getLogsForDay(DateTime day) {
    return _logs
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
    saveWaterData();
    notifyListeners();
  }

  Future<void> loadWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    waterConsumed = prefs.getDouble('waterConsumed') ?? 0.0;
    waterGoal = prefs.getDouble('waterGoal') ?? 0.0;
    notifyListeners();
  }

  Future<void> saveWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('waterConsumed', waterConsumed);
    await prefs.setDouble('waterGoal', waterGoal);
  }

  void resetWater() {
    waterConsumed = 0.0;
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
