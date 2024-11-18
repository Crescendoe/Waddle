import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterTracker extends ChangeNotifier {
  double waterConsumed = 0;
  double waterGoal = 0;

  double get getWaterConsumed => waterConsumed;
  double get getWaterGoal => waterGoal;

  get unit => null;

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
