import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/core/router/app_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/notification_service.dart';
import 'package:waddle/firebase_options.dart';
import 'package:waddle/presentation/blocs/auth/auth_cubit.dart';
import 'package:waddle/presentation/blocs/auth/auth_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';

/// Background message handler – must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // DI setup (registers SharedPreferences, repos, cubits, services)
  await setupDependencies();

  // Initialize local notification service (creates channels, restores schedules)
  await getIt<NotificationService>().init();

  runApp(const WaddleApp());
}

class WaddleApp extends StatefulWidget {
  const WaddleApp({super.key});

  @override
  State<WaddleApp> createState() => _WaddleAppState();
}

class _WaddleAppState extends State<WaddleApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() {
    final notifService = getIt<NotificationService>();
    // Foreground FCM messages – show as local notification via service
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        notifService.showFCMNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => getIt<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider<HydrationCubit>(
          create: (_) => getIt<HydrationCubit>(),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          // When user authenticates, load their hydration data
          if (state is Authenticated) {
            context.read<HydrationCubit>().loadData(state.user.uid);
          }
        },
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router(),
        ),
      ),
    );
  }
}
