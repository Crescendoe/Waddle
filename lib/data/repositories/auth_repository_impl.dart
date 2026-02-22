import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/error/failures.dart';
import 'package:waddle/domain/entities/user_entity.dart';
import 'package:waddle/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _auth = auth,
        _firestore = firestore,
        _prefs = prefs;

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Backfill fields added after initial launch so existing users are searchable
  Future<void> _backfillUserFields(
      String uid, Map<String, dynamic> data) async {
    final updates = <String, dynamic>{};
    final username = data['username'] as String? ?? 'User';

    if (data['usernameLower'] == null) {
      updates['usernameLower'] = username.toLowerCase();
    }
    if (data['isPublicProfile'] == null) {
      updates['isPublicProfile'] = true;
    }
    if (data['friendCount'] == null) {
      updates['friendCount'] = 0;
    }
    // Backfill createdAt for users registered before this field was added
    if (data['createdAt'] == null) {
      final authUser = _auth.currentUser;
      final creationTime = authUser?.metadata.creationTime;
      updates['createdAt'] = Timestamp.fromDate(creationTime ?? DateTime.now());
    }

    if (updates.isNotEmpty) {
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update(updates);
      } catch (_) {
        // Non-critical — will retry next session
      }
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // Wait for Firebase Auth to restore any persisted session.
      // currentUser can be null immediately after Firebase.initializeApp().
      final user = await _auth.authStateChanges().first;
      if (user == null) return const Right(null);

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) return const Right(null);

      final data = doc.data()!;

      // Backfill missing fields for users created before social features
      await _backfillUserFields(user.uid, data);

      return Right(UserEntity(
        uid: user.uid,
        email: data['email'] as String? ?? user.email ?? '',
        username: data['username'] as String? ?? 'User',
        bio: data['bio'] as String?,
        profileImageUrl: data['profileImage'] as String?,
        fcmToken: data['fcmToken'] as String?,
        createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
        rememberMe: data['rememberMe'] as bool? ?? false,
        isPublicProfile: data['isPublicProfile'] as bool? ?? true,
        friendCount: data['friendCount'] as int? ?? 0,
      ));
    } on FirebaseException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Firebase error'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure(message: 'Sign in failed'));
      }

      // Load user data from Firestore
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      // Update FCM token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _firestore
              .collection(AppConstants.usersCollection)
              .doc(user.uid)
              .set({'fcmToken': fcmToken}, SetOptions(merge: true));
        }
      } catch (_) {}

      // Backfill missing fields for users created before social features
      await _backfillUserFields(user.uid, data);

      return Right(UserEntity(
        uid: user.uid,
        email: data['email'] as String? ?? email,
        username: data['username'] as String? ?? 'User',
        bio: data['bio'] as String?,
        profileImageUrl: data['profileImage'] as String?,
        fcmToken: fcmToken,
        createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
        isPublicProfile: data['isPublicProfile'] as bool? ?? true,
        friendCount: data['friendCount'] as int? ?? 0,
      ));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.code)));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        return const Left(AuthFailure(message: 'Registration failed'));
      }

      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      final now = DateTime.now();

      // Create user document with default hydration values
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set({
        'email': email,
        'username': username,
        'usernameLower': username.toLowerCase(),
        'profileImage': null,
        'bio': null,
        'isPublicProfile': true,
        'friendCount': 0,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(now),
        'rememberMe': false,
        // Hydration defaults
        'currentStreak': 0,
        'recordStreak': 0,
        'completedChallenges': 0,
        'companionsCollected': 0,
        'waterConsumed': 0.0,
        'waterGoal': AppConstants.defaultWaterGoalOz,
        'goalMetToday': false,
        'activeChallengeIndex': null,
        'challenge1Active': false,
        'challenge2Active': false,
        'challenge3Active': false,
        'challenge4Active': false,
        'challenge5Active': false,
        'challenge6Active': false,
        'challengeFailed': false,
        'challengeCompleted': false,
        'daysLeft': 14,
        'totalWaterConsumed': 0.0,
        'totalDaysLogged': 0,
        'fcmSettings': {
          'notificationsEnabled': false,
          'dailyReminderTime': null,
          'reminderIntervalMinutes': null,
        },
      });

      return Right(UserEntity(
        uid: user.uid,
        email: email,
        username: username,
        fcmToken: fcmToken,
        createdAt: now,
      ));
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.code)));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'rememberMe': false});
      }
      await _auth.signOut();
      await _prefs.remove(AppConstants.prefRememberMe);
      await _prefs.remove(AppConstants.prefSavedUid);
      await _prefs.remove(AppConstants.prefSavedEmail);
      await _prefs.remove(AppConstants.prefSavedPassword);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.code)));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile({
    String? username,
    String? profileImageUrl,
    String? bio,
    bool? isPublicProfile,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null)
        return const Left(AuthFailure(message: 'Not authenticated'));

      final updates = <String, dynamic>{};
      if (username != null) {
        updates['username'] = username;
        updates['usernameLower'] = username.toLowerCase();
      }
      if (profileImageUrl != null) updates['profileImage'] = profileImageUrl;
      if (bio != null) updates['bio'] = bio;
      if (isPublicProfile != null) updates['isPublicProfile'] = isPublicProfile;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(updates);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'Not authenticated'));
      }

      final uid = user.uid;

      // Delete Firebase Auth user FIRST (requires recent login).
      // If this fails (e.g. requires-recent-login), we abort before
      // touching Firestore so no data is orphaned.
      await user.delete();

      // Auth user deleted — now clean up Firestore data
      final logsSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(AppConstants.waterLogsSubcollection)
          .get();
      for (final doc in logsSnapshot.docs) {
        await doc.reference.delete();
      }
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .delete();

      // Clear local prefs
      await _prefs.remove(AppConstants.prefRememberMe);
      await _prefs.remove(AppConstants.prefSavedUid);
      await _prefs.remove(AppConstants.prefSavedEmail);
      await _prefs.remove(AppConstants.prefSavedPassword);

      return const Right(null);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: _mapAuthError(e.code)));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setRememberMe(bool value) async {
    try {
      final uid = _auth.currentUser?.uid;
      await _prefs.setBool(AppConstants.prefRememberMe, value);
      if (uid != null) {
        await _prefs.setString(AppConstants.prefSavedUid, uid);
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'rememberMe': value});
      }
      if (!value) {
        await _prefs.remove(AppConstants.prefSavedUid);
      }
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getRememberMe() async {
    try {
      return Right(_prefs.getBool(AppConstants.prefRememberMe) ?? false);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getSavedUserId() async {
    try {
      return Right(_prefs.getString(AppConstants.prefSavedUid));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'requires-recent-login':
        return 'Please sign out and sign back in, then try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return 'Authentication error: $code';
    }
  }
}
