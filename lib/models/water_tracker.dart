import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WaterTracker extends ChangeNotifier {
  double waterConsumed = 0;
  double waterGoal = 0;
  int _currentStreak = 0;
  bool goalMetToday = false;
  int completedChallenges = 0;
  int recordStreak = 0;
  int companionsCollected = 0;

  double get getWaterConsumed => waterConsumed;
  double get getWaterGoal => waterGoal;
  int get currentStreak => _currentStreak;
  bool get getGoalMetToday => goalMetToday;
  int get getCompletedChallenges => completedChallenges;
  int get getRecordStreak => recordStreak;
  int get getCompanionsCollected => companionsCollected;

  List<WaterLog> logs = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  WaterTracker({required this.userId}) {
    loadWaterData();
  }

  void addLog(WaterLog log) async {
    logs.add(log);
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('waterLogs')
        .add(log.toMap());
    notifyListeners();
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
    if (waterConsumed >= waterGoal) {
      goalMetToday = true;
      incrementStreak();
    }
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
    goalMetToday = prefs.getBool('goalMetToday') ?? false;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      _currentStreak = userDoc['currentStreak'] ?? 0;
    } else {
      _currentStreak = 0;
    }

    notifyListeners();
  }

  Future<void> saveWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('waterConsumed', waterConsumed);
    await prefs.setDouble('waterGoal', waterGoal);
    await prefs.setBool('goalMetToday', goalMetToday);

    await _firestore.collection('users').doc(userId).set({
      'currentStreak': _currentStreak,
    }, SetOptions(merge: true));
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

bool isChallengeCompleted(int index) {
  return index == 0;
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

  Map<String, dynamic> toMap() => {
        'drinkName': drinkName,
        'amount': amount,
        'waterContent': waterContent,
        'entryTime': entryTime.toIso8601String(), // Convert for Firestore
      };
}
