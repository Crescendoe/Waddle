import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/error/failures.dart';
import 'package:waddle/domain/entities/daily_quest.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/shop_item.dart';
import 'package:waddle/domain/entities/water_log.dart';
import 'package:waddle/domain/repositories/hydration_repository.dart';

class HydrationRepositoryImpl implements HydrationRepository {
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  HydrationRepositoryImpl({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _firestore = firestore,
        _prefs = prefs;

  DocumentReference _userDoc(String userId) =>
      _firestore.collection(AppConstants.usersCollection).doc(userId);

  CollectionReference _logsCollection(String userId) =>
      _userDoc(userId).collection(AppConstants.waterLogsSubcollection);

  /// Safely parse a DateTime from Firestore (could be Timestamp, String, or null)
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Future<Either<Failure, HydrationState>> loadHydrationState(
      String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      if (!doc.exists) {
        return const Right(HydrationState());
      }

      final data = doc.data() as Map<String, dynamic>? ?? {};

      final state = HydrationState(
        waterConsumedOz: (data['waterConsumed'] as num?)?.toDouble() ?? 0.0,
        waterGoalOz: (data['waterGoal'] as num?)?.toDouble() ??
            AppConstants.defaultWaterGoalOz,
        currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
        recordStreak: (data['recordStreak'] as num?)?.toInt() ?? 0,
        goalMetToday: data['goalMetToday'] as bool? ?? false,
        completedChallenges:
            (data['completedChallenges'] as num?)?.toInt() ?? 0,
        companionsCollected:
            (data['companionsCollected'] as num?)?.toInt() ?? 0,
        lastResetDate: _parseDateTime(data['lastResetDate']),
        nextEntryTime: _parseDateTime(data['nextEntryTime']),
        activeChallengeIndex: data['activeChallengeIndex'] as int?,
        challengeActive: [
          data['challenge1Active'] as bool? ?? false,
          data['challenge2Active'] as bool? ?? false,
          data['challenge3Active'] as bool? ?? false,
          data['challenge4Active'] as bool? ?? false,
          data['challenge5Active'] as bool? ?? false,
          data['challenge6Active'] as bool? ?? false,
        ],
        challengeFailed: data['challengeFailed'] as bool? ?? false,
        challengeCompleted: data['challengeCompleted'] as bool? ?? false,
        challengeDaysLeft: (data['daysLeft'] as num?)?.toInt() ?? 14,
        // Lifetime / rewards stats
        totalWaterConsumedOz:
            (data['totalWaterConsumed'] as num?)?.toDouble() ?? 0.0,
        totalDaysLogged: (data['totalDaysLogged'] as num?)?.toInt() ?? 0,
        totalDrinksLogged: (data['totalDrinksLogged'] as num?)?.toInt() ?? 0,
        totalHealthyPicks: (data['totalHealthyPicks'] as num?)?.toInt() ?? 0,
        uniqueDrinksLogged: (data['uniqueDrinksLogged'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        totalGoalsMet: (data['totalGoalsMet'] as num?)?.toInt() ?? 0,
        activeThemeId: data['activeThemeId'] as String?,
        activeDuckIndex: (data['activeDuckIndex'] as num?)?.toInt(),
        cupDuckIndex: (data['cupDuckIndex'] as num?)?.toInt(),
        homeDuckIndices: (data['homeDuckIndices'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        // XP & Leveling
        totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
        // Currency
        drops: (data['drops'] as num?)?.toInt() ?? 0,
        // Daily Quests
        dailyQuests: (data['dailyQuests'] as List<dynamic>?)
                ?.map((e) => DailyQuestProgress.fromMap(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        dailyQuestsDate: data['dailyQuestsDate'] as String?,
        // Inventory
        inventory: data['inventory'] != null
            ? UserInventory.fromMap(
                Map<String, dynamic>.from(data['inventory'] as Map))
            : const UserInventory(),
        // Seen unlock rewards
        seenDuckIndices: (data['seenDuckIndices'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
        seenThemeIds: (data['seenThemeIds'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

      // Cache locally
      _cacheState(state);

      return Right(state);
    } on FirebaseException catch (e) {
      // Fallback to local cache
      final cached = _loadCachedState();
      if (cached != null) return Right(cached);
      return Left(ServerFailure(message: e.message ?? 'Failed to load data'));
    } catch (e) {
      final cached = _loadCachedState();
      if (cached != null) return Right(cached);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveHydrationState(
      String userId, HydrationState state) async {
    try {
      await _userDoc(userId).set({
        'waterConsumed': state.waterConsumedOz,
        'waterGoal': state.waterGoalOz,
        'currentStreak': state.currentStreak,
        'recordStreak': state.recordStreak,
        'goalMetToday': state.goalMetToday,
        'completedChallenges': state.completedChallenges,
        'companionsCollected': state.companionsCollected,
        'lastResetDate': state.lastResetDate != null
            ? Timestamp.fromDate(state.lastResetDate!)
            : null,
        'nextEntryTime': state.nextEntryTime != null
            ? Timestamp.fromDate(state.nextEntryTime!)
            : null,
        'activeChallengeIndex': state.activeChallengeIndex,
        'challenge1Active':
            state.challengeActive.length > 0 ? state.challengeActive[0] : false,
        'challenge2Active':
            state.challengeActive.length > 1 ? state.challengeActive[1] : false,
        'challenge3Active':
            state.challengeActive.length > 2 ? state.challengeActive[2] : false,
        'challenge4Active':
            state.challengeActive.length > 3 ? state.challengeActive[3] : false,
        'challenge5Active':
            state.challengeActive.length > 4 ? state.challengeActive[4] : false,
        'challenge6Active':
            state.challengeActive.length > 5 ? state.challengeActive[5] : false,
        'challengeFailed': state.challengeFailed,
        'challengeCompleted': state.challengeCompleted,
        'daysLeft': state.challengeDaysLeft,
        // Lifetime / rewards stats
        'totalWaterConsumed': state.totalWaterConsumedOz,
        'totalDaysLogged': state.totalDaysLogged,
        'totalDrinksLogged': state.totalDrinksLogged,
        'totalHealthyPicks': state.totalHealthyPicks,
        'uniqueDrinksLogged': state.uniqueDrinksLogged,
        'totalGoalsMet': state.totalGoalsMet,
        'activeThemeId': state.activeThemeId,
        'activeDuckIndex': state.activeDuckIndex,
        'cupDuckIndex': state.cupDuckIndex,
        'homeDuckIndices': state.homeDuckIndices,
        // XP & Leveling
        'totalXp': state.totalXp,
        // Currency
        'drops': state.drops,
        // Daily Quests
        'dailyQuests': state.dailyQuests.map((q) => q.toMap()).toList(),
        'dailyQuestsDate': state.dailyQuestsDate,
        // Inventory
        'inventory': state.inventory.toMap(),
        // Seen unlock rewards
        'seenDuckIndices': state.seenDuckIndices,
        'seenThemeIds': state.seenThemeIds,
      }, SetOptions(merge: true));

      _cacheState(state);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addWaterLog(String userId, WaterLog log,
      {bool isHealthyPick = false}) async {
    try {
      await _logsCollection(userId).add(log.toMap());

      // Atomically update cumulative lifetime stats
      final updates = <String, dynamic>{
        'totalWaterConsumed': FieldValue.increment(log.waterContentOz),
        'totalDrinksLogged': FieldValue.increment(1),
        'uniqueDrinksLogged': FieldValue.arrayUnion([log.drinkName]),
      };
      if (isHealthyPick) {
        updates['totalHealthyPicks'] = FieldValue.increment(1);
      }
      await _userDoc(userId).set(updates, SetOptions(merge: true));

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeWaterLog(
      String userId, WaterLog log) async {
    try {
      if (log.id != null) {
        await _logsCollection(userId).doc(log.id).delete();
      } else {
        // Find by matching fields
        final query = await _logsCollection(userId)
            .where('drinkName', isEqualTo: log.drinkName)
            .where('entryTime', isEqualTo: log.entryTime.toIso8601String())
            .limit(1)
            .get();
        for (var doc in query.docs) {
          await doc.reference.delete();
        }
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearLogsForDate(
      String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _logsCollection(userId)
          .where('entryTime',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('entryTime', isLessThan: endOfDay.toIso8601String())
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WaterLog>>> getLogsForDate(
      String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _logsCollection(userId)
          .where('entryTime',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('entryTime', isLessThan: endOfDay.toIso8601String())
          .orderBy('entryTime', descending: true)
          .get();

      final logs = query.docs
          .map((doc) =>
              WaterLog.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();

      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<WaterLog>>> getAllLogs(String userId) async {
    try {
      final query = await _logsCollection(userId)
          .orderBy('entryTime', descending: true)
          .get();

      final logs = query.docs
          .map((doc) =>
              WaterLog.fromMap(doc.data() as Map<String, dynamic>, id: doc.id))
          .toList();

      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, bool>>> getLoggedDays(
      String userId) async {
    try {
      final query = await _logsCollection(userId).get();
      final Map<DateTime, double> dailyTotals = {};

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final entryTime = data['entryTime'] != null
            ? DateTime.parse(data['entryTime'] as String)
            : DateTime.now();
        final dayKey = DateTime(entryTime.year, entryTime.month, entryTime.day);
        final water = (data['waterContent'] as num?)?.toDouble() ?? 0.0;
        dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0.0) + water;
      }

      // Load goal to determine if goal was met
      final userDoc = await _userDoc(userId).get();
      final userData = (userDoc.data() as Map<String, dynamic>?) ?? {};
      final goal = (userData['waterGoal'] as num?)?.toDouble() ?? 80.0;

      final Map<DateTime, bool> loggedDays = {};
      for (var entry in dailyTotals.entries) {
        loggedDays[entry.key] = entry.value >= goal;
      }

      return Right(loggedDays);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalWaterConsumed(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      final data = (doc.data() as Map<String, dynamic>?) ?? {};
      return Right((data['totalWaterConsumed'] as num?)?.toDouble() ?? 0.0);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalDaysLogged(String userId) async {
    try {
      final doc = await _userDoc(userId).get();
      final data = (doc.data() as Map<String, dynamic>?) ?? {};
      return Right((data['totalDaysLogged'] as num?)?.toInt() ?? 0);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateWaterGoal(
      String userId, double goalOz) async {
    try {
      await _userDoc(userId).set({
        'waterGoal': goalOz,
      }, SetOptions(merge: true));
      await _prefs.setDouble(AppConstants.prefWaterGoal, goalOz);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetDailyData(
      String userId, HydrationState currentState) async {
    try {
      final now = DateTime.now();
      int newStreak = currentState.currentStreak;

      if (currentState.goalMetToday) {
        // Streak was already incremented in addWater when goal was met.
        // Just keep it as-is.
      } else {
        newStreak = 0;
      }

      // Update total days logged if any water was consumed
      if (currentState.waterConsumedOz > 0) {
        final doc = await _userDoc(userId).get();
        final data = (doc.data() as Map<String, dynamic>?) ?? {};
        final totalDays = (data['totalDaysLogged'] as num?)?.toInt() ?? 0;
        await _userDoc(userId).set({
          'totalDaysLogged': totalDays + 1,
        }, SetOptions(merge: true));
      }

      final newState = currentState.copyWith(
        waterConsumedOz: 0.0,
        goalMetToday: false,
        currentStreak: newStreak,
        recordStreak: newStreak > currentState.recordStreak
            ? newStreak
            : currentState.recordStreak,
        lastResetDate: now,
        clearNextEntryTime: true,
      );

      // Handle challenge day count
      if (currentState.hasActiveChallenge) {
        final daysLeft = currentState.challengeDaysLeft - 1;
        if (daysLeft <= 0) {
          // Challenge completed!
          await saveHydrationState(
            userId,
            newState.copyWith(
              challengeCompleted: true,
              challengeDaysLeft: 0,
              completedChallenges: currentState.completedChallenges + 1,
            ),
          );
        } else if (!currentState.goalMetToday) {
          // Failed challenge by not meeting goal
          await saveHydrationState(
            userId,
            newState.copyWith(
              challengeFailed: true,
            ),
          );
        } else {
          await saveHydrationState(
            userId,
            newState.copyWith(challengeDaysLeft: daysLeft),
          );
        }
      } else {
        await saveHydrationState(userId, newState);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateChallengeState(
    String userId, {
    int? activeChallengeIndex,
    List<bool>? challengeActive,
    bool? challengeFailed,
    bool? challengeCompleted,
    int? challengeDaysLeft,
    int? completedChallenges,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (activeChallengeIndex != null) {
        updates['activeChallengeIndex'] = activeChallengeIndex;
      }
      if (challengeActive != null) {
        for (int i = 0; i < challengeActive.length && i < 6; i++) {
          updates['challenge${i + 1}Active'] = challengeActive[i];
        }
      }
      if (challengeFailed != null) updates['challengeFailed'] = challengeFailed;
      if (challengeCompleted != null)
        updates['challengeCompleted'] = challengeCompleted;
      if (challengeDaysLeft != null) updates['daysLeft'] = challengeDaysLeft;
      if (completedChallenges != null)
        updates['completedChallenges'] = completedChallenges;

      if (updates.isNotEmpty) {
        await _userDoc(userId).set(updates, SetOptions(merge: true));
      }
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ── Local cache helpers ────────────────────────────────────────────

  void _cacheState(HydrationState state) {
    _prefs.setDouble(AppConstants.prefWaterConsumed, state.waterConsumedOz);
    _prefs.setDouble(AppConstants.prefWaterGoal, state.waterGoalOz);
    _prefs.setInt(AppConstants.prefCurrentStreak, state.currentStreak);
    _prefs.setInt(AppConstants.prefRecordStreak, state.recordStreak);
    _prefs.setBool(AppConstants.prefGoalMetToday, state.goalMetToday);
  }

  HydrationState? _loadCachedState() {
    if (!_prefs.containsKey(AppConstants.prefWaterGoal)) return null;
    return HydrationState(
      waterConsumedOz: _prefs.getDouble(AppConstants.prefWaterConsumed) ?? 0.0,
      waterGoalOz: _prefs.getDouble(AppConstants.prefWaterGoal) ?? 80.0,
      currentStreak: _prefs.getInt(AppConstants.prefCurrentStreak) ?? 0,
      recordStreak: _prefs.getInt(AppConstants.prefRecordStreak) ?? 0,
      goalMetToday: _prefs.getBool(AppConstants.prefGoalMetToday) ?? false,
    );
  }
}
