import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';

class WaterTracker extends ChangeNotifier {
  double waterConsumed = 0.0;
  double waterGoal = 0.0;
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
  int? activeChallengeIndex;
  bool challenge1Active = false;
  bool challenge2Active = false;
  bool challenge3Active = false;
  bool challenge4Active = false;
  bool challenge5Active = false;
  bool challenge6Active = false;
  DateTime? _lastLogTime;
  bool challengeFailed = false;
  bool challengeCompleted = false;
  int daysLeft = 14;
  bool notificationsEnabled = false;
  String userId = '';
  bool _isLoading =
      false; // Added to track loading state, crucial for UI updates

  //Getter methods
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
  bool get isLoading => _isLoading; // Expose the loading state to the UI.

  //Setter methods
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
    // Removed loadWaterData() from the constructor.
    _initialize(); // Call initialize
  }

  WaterTracker.withNotifications({
    required this.notificationsEnabled,
    this.notificationTime,
    this.notificationInterval,
    required this.userId,
  }) {
    // Removed loadWaterData() from the constructor.
    _initialize(); // Call initialize
  }

  // Initialization method.  This should be called instead of calling loadWaterData() in the constructor.
  Future<void> _initialize() async {
    _isLoading =
        true; // Set loading to true *before* starting the async operation
    notifyListeners(); // Notify listeners to show loading state in UI

    await loadWaterData(); // Await the loading of data
    if (kDebugMode) {
      printFirestoreVariables();
    }
    loadNotificationSettings();
    scheduleDailyReset();
    await checkAndResetDailyData(); // Await
    _isLoading =
        false; // Set loading to false *after* data is loaded.  Crucial!
    notifyListeners(); // Notify listeners to update UI with loaded data
  }

  Future<void> handleFirebaseAuthError(FirebaseAuthException e) async {
    _logger.e('FirebaseAuth Error: ${e.message}');
    switch (e.code) {
      case 'user-not-found':
        _logger.e('No user found for that email.');
        break;
      case 'wrong-password':
        _logger.e('Wrong password provided.');
        break;
      default:
        _logger.e('An undefined Error happened.');
    }
  }

  Future<void> updateFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        DocumentReference userDocRef = _firestore.collection('users').doc(uid);

        await userDocRef.set(
          {
            'waterConsumed': waterConsumed,
            'waterGoal': waterGoal,
            'goalMetToday': goalMetToday,
            'currentStreak': _currentStreak,
            'recordStreak': recordStreak,
            'completedChallenges': completedChallenges,
            'companionsCollected': companionsCollected,
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
          SetOptions(merge: true),
        );
      } catch (e) {
        _logger.e('Error updating Firestore: $e');
      }
    }
  }

  void addLog(WaterLog log) async {
    if (_lastLogTime != null &&
        DateTime.now().difference(_lastLogTime!).inSeconds < 60) {
      return;
    }
    _lastLogTime = DateTime.now();

    logs.add(log);
    waterConsumed += log.amount;
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void logDrink(BuildContext context, String drinkName, double amount,
      double waterContent) async {
    if (_lastLogTime != null &&
        DateTime.now().difference(_lastLogTime!).inSeconds < 60) {
      _logger.w('Duplicate log prevented: $drinkName, $amount');
      return;
    }

    final log = WaterLog(
      drinkName: drinkName,
      amount: amount,
      waterContent: waterContent,
      entryTime: DateTime.now(),
    );

    addLog(log);

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

      await updateFirestore();
    }

    _lastLogTime = DateTime.now();
  }

  void removeLog(WaterLog log) async {
    logs.remove(log);
    waterConsumed -= log.amount;
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void resetEntryTimer() {
    nextEntryTime = null;
    saveWaterData();
    notifyListeners();
  }

  Future<void> setWaterGoal(double goal) async {
    waterGoal = goal;
    resetEntryTimer();
    if (waterConsumed >= waterGoal) {
      goalMetToday = false;
    }
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
      await flutterLocalNotificationsPlugin.cancelAll();
      if (context.mounted) {
        checkGoalMet(context);
      }
    }
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  Future<void> incrementWaterConsumed(double amount) async {
    _logger.i(
        'incrementWaterConsumed called with amount: $amount, current waterConsumed: $waterConsumed, target: ${waterConsumed + amount}');
    double target = waterConsumed + amount;
    int initialDuration = 50;
    int currentDuration = initialDuration;

    if (target <= waterConsumed) {
      _logger.w(
          'Target is less than or equal to current waterConsumed. Adjusting target to ${waterConsumed + 1}');
      target = waterConsumed + 1;
    }

    Future<void> incrementWater() async {
      if (waterConsumed < target && waterConsumed < waterGoal) {
        await Future.delayed(Duration(milliseconds: currentDuration));
        waterConsumed += 1;
        _logger.i(
            'Incrementing waterConsumed: $waterConsumed, currentDuration: $currentDuration');
        currentDuration = max((currentDuration * 1.03).toInt(), 20);
        notifyListeners(); // Notify within the loop for visual updates
        await incrementWater();
      } else {
        waterConsumed = min(target, waterGoal);
        if (waterConsumed >= waterGoal && !goalMetToday) {
          goalMetToday = true;
          incrementStreak();
        }
        _logger.i('Final waterConsumed: $waterConsumed');
        await updateFirestore();
        saveWaterData();
        notifyListeners(); // Final notification
      }
    }

    await incrementWater();
  }

  void incrementStreak() async {
    if (_currentStreak == 0) {
      _currentStreak = 1;
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
    await updateFirestore();
    saveWaterData();
    notifyListeners();
  }

  void resetWater() async {
    if (!goalMetToday) {
      _currentStreak = 0;
    }
    waterConsumed = 0.0;
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
    await updateFirestore();
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
      await resetDailyData();
    }
  }

  Future<void> loadWaterData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          // Update local WaterTracker variables with Firestore data
          waterConsumed = (userDoc['waterConsumed'] as num?)?.toDouble() ?? 0.0;
          waterGoal = (userDoc['waterGoal'] as num?)?.toDouble() ?? 0.0;
          goalMetToday = userDoc['goalMetToday'] ?? false;
          _currentStreak = userDoc['currentStreak'] ?? 0;
          recordStreak = userDoc['recordStreak'] ?? 0;
          completedChallenges = userDoc['completedChallenges'] ?? 0;
          companionsCollected = userDoc['companionsCollected'] ?? 0;
          profileImage = userDoc['profileImage'];
          nextEntryTime = userDoc['nextEntryTime'] != null
              ? DateTime.parse(userDoc['nextEntryTime'])
              : null;
          activeChallengeIndex = userDoc['activeChallengeIndex'];
          challenge1Active = userDoc['challenge1Active'] ?? false;
          challenge2Active = userDoc['challenge2Active'] ?? false;
          challenge3Active = userDoc['challenge3Active'] ?? false;
          challenge4Active = userDoc['challenge4Active'] ?? false;
          challenge5Active = userDoc['challenge5Active'] ?? false;
          challenge6Active = userDoc['challenge6Active'] ?? false;
          challengeFailed = userDoc['challengeFailed'] ?? false;
          challengeCompleted = userDoc['challengeCompleted'] ?? false;
          daysLeft = userDoc['daysLeft'] ?? 14;
          username = userDoc['username'] ?? username;
          lastResetDate = userDoc['lastResetDate'] != null
              ? DateTime.parse(userDoc['lastResetDate'])
              : null;
          //notification
          String? notificationTimeString = userDoc['notificationTime'];
          if (notificationTimeString != null) {
            List<String> parts = notificationTimeString.split(':');
            notificationTime = TimeOfDay(
                hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          notificationInterval = userDoc['notificationInterval'];

          if (kDebugMode) {
            _logger.i(
                'Successfully loaded data from Firestore for user: $uid'); //success
          }
        } else {
          _logger.w('No Firestore document found for user: $uid'); // no data
        }
      } catch (e) {
        _logger.e('Error loading data from Firestore: $e'); //error
      }
    } else {
      _logger.w('No authenticated user found.'); //no user
    }
  }

  Future<void> saveWaterData({bool updateLastResetDate = true}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('waterConsumed', waterConsumed);
    await prefs.setDouble('waterGoal', waterGoal);
    await prefs.setBool('goalMetToday', goalMetToday);
    await prefs.setInt('currentStreak', _currentStreak);
    await prefs.setInt('recordStreak', recordStreak);
    await prefs.setInt('completedChallenges', completedChallenges);
    await prefs.setInt('companionsCollected', companionsCollected);
    if (updateLastResetDate) {
      await prefs.setString('lastResetDate', DateTime.now().toIso8601String());
    }
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
      CollectionReference logCollection =
          _firestore.collection('users').doc(uid).collection('waterLogs');

      try {
        for (WaterLog log in logs) {
          QuerySnapshot snapshot = await logCollection
              .where('entryTime', isEqualTo: log.entryTime.toIso8601String())
              .get();

          if (snapshot.docs.isNotEmpty) {
            await logCollection.doc(snapshot.docs.first.id).update(log.toMap());
          } else {
            await logCollection.add(log.toMap());
          }
        }
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
    activeChallengeIndex = null;
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
        scheduleDailyReset();
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
