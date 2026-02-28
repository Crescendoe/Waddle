import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/domain/entities/friend_entity.dart';

/// Firebase-backed friend system service
class FriendService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _friendRequestsCollection = 'friendRequests';
  static const String _friendsSubcollection = 'friends';

  FriendService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String? get _currentUid => _auth.currentUser?.uid;

  // ── Search Users ──────────────────────────────────────────────────

  /// Search for users by username (case-insensitive prefix match)
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final uid = _currentUid;
    if (uid == null) return [];

    final lower = query.toLowerCase().trim();
    final upper = '$lower\uf8ff';

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('usernameLower', isGreaterThanOrEqualTo: lower)
        .where('usernameLower', isLessThanOrEqualTo: upper)
        .limit(20)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != uid)
        .map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'username': data['username'] as String? ?? 'User',
            'profileImageUrl': data['profileImage'] as String?,
            'bio': data['bio'] as String?,
            'currentStreak': data['currentStreak'] as int? ?? 0,
            'isPublicProfile': data['isPublicProfile'] as bool? ?? true,
          };
        })
        .where((u) => u['isPublicProfile'] == true)
        .toList();
  }

  // ── Friend Requests ───────────────────────────────────────────────

  /// Send a friend request
  Future<void> sendFriendRequest(String toUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not authenticated');

    // Check if already friends
    final existingFriend = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(_friendsSubcollection)
        .doc(toUid)
        .get();
    if (existingFriend.exists) throw Exception('Already friends');

    // Check if request already exists
    final existing = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUid', isEqualTo: uid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) throw Exception('Request already sent');

    // Check reverse request (they already sent us one)
    final reverse = await _firestore
        .collection(_friendRequestsCollection)
        .where('fromUid', isEqualTo: toUid)
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (reverse.docs.isNotEmpty) {
      // Auto-accept if they already sent us a request
      await acceptFriendRequest(reverse.docs.first.id);
      return;
    }

    // Get current user info
    final myDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    final myData = myDoc.data() ?? {};

    // Get target user info
    final theirDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(toUid)
        .get();
    final theirData = theirDoc.data() ?? {};

    await _firestore.collection(_friendRequestsCollection).add({
      'fromUid': uid,
      'toUid': toUid,
      'fromUsername': myData['username'] ?? 'User',
      'fromProfileImage': myData['profileImage'],
      'toUsername': theirData['username'] ?? 'User',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Accept a friend request
  Future<void> acceptFriendRequest(String requestId) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not authenticated');

    final requestDoc = await _firestore
        .collection(_friendRequestsCollection)
        .doc(requestId)
        .get();

    if (!requestDoc.exists) throw Exception('Request not found');
    final data = requestDoc.data()!;

    final fromUid = data['fromUid'] as String;
    final toUid = data['toUid'] as String;

    // Get both user docs for stats
    final fromDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(fromUid)
        .get();
    final toDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(toUid)
        .get();

    final fromData = fromDoc.data() ?? {};
    final toData = toDoc.data() ?? {};

    final now = DateTime.now();
    final batch = _firestore.batch();

    // Add friend to sender's friends list
    batch.set(
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(fromUid)
          .collection(_friendsSubcollection)
          .doc(toUid),
      {
        'uid': toUid,
        'username': toData['username'] ?? 'User',
        'profileImage': toData['profileImage'],
        'addedAt': Timestamp.fromDate(now),
        'currentStreak': toData['currentStreak'] ?? 0,
        'recordStreak': toData['recordStreak'] ?? 0,
        'totalWaterConsumed': toData['totalWaterConsumed'] ?? 0.0,
        'totalGoalsMet': toData['totalGoalsMet'] ?? 0,
        'totalDaysLogged': toData['totalDaysLogged'] ?? 0,
      },
    );

    // Add friend to receiver's friends list
    batch.set(
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(toUid)
          .collection(_friendsSubcollection)
          .doc(fromUid),
      {
        'uid': fromUid,
        'username': fromData['username'] ?? 'User',
        'profileImage': fromData['profileImage'],
        'addedAt': Timestamp.fromDate(now),
        'currentStreak': fromData['currentStreak'] ?? 0,
        'recordStreak': fromData['recordStreak'] ?? 0,
        'totalWaterConsumed': fromData['totalWaterConsumed'] ?? 0.0,
        'totalGoalsMet': fromData['totalGoalsMet'] ?? 0,
        'totalDaysLogged': fromData['totalDaysLogged'] ?? 0,
      },
    );

    // Increment friend count for both
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(fromUid),
      {'friendCount': FieldValue.increment(1)},
    );
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(toUid),
      {'friendCount': FieldValue.increment(1)},
    );

    // Update request status
    batch.update(
      _firestore.collection(_friendRequestsCollection).doc(requestId),
      {'status': 'accepted'},
    );

    await batch.commit();
  }

  /// Decline a friend request
  Future<void> declineFriendRequest(String requestId) async {
    await _firestore
        .collection(_friendRequestsCollection)
        .doc(requestId)
        .update({'status': 'declined'});
  }

  /// Get pending incoming friend requests (real-time stream)
  Stream<List<FriendRequest>> getIncomingRequests() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(_friendRequestsCollection)
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return FriendRequest(
                id: doc.id,
                fromUid: data['fromUid'] as String? ?? '',
                toUid: data['toUid'] as String? ?? '',
                fromUsername: data['fromUsername'] as String? ?? 'User',
                fromProfileImageUrl: data['fromProfileImage'] as String?,
                toUsername: data['toUsername'] as String? ?? '',
                status: FriendRequestStatus.pending,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList());
  }

  /// Get count of pending incoming requests
  Future<int> getPendingRequestCount() async {
    final uid = _currentUid;
    if (uid == null) return 0;

    final snapshot = await _firestore
        .collection(_friendRequestsCollection)
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // ── Friends List ──────────────────────────────────────────────────

  /// Get all friends (real-time stream)
  Stream<List<FriendEntity>> getFriends() {
    final uid = _currentUid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(_friendsSubcollection)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return FriendEntity(
                uid: doc.id,
                username: data['username'] as String? ?? 'User',
                profileImageUrl: data['profileImage'] as String?,
                addedAt:
                    (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                currentStreak: data['currentStreak'] as int? ?? 0,
                recordStreak: data['recordStreak'] as int? ?? 0,
                totalWaterConsumedOz:
                    (data['totalWaterConsumed'] as num?)?.toDouble() ?? 0,
                totalGoalsMet: data['totalGoalsMet'] as int? ?? 0,
                totalDaysLogged: data['totalDaysLogged'] as int? ?? 0,
              );
            }).toList());
  }

  /// Get friends count
  Future<int> getFriendsCount() async {
    final uid = _currentUid;
    if (uid == null) return 0;

    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(_friendsSubcollection)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Remove a friend
  Future<void> removeFriend(String friendUid) async {
    final uid = _currentUid;
    if (uid == null) throw Exception('Not authenticated');

    final batch = _firestore.batch();

    // Remove from both users' friends lists
    batch.delete(
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection(_friendsSubcollection)
          .doc(friendUid),
    );
    batch.delete(
      _firestore
          .collection(AppConstants.usersCollection)
          .doc(friendUid)
          .collection(_friendsSubcollection)
          .doc(uid),
    );

    // Decrement friend count for both
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(uid),
      {'friendCount': FieldValue.increment(-1)},
    );
    batch.update(
      _firestore.collection(AppConstants.usersCollection).doc(friendUid),
      {'friendCount': FieldValue.increment(-1)},
    );

    await batch.commit();
  }

  // ── Friend Stats (for viewing a friend's profile) ────────────────

  /// Get a friend's public stats by reading their user doc
  Future<Map<String, dynamic>?> getFriendPublicStats(String friendUid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(friendUid)
        .get();

    if (!doc.exists) return null;
    final data = doc.data()!;

    final isPublic = data['isPublicProfile'] as bool? ?? true;
    if (!isPublic) return null;

    return {
      'uid': friendUid,
      'username': data['username'] as String? ?? 'User',
      'profileImage': data['profileImage'] as String?,
      'bio': data['bio'] as String?,
      'currentStreak': data['currentStreak'] as int? ?? 0,
      'recordStreak': data['recordStreak'] as int? ?? 0,
      'totalWaterConsumed':
          (data['totalWaterConsumed'] as num?)?.toDouble() ?? 0.0,
      'totalGoalsMet': data['totalGoalsMet'] as int? ?? 0,
      'totalDaysLogged': data['totalDaysLogged'] as int? ?? 0,
      'completedChallenges': data['completedChallenges'] as int? ?? 0,
      'totalDrinksLogged': data['totalDrinksLogged'] as int? ?? 0,
      'totalHealthyPicks': data['totalHealthyPicks'] as int? ?? 0,
      'uniqueDrinksLogged': (data['uniqueDrinksLogged'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      'waterGoal': (data['waterGoal'] as num?)?.toDouble() ?? 80.0,
      'friendCount': data['friendCount'] as int? ?? 0,
      'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
      'totalXp': data['totalXp'] as int? ?? 0,
      'challenge1Active': data['challenge1Active'] as bool? ?? false,
      'challenge2Active': data['challenge2Active'] as bool? ?? false,
      'challenge3Active': data['challenge3Active'] as bool? ?? false,
      'challenge4Active': data['challenge4Active'] as bool? ?? false,
      'challenge5Active': data['challenge5Active'] as bool? ?? false,
      'challenge6Active': data['challenge6Active'] as bool? ?? false,
    };
  }

  // ── Refresh friend stats snapshot ─────────────────────────────────

  /// Refresh the stats snapshot stored in the friends subcollection
  Future<void> refreshFriendStats() async {
    final uid = _currentUid;
    if (uid == null) return;

    // Get current user stats
    final myDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    final myData = myDoc.data() ?? {};

    // Get all friends
    final friendsSnapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(_friendsSubcollection)
        .get();

    if (friendsSnapshot.docs.isEmpty) return;

    final batch = _firestore.batch();

    // Update my stats in each friend's subcollection
    for (final friendDoc in friendsSnapshot.docs) {
      batch.update(
        _firestore
            .collection(AppConstants.usersCollection)
            .doc(friendDoc.id)
            .collection(_friendsSubcollection)
            .doc(uid),
        {
          'username': myData['username'] ?? 'User',
          'profileImage': myData['profileImage'],
          'currentStreak': myData['currentStreak'] ?? 0,
          'recordStreak': myData['recordStreak'] ?? 0,
          'totalWaterConsumed': myData['totalWaterConsumed'] ?? 0.0,
          'totalGoalsMet': myData['totalGoalsMet'] ?? 0,
          'totalDaysLogged': myData['totalDaysLogged'] ?? 0,
        },
      );
    }

    await batch.commit();
  }
}
