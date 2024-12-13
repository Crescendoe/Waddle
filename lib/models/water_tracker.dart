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
  String? username;
  String? profileImage; // Changed from _profileImage to profileImage

  double get getWaterConsumed => waterConsumed;
  double get getWaterGoal => waterGoal;
  int get currentStreak => _currentStreak;
  bool get getGoalMetToday => goalMetToday;
  int get getCompletedChallenges => completedChallenges;
  int get getRecordStreak => recordStreak;
  int get getCompanionsCollected => companionsCollected;
  String? get getUsername => username;
  String? get getProfileImage =>
      profileImage; // Changed from _profileImage to profileImage

  List<WaterLog> logs = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId;

  WaterTracker({this.userId, this.username}) {
    loadWaterData();
  }

  void addLog(WaterLog log) async {
    logs.add(log);
    if (userId != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .add(log.toMap());
    } else {
      saveWaterData();
    }
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
      if (_currentStreak > recordStreak) {
        recordStreak = _currentStreak;
      }
    }
  }

  void setLogs(List<WaterLog> newLogs) {
    logs = newLogs;
    notifyListeners();
  }

  Future<void> loadWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    waterConsumed = prefs.getDouble('waterConsumed') ?? 0.0;
    waterGoal = prefs.getDouble('waterGoal') ?? 0.0;
    goalMetToday = prefs.getBool('goalMetToday') ?? false;
    username = prefs.getString('username');

    if (userId != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _currentStreak = userDoc['currentStreak'] ?? 0;
        recordStreak = userDoc['recordStreak'] ?? 0;
        completedChallenges = userDoc['completedChallenges'] ?? 0;
        companionsCollected = userDoc['companionsCollected'] ?? 0;
        username = userDoc['username'];

        QuerySnapshot logSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('waterLogs')
            .get();
        logs = logSnapshot.docs
            .map((doc) => WaterLog.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        _currentStreak = 0;
        recordStreak = 0;
        completedChallenges = 0;
        companionsCollected = 0;
      }
    } else {
      _currentStreak = prefs.getInt('currentStreak') ?? 0;
      recordStreak = prefs.getInt('recordStreak') ?? 0;
      completedChallenges = prefs.getInt('completedChallenges') ?? 0;
      companionsCollected = prefs.getInt('companionsCollected') ?? 0;
    }

    notifyListeners();
  }

  Future<void> saveWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('waterConsumed', waterConsumed);
    await prefs.setDouble('waterGoal', waterGoal);
    await prefs.setBool('goalMetToday', goalMetToday);
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('recordStreak', recordStreak);
    await prefs.setInt('completedChallenges', completedChallenges);
    await prefs.setInt('companionsCollected', companionsCollected);
    if (username != null) {
      await prefs.setString('username', username!);
    }

    if (userId != null) {
      await _firestore.collection('users').doc(userId).set({
        'currentStreak': _currentStreak,
        'recordStreak': recordStreak,
        'completedChallenges': completedChallenges,
        'companionsCollected': companionsCollected,
        'username': username,
      }, SetOptions(merge: true));

      for (WaterLog log in logs) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('waterLogs')
            .add(log.toMap());
      }
    }
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

  Future<void> updateProfileImage(String path) async {
    profileImage = path; // Changed from _profileImage to profileImage

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

  factory WaterLog.fromMap(Map<String, dynamic> map) {
    return WaterLog(
      drinkName: map['drinkName'],
      amount: map['amount'],
      waterContent: map['waterContent'],
      entryTime: DateTime.parse(map['entryTime']),
    );
  }
}
