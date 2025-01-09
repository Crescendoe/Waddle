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
  String? profileImage;
  DateTime? lastResetDate;

  double get getWaterConsumed => waterConsumed;
  double get getWaterGoal => waterGoal;
  int get currentStreak => _currentStreak;
  bool get getGoalMetToday => goalMetToday;
  int get getCompletedChallenges => completedChallenges;
  int get getRecordStreak => recordStreak;
  int get getCompanionsCollected => companionsCollected;
  String? get getUsername => username;
  String? get getProfileImage => profileImage;

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

  void removeLog(WaterLog log) async {
    logs.remove(log);
    if (userId != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('waterLogs')
          .where('entryTime', isEqualTo: log.entryTime.toIso8601String())
          .get();
      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.delete();
      }
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

  void setWaterGoal(double goal) async {
    waterGoal = goal;
    saveWaterData();
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'waterGoal': waterGoal,
      });
    }
    notifyListeners();
  }

  void addWater(double amount) async {
    waterConsumed += amount;
    if (waterConsumed > waterGoal) {
      waterConsumed = waterGoal; // Cap water consumed at the goal
    }
    if (waterConsumed >= waterGoal) {
      goalMetToday = true;
      incrementStreak();
    }
    saveWaterData();
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'waterConsumed': waterConsumed,
        'goalMetToday': goalMetToday,
        'currentStreak': _currentStreak,
        'recordStreak': recordStreak,
      });
    }
    notifyListeners();
  }

  void incrementStreak() async {
    _currentStreak++;
    if (_currentStreak > recordStreak) {
      recordStreak = _currentStreak;
    }
    saveWaterData();
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'currentStreak': _currentStreak,
        'recordStreak': recordStreak,
      });
    }
    notifyListeners();
  }

  void setLogs(List<WaterLog> newLogs) async {
    logs = newLogs;
    if (userId != null) {
      WriteBatch batch = _firestore.batch();
      CollectionReference logCollection =
          _firestore.collection('users').doc(userId).collection('waterLogs');

      // Delete existing logs
      QuerySnapshot snapshot = await logCollection.get();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new logs
      for (WaterLog log in logs) {
        batch.set(logCollection.doc(), log.toMap());
      }

      await batch.commit();
    } else {
      saveWaterData();
    }
    notifyListeners();
  }

  Future<void> loadWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    waterConsumed = prefs.getDouble('waterConsumed') ?? 0.0;
    waterGoal = prefs.getDouble('waterGoal') ?? 0.0;
    goalMetToday = prefs.getBool('goalMetToday') ?? false;
    username = prefs.getString('username');
    profileImage = prefs.getString('profileImage');
    lastResetDate = DateTime.tryParse(prefs.getString('lastResetDate') ?? '');

    if (userId != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _currentStreak = userDoc['currentStreak'] ?? 0;
        recordStreak = userDoc['recordStreak'] ?? 0;
        completedChallenges = userDoc['completedChallenges'] ?? 0;
        companionsCollected = userDoc['companionsCollected'] ?? 0;
        username = userDoc['username'];
        profileImage = userDoc['profileImage'];

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

    resetDailyData();
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
    await prefs.setString('lastResetDate', DateTime.now().toIso8601String());
    if (username != null) {
      await prefs.setString('username', username!);
    }
    if (profileImage != null) {
      await prefs.setString('profileImage', profileImage!);
    }

    if (userId != null) {
      await _firestore.collection('users').doc(userId).set({
        'waterConsumed': waterConsumed,
        'waterGoal': waterGoal,
        'goalMetToday': goalMetToday,
        'currentStreak': _currentStreak,
        'recordStreak': recordStreak,
        'completedChallenges': completedChallenges,
        'companionsCollected': companionsCollected,
        'username': username,
        'profileImage': profileImage,
        'lastResetDate': lastResetDate?.toIso8601String(),
      }, SetOptions(merge: true));

      WriteBatch batch = _firestore.batch();
      CollectionReference logCollection =
          _firestore.collection('users').doc(userId).collection('waterLogs');

      // Delete existing logs
      QuerySnapshot snapshot = await logCollection.get();
      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add new logs
      for (WaterLog log in logs) {
        batch.set(logCollection.doc(), log.toMap());
      }

      await batch.commit();
    }
  }

  void subtractWater(double amount) async {
    waterConsumed -= amount;
    if (waterConsumed < 0) {
      waterConsumed = 0; // Ensure water consumed doesn't go below 0
    }
    if (waterConsumed < waterGoal) {
      goalMetToday = false;
    }
    saveWaterData();
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'waterConsumed': waterConsumed,
        'goalMetToday': goalMetToday,
      });
    }
    notifyListeners();
  }

  void resetWater() async {
    if (!goalMetToday) {
      _currentStreak = 0;
    }
    waterConsumed = 0.0;
    goalMetToday = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('waterConsumed', waterConsumed);
    saveWaterData();
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'waterConsumed': waterConsumed,
        'goalMetToday': goalMetToday,
        'currentStreak': _currentStreak,
      });
    }
    notifyListeners();
  }

  Future<void> updateProfileImage(String path) async {
    profileImage = path;
    saveWaterData();
    if (userId != null) {
      await _firestore.collection('users').doc(userId).update({
        'profileImage': profileImage,
      });
    }
    notifyListeners();
  }

  void setWater(double target) {}

  Future<void> resetDailyData() async {
    DateTime now = DateTime.now();
    if (lastResetDate == null || now.difference(lastResetDate!).inDays >= 1) {
      waterConsumed = 0.0;
      if (!goalMetToday) {
        _currentStreak = 0;
      }
      goalMetToday = false;
      lastResetDate = now;
      saveWaterData();
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'waterConsumed': waterConsumed,
          'goalMetToday': goalMetToday,
          'currentStreak': _currentStreak,
          'lastResetDate': lastResetDate?.toIso8601String(),
        });
      }
      notifyListeners();
    }
  }

  bool isChallengeCompleted(int index) {
    return index == 0;
  }
}

class WaterLog {
  final String drinkName;
  final double amount;
  final double waterContent;
  final DateTime entryTime;

  WaterLog({
    required this.drinkName,
    required this.amount,
    required this.waterContent,
    required this.entryTime,
  });

  Map<String, dynamic> toMap() => {
        'drinkName': drinkName,
        'amount': amount,
        'waterContent': waterContent,
        'entryTime': entryTime.toIso8601String(),
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
