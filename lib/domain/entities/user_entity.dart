import 'package:equatable/equatable.dart';

/// Core user entity
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String username;
  final String? bio;
  final String? profileImageUrl;
  final String? fcmToken;
  final DateTime createdAt;
  final bool rememberMe;
  final bool isPublicProfile;
  final int friendCount;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.username,
    this.bio,
    this.profileImageUrl,
    this.fcmToken,
    required this.createdAt,
    this.rememberMe = false,
    this.isPublicProfile = true,
    this.friendCount = 0,
  });

  UserEntity copyWith({
    String? uid,
    String? email,
    String? username,
    String? bio,
    String? profileImageUrl,
    String? fcmToken,
    DateTime? createdAt,
    bool? rememberMe,
    bool? isPublicProfile,
    int? friendCount,
    bool clearBio = false,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: clearBio ? null : (bio ?? this.bio),
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      rememberMe: rememberMe ?? this.rememberMe,
      isPublicProfile: isPublicProfile ?? this.isPublicProfile,
      friendCount: friendCount ?? this.friendCount,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        username,
        bio,
        profileImageUrl,
        fcmToken,
        createdAt,
        rememberMe,
        isPublicProfile,
        friendCount,
      ];
}
