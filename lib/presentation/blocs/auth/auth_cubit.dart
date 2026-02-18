import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/domain/repositories/auth_repository.dart';
import 'package:waddle/presentation/blocs/auth/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  /// Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());

    // Check remember me + saved user
    final rememberResult = await _authRepository.getRememberMe();
    final rememberMe = rememberResult.fold((_) => false, (val) => val);

    if (rememberMe) {
      final savedUidResult = await _authRepository.getSavedUserId();
      final savedUid = savedUidResult.fold((_) => null, (val) => val);
      if (savedUid != null) {
        final userResult = await _authRepository.getCurrentUser();
        userResult.fold(
          (failure) => emit(const Unauthenticated()),
          (user) {
            if (user != null) {
              emit(Authenticated(user));
            } else {
              emit(const Unauthenticated());
            }
          },
        );
        return;
      }
    }

    // Check current Firebase user
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(const Unauthenticated()),
      (user) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      },
    );
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    emit(const AuthLoading());

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (user) async {
        if (rememberMe) {
          await _authRepository.setRememberMe(true);
        }
        emit(Authenticated(user));
      },
    );
  }

  /// Register a new user
  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _authRepository.register(
      email: email,
      username: username,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    emit(const AuthLoading());

    final result = await _authRepository.resetPassword(email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const PasswordResetSent()),
    );
  }

  /// Sign out
  Future<void> signOut() async {
    emit(const AuthLoading());

    final result = await _authRepository.signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Delete account and all data
  Future<void> deleteAccount() async {
    emit(const AuthLoading());

    final result = await _authRepository.deleteAccount();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Update profile
  Future<void> updateProfile({
    String? username,
    String? profileImageUrl,
    String? bio,
    bool? isPublicProfile,
  }) async {
    final currentState = state;
    if (currentState is! Authenticated) return;

    final result = await _authRepository.updateProfile(
      username: username,
      profileImageUrl: profileImageUrl,
      bio: bio,
      isPublicProfile: isPublicProfile,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        emit(Authenticated(currentState.user.copyWith(
          username: username,
          profileImageUrl: profileImageUrl,
          bio: bio,
          isPublicProfile: isPublicProfile,
        )));
      },
    );
  }
}
