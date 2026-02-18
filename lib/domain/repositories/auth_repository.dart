import 'package:dartz/dartz.dart';
import 'package:waddle/core/error/failures.dart';
import 'package:waddle/domain/entities/user_entity.dart';

/// Authentication repository contract
abstract class AuthRepository {
  /// Get current authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// Register a new user
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String username,
    required String password,
  });

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Send password reset email
  Future<Either<Failure, void>> resetPassword(String email);

  /// Update user profile
  Future<Either<Failure, void>> updateProfile({
    String? username,
    String? profileImageUrl,
    String? bio,
    bool? isPublicProfile,
  });

  /// Delete user account and all data
  Future<Either<Failure, void>> deleteAccount();

  /// Save remember me preference
  Future<Either<Failure, void>> setRememberMe(bool value);

  /// Check if user has remember me enabled
  Future<Either<Failure, bool>> getRememberMe();

  /// Get saved user ID for auto-login
  Future<Either<Failure, String?>> getSavedUserId();
}
