import 'package:equatable/equatable.dart';

/// Represents a friend relationship
class FriendEntity extends Equatable {
  final String uid;
  final String username;
  final String? profileImageUrl;
  final DateTime addedAt;

  // Snapshot of their public stats (refreshed periodically)
  final int currentStreak;
  final int recordStreak;
  final double totalWaterConsumedOz;
  final int totalGoalsMet;
  final int totalDaysLogged;

  const FriendEntity({
    required this.uid,
    required this.username,
    this.profileImageUrl,
    required this.addedAt,
    this.currentStreak = 0,
    this.recordStreak = 0,
    this.totalWaterConsumedOz = 0,
    this.totalGoalsMet = 0,
    this.totalDaysLogged = 0,
  });

  @override
  List<Object?> get props => [
        uid,
        username,
        profileImageUrl,
        addedAt,
        currentStreak,
        recordStreak,
        totalWaterConsumedOz,
        totalGoalsMet,
        totalDaysLogged,
      ];
}

/// Represents a pending friend request
class FriendRequest extends Equatable {
  final String id;
  final String fromUid;
  final String toUid;
  final String fromUsername;
  final String? fromProfileImageUrl;
  final String toUsername;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromUsername,
    this.fromProfileImageUrl,
    required this.toUsername,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, fromUid, toUid, fromUsername, toUsername, status, createdAt];
}

enum FriendRequestStatus { pending, accepted, declined }
