import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waddle/data/repositories/auth_repository_impl.dart';
import 'package:waddle/data/repositories/health_repository_impl.dart';
import 'package:waddle/data/repositories/hydration_repository_impl.dart';
import 'package:waddle/data/services/notification_service.dart';
import 'package:waddle/data/services/app_settings_service.dart';
import 'package:waddle/data/services/debug_mode_service.dart';
import 'package:waddle/data/services/friend_service.dart';
import 'package:waddle/domain/repositories/auth_repository.dart';
import 'package:waddle/domain/repositories/health_repository.dart';
import 'package:waddle/domain/repositories/hydration_repository.dart';
import 'package:waddle/presentation/blocs/auth/auth_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => prefs);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      auth: getIt(),
      firestore: getIt(),
      prefs: getIt(),
    ),
  );

  getIt.registerLazySingleton<HydrationRepository>(
    () => HydrationRepositoryImpl(
      firestore: getIt(),
      prefs: getIt(),
    ),
  );

  getIt.registerLazySingleton<HealthRepository>(
    () => HealthRepositoryImpl(prefs: getIt()),
  );

  // Services
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(prefs: getIt()),
  );

  getIt.registerLazySingleton<AppSettingsService>(
    () => AppSettingsService(prefs: getIt()),
  );

  getIt.registerLazySingleton<FriendService>(
    () => FriendService(
      firestore: getIt(),
      auth: getIt(),
    ),
  );

  getIt.registerLazySingleton<DebugModeService>(
    () => DebugModeService(),
  );

  // Cubits
  getIt.registerFactory(
    () => AuthCubit(authRepository: getIt()),
  );

  getIt.registerFactory(
    () => HydrationCubit(
      hydrationRepository: getIt(),
      healthRepository: getIt(),
    ),
  );
}
