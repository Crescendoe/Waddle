import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';

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
  DateTime? nextEntryTime;
  TimeOfDay? notificationTime;
  int? notificationInterval;
  int? activeChallengeIndex; // Ensure default state is null
  bool challenge1Active = false;
  bool challenge2Active = false;
  bool challenge3Active = false;
  bool challenge4Active = false;
  bool challenge5Active = false;
  bool challenge6Active = false;
  DateTime? _lastLogTime; // Add a variable to track the last log time
  bool challengeFailed = false;
  bool challengeCompleted = false;
  int daysLeft = 14;

  double get getWaterConsumed => waterConsumed;
  double get getWaterGoal => waterGoal;
  int get currentStreak => _currentStreak;
  bool get getGoalMetToday => goalMetToday;
  int get getCompletedChallenges => completedChallenges;
  int get getRecordStreak => recordStreak;
  int get getCompanionsCollected => companionsCollected;
  String? get getUsername => username;
  String? get getProfileImage => profileImage;
  DateTime? get getNextEntryTime => nextEntryTime;
  int? get getActiveChallengeIndex => activeChallengeIndex;
  bool get getChallenge1Active => challenge1Active;
  bool get getChallenge2Active => challenge2Active;
  bool get getChallenge3Active => challenge3Active;
  bool get getChallenge4Active => challenge4Active;
  bool get getChallenge5Active => challenge5Active;
  bool get getChallenge6Active => challenge6Active;

  set setActiveChallengeIndex(int? index) {
    activeChallengeIndex = index;
    notifyListeners();
    saveWaterData();
    updateFirestore();
  }

  List<WaterLog> logs = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  WaterTracker({this.username}) {
    loadWaterData();
    printFirestoreVariables();
    loadNotificationSettings();
    scheduleDailyReset(); // Schedule the daily reset
    checkAndResetDailyData(); // Check and reset daily data on initialization
  }

  Future<void> updateFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        WriteBatch batch = _firestore.batch();
        DocumentReference userDocRef = _firestore.collection('users').doc(uid);

        batch.set(
            userDocRef,
            {
              'waterConsumed': waterConsumed,
              'waterGoal': waterGoal,
              'goalMetToday': goalMetToday,
              'currentStreak': _currentStreak,
              'recordStreak': recordStreak,
              'completedChallenges': completedChallenges,
              'companionsCollected': companionsCollected,
              'username': username ?? user.displayName ?? user.email,
              'profileImage': profileImage,
              'lastResetDate': lastResetDate?.toIso8601String(),
              'nextEntryTime': nextEntryTime?.toIso8601String(),
              'notificationTime': notificationTime != null
                  ? '${notificationTime!.hour}:${notificationTime!.minute}'
                  : null,
              'notificationInterval': notificationInterval,
              'activeChallengeIndex': activeChallengeIndex,
              'challenge1Active': challenge1Active,
              'challenge2Active': challenge2Active,
              'challenge3Active': challenge3Active,
              'challenge4Active': challenge4Active,
              'challenge5Active': challenge5Active,
              'challenge6Active': challenge6Active,
              'daysLeft': daysLeft,
            },
            SetOptions(merge: true));

        // Update water logs in Firestore
        CollectionReference logCollection = userDocRef.collection('waterLogs');
        QuerySnapshot snapshot = await logCollection.get();
        for (DocumentSnapshot doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        for (WaterLog log in logs) {
          batch.set(logCollection.doc(), log.toMap());
        }

        await batch.commit();
      } catch (e) {
        _logger.e('Error updating Firestore: $e');
      }
    }
  }

  void addLog(WaterLog log) async {
    // Check if the last log was added within the last minute
    if (_lastLogTime != null &&
        DateTime.now().difference(_lastLogTime!).inSeconds < 60) {
      return; // Prevent adding the log if it was added within the last minute
    }
    _lastLogTime = DateTime.now(); // Update the last log time

    logs.add(log);
    waterConsumed += log.amount; // Ensure waterConsumed is updated correctly
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void logDrink(BuildContext context, String drinkName, double amount,
      double waterContent) async {
    final log = WaterLog(
      drinkName: drinkName,
      amount: amount,
      waterContent: waterContent,
      entryTime: DateTime.now(),
    );

    addLog(
        log); // Use addLog method to ensure waterConsumed is updated correctly

    // Send log to Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final logData = {
        'drinkName': drinkName,
        'amount': amount,
        'waterContent': waterContent,
        'entryTime': log.entryTime.toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('waterLogs')
          .add(logData);

      // Update Firestore with the new water consumption
      await updateFirestore();
    }
  }

  void removeLog(WaterLog log) async {
    logs.remove(log);
    waterConsumed -= log.amount; // Ensure waterConsumed is updated correctly
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void resetEntryTimer() {
    nextEntryTime = null;
    saveWaterData();
    notifyListeners();
  }

  void setWaterGoal(double goal) async {
    waterGoal = goal;
    resetEntryTimer(); // Reset entry timer when water goal is changed
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void addWater(BuildContext context, double amount) async {
    waterConsumed += amount;
    if (waterConsumed > waterGoal) {
      waterConsumed = waterGoal;
    }
    if (waterConsumed >= waterGoal) {
      goalMetToday = true;
      incrementStreak();
      await flutterLocalNotificationsPlugin.cancelAll(); // Cancel notifications
      if (context.mounted) {
        checkGoalMet(
            context); // Check if goal is met and navigate to congrats screen
      }
    }
    await updateFirestore(); // Update Firestore
    saveWaterData();
    notifyListeners();
  }

  void incrementWaterConsumed(double amount) {
    double target = waterConsumed + amount;
    int duration = 50;

    void incrementWater() {
      Timer(Duration(milliseconds: duration), () {
        if (waterConsumed < target && waterConsumed < waterGoal) {
          waterConsumed += 1;
          duration = max((duration * 1.03).toInt(), 20);
          incrementWater();
        } else if (waterConsumed >= waterGoal) {
          if (!goalMetToday) {
            goalMetToday = true;
            incrementStreak();
          }
        }
        notifyListeners();
      });
    }

    incrementWater();
  }

  void incrementStreak() async {
    if (_currentStreak == 0) {
      _currentStreak = 1; // Start the streak from 1
    } else {
      _currentStreak++;
    }
    if (_currentStreak > recordStreak) {
      recordStreak = _currentStreak;
    }
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void subtractWater(double amount) async {
    waterConsumed -= amount;
    if (waterConsumed < 0) {
      waterConsumed = 0;
    }
    if (waterConsumed < waterGoal) {
      goalMetToday = false;
    }
    await updateFirestore(); // Update Firestore
    saveWaterData();
    notifyListeners();
  }

  void resetWater() async {
    if (!goalMetToday) {
      _currentStreak = 0;
    }
    waterConsumed = 0.0; // Reset waterConsumed to 0
    goalMetToday = false;
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  Future<void> updateProfileImage(String path) async {
    profileImage = path;
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  Future<void> setWater(double amount) async {
    waterConsumed = amount;
    if (waterConsumed >= waterGoal) {
      goalMetToday = true;
      incrementStreak();
    }
    await updateFirestore(); // Update Firestore
    saveWaterData();
    notifyListeners();
  }

  Future<void> resetDailyData() async {
    DateTime now = DateTime.now();
    if (lastResetDate == null || now.difference(lastResetDate!).inDays >= 1) {
      if (!goalMetToday) {
        _currentStreak = 0;
      }
      waterConsumed = 0.0;
      goalMetToday = false;
      lastResetDate = now;
      await updateFirestore();
      saveWaterData();
      notifyListeners();
    }
  }

  Future<void> checkAndResetDailyData() async {
    DateTime now = DateTime.now();
    if (lastResetDate == null || now.difference(lastResetDate!).inDays >= 1) {
      if (!goalMetToday) {
        _currentStreak = 0;
      }
      waterConsumed = 0.0;
      goalMetToday = false;
      lastResetDate = now;
      await updateFirestore();
      saveWaterData();
      notifyListeners();
    }
  }

  Future<void> loadWaterData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    waterConsumed = prefs.getDouble('waterConsumed') ?? 0.0;
    waterGoal = prefs.getDouble('waterGoal') ?? 0.0;
    goalMetToday = prefs.getBool('goalMetToday') ?? false;
    username = prefs.getString('username');
    profileImage = prefs.getString('profileImage');
    lastResetDate = DateTime.tryParse(prefs.getString('lastResetDate') ?? '');
    nextEntryTime = DateTime.tryParse(prefs.getString('nextEntryTime') ?? '');
    String? notificationTimeString = prefs.getString('notificationTime');
    if (notificationTimeString != null) {
      List<String> parts = notificationTimeString.split(':');
      notificationTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    notificationInterval = prefs.getInt('notificationInterval');
    activeChallengeIndex = prefs.getInt('activeChallengeIndex');
    // Ensure activeChallengeIndex is null by default
    activeChallengeIndex ??= null;
    challenge1Active = prefs.getBool('challenge1Active') ?? false;
    challenge2Active = prefs.getBool('challenge2Active') ?? false;
    challenge3Active = prefs.getBool('challenge3Active') ?? false;
    challenge4Active = prefs.getBool('challenge4Active') ?? false;
    challenge5Active = prefs.getBool('challenge5Active') ?? false;
    challenge6Active = prefs.getBool('challenge6Active') ?? false;
    challengeFailed = prefs.getBool('challengeFailed') ?? false;
    challengeCompleted = prefs.getBool('challengeCompleted') ?? false;
    daysLeft = prefs.getInt('daysLeft') ?? 14;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          waterConsumed = userDoc['waterConsumed'] ?? waterConsumed;
          waterGoal = userDoc['waterGoal'] ?? waterGoal;
          goalMetToday = userDoc['goalMetToday'] ?? goalMetToday;
          _currentStreak = userDoc['currentStreak'] ?? _currentStreak;
          recordStreak = userDoc['recordStreak'] ?? recordStreak;
          completedChallenges =
              userDoc['completedChallenges'] ?? completedChallenges;
          companionsCollected =
              userDoc['companionsCollected'] ?? companionsCollected;
          username = userDoc['username'] ?? username;
          profileImage = userDoc['profileImage'] ?? profileImage;
          nextEntryTime = userDoc['nextEntryTime']?.toDate() ?? nextEntryTime;
          activeChallengeIndex = userDoc['activeChallengeIndex'];
          challenge1Active = userDoc['challenge1Active'] ?? false;
          challenge2Active = userDoc['challenge2Active'] ?? false;
          challenge3Active = userDoc['challenge3Active'] ?? false;
          challenge4Active = userDoc['challenge4Active'] ?? false;
          challenge5Active = userDoc['challenge5Active'] ?? false;
          challenge6Active = userDoc['challenge6Active'] ?? false;

          QuerySnapshot logSnapshot = await _firestore
              .collection('users')
              .doc(uid)
              .collection('waterLogs')
              .get();
          logs = logSnapshot.docs
              .map(
                  (doc) => WaterLog.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        _logger.e('Error loading data from Firestore: $e');
      }
    } else {
      _currentStreak = prefs.getInt('currentStreak') ?? 0;
      recordStreak = prefs.getInt('recordStreak') ?? 0;
      completedChallenges = prefs.getInt('completedChallenges') ?? 0;
      companionsCollected = prefs.getInt('companionsCollected') ?? 0;
    }

    checkAndResetDailyData(); // Check and reset daily data after loading
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
    if (nextEntryTime != null) {
      await prefs.setString('nextEntryTime', nextEntryTime!.toIso8601String());
    }
    if (notificationTime != null) {
      await prefs.setString('notificationTime',
          '${notificationTime!.hour}:${notificationTime!.minute}');
    }
    if (notificationInterval != null) {
      await prefs.setInt('notificationInterval', notificationInterval!);
    }
    if (activeChallengeIndex != null) {
      await prefs.setInt('activeChallengeIndex', activeChallengeIndex!);
    } else {
      await prefs.remove('activeChallengeIndex');
    }
    await prefs.setBool('challenge1Active', challenge1Active);
    await prefs.setBool('challenge2Active', challenge2Active);
    await prefs.setBool('challenge3Active', challenge3Active);
    await prefs.setBool('challenge4Active', challenge4Active);
    await prefs.setBool('challenge5Active', challenge5Active);
    await prefs.setBool('challenge6Active', challenge6Active);
    await prefs.setBool('challengeFailed', challengeFailed);
    await prefs.setBool('challengeCompleted', challengeCompleted);
    await prefs.setInt('daysLeft', daysLeft);

    await updateFirestore();
  }

  // method called getLogsForDay that returns a list of WaterLog objects for a given day
  List<WaterLog> getLogsForDay(DateTime day) {
    return logs
        .where((log) =>
            log.entryTime.year == day.year &&
            log.entryTime.month == day.month &&
            log.entryTime.day == day.day)
        .toList();
  }

  void setLogs(List<WaterLog> newLogs) async {
    logs = newLogs;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      WriteBatch batch = _firestore.batch();
      CollectionReference logCollection =
          _firestore.collection('users').doc(uid).collection('waterLogs');

      try {
        QuerySnapshot snapshot = await logCollection.get();
        for (DocumentSnapshot doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        for (WaterLog log in logs) {
          batch.set(logCollection.doc(), log.toMap());
        }

        await batch.commit();
      } catch (e) {
        _logger.e('Error setting logs in Firestore: $e');
      }
    } else {
      saveWaterData();
    }
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void printFirestoreVariables() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          _logger.i('Firestore Variables:');
          _logger.i('waterConsumed: ${userDoc['waterConsumed']}');
          _logger.i('waterGoal: ${userDoc['waterGoal']}');
          _logger.i('goalMetToday: ${userDoc['goalMetToday']}');
          _logger.i('currentStreak: ${userDoc['currentStreak']}');
          _logger.i('recordStreak: ${userDoc['recordStreak']}');
          _logger.i('completedChallenges: ${userDoc['completedChallenges']}');
          _logger.i('companionsCollected: ${userDoc['companionsCollected']}');
          _logger.i('username: ${userDoc['username']}');
          _logger.i('profileImage: ${userDoc['profileImage']}');
          _logger.i('lastResetDate: ${userDoc['lastResetDate']}');
          _logger.i('nextEntryTime: ${userDoc['nextEntryTime']}');
        }
      } catch (e) {
        _logger.e('Error printing Firestore variables: $e');
      }
    }
  }

  Future<void> loadNotificationSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          String? notificationTimeString = userDoc['notificationTime'];
          if (notificationTimeString != null) {
            List<String> parts = notificationTimeString.split(':');
            notificationTime = TimeOfDay(
                hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          notificationInterval = userDoc['notificationInterval'];
        }
      } catch (e) {
        _logger.e('Error loading notification settings from Firestore: $e');
      }
    }
  }

  Future<void> startChallenge(int index) async {
    activeChallengeIndex = index;
    switch (index) {
      case 0:
        challenge1Active = true;
        break;
      case 1:
        challenge2Active = true;
        break;
      case 2:
        challenge3Active = true;
        break;
      case 3:
        challenge4Active = true;
        break;
      case 4:
        challenge5Active = true;
        break;
      case 5:
        challenge6Active = true;
        break;
    }
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  Future<void> resetChallenge() async {
    activeChallengeIndex = null; // Reset to null
    challenge1Active = false;
    challenge2Active = false;
    challenge3Active = false;
    challenge4Active = false;
    challenge5Active = false;
    challenge6Active = false;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        await _firestore.collection('users').doc(uid).update({
          'activeChallengeIndex': null,
          'challenge1Active': false,
          'challenge2Active': false,
          'challenge3Active': false,
          'challenge4Active': false,
          'challenge5Active': false,
          'challenge6Active': false,
        });
      } catch (e) {
        _logger.e('Error resetting Firestore variables: $e');
      }
    }

    await saveWaterData();
    notifyListeners();
  }

  Future<void> checkChallengeState() async {
    if (activeChallengeIndex != null) {
      if (!goalMetToday) {
        challengeFailed = true;
        await resetChallenge();
      } else {
        daysLeft--;
        if (daysLeft <= 0) {
          challengeCompleted = true;
          await completeChallenge();
        }
      }
      await updateFirestore();
      saveWaterData();
      notifyListeners();
    }
  }

  Future<void> completeChallenge() async {
    switch (activeChallengeIndex) {
      case 0:
        challenge1Active = false;
        break;
      case 1:
        challenge2Active = false;
        break;
      case 2:
        challenge3Active = false;
        break;
      case 3:
        challenge4Active = false;
        break;
      case 4:
        challenge5Active = false;
        break;
      case 5:
        challenge6Active = false;
        break;
    }
    activeChallengeIndex = null;
    challengeCompleted = false;
    daysLeft = 14;
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void scheduleDailyReset() {
    Timer.periodic(Duration(days: 1), (timer) {
      DateTime now = DateTime.now();
      DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1);
      Duration timeUntilMidnight = nextMidnight.difference(now);

      Timer(timeUntilMidnight, () async {
        await resetDailyData();
        scheduleDailyReset(); // Reschedule the next reset
      });
    });
  }

  void checkGoalMet(BuildContext context) {
    if (waterConsumed >= waterGoal) {
      try {
        Navigator.pushNamed(context, '/congrats');
      } catch (e) {
        _logger.e('Error navigating to congrats screen: $e');
      }
    }
  }

  static const SocialPlatform platform = SocialPlatform.facebook;

  Future<void> shareProfileScreenshot(String imagePath) async {
    await SocialSharingPlus.shareToSocialMedia(
      platform,
      'Check out my profile on WWaddle!',
      media: imagePath,
      isOpenBrowser: true,
    );
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
