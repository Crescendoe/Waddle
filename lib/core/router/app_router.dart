import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/presentation/screens/auth/forgot_password_screen.dart';
import 'package:waddle/presentation/screens/auth/login_screen.dart';
import 'package:waddle/presentation/screens/auth/registration_screen.dart';
import 'package:waddle/presentation/screens/main/main_shell.dart';
import 'package:waddle/presentation/screens/onboarding/account_created_screen.dart';
import 'package:waddle/presentation/screens/onboarding/questions_screen.dart';
import 'package:waddle/presentation/screens/onboarding/results_screen.dart';
import 'package:waddle/presentation/screens/onboarding/welcome_screen.dart';
import 'package:waddle/presentation/screens/profile/edit_profile_screen.dart';
import 'package:waddle/presentation/screens/profile/friend_profile_screen.dart';
import 'package:waddle/presentation/screens/profile/friends_screen.dart';
import 'package:waddle/presentation/screens/settings/health_sync_screen.dart';
import 'package:waddle/presentation/screens/settings/notifications_screen.dart';
import 'package:waddle/presentation/screens/settings/privacy_policy_screen.dart';
import 'package:waddle/presentation/screens/settings/settings_screen.dart';
import 'package:waddle/presentation/screens/settings/terms_of_service_screen.dart';
import 'package:waddle/presentation/screens/celebration/congrats_screen.dart';
import 'package:waddle/presentation/screens/celebration/challenge_complete_screen.dart';
import 'package:waddle/presentation/screens/celebration/challenge_failed_screen.dart';
import 'package:waddle/presentation/screens/celebration/unlock_reward_screen.dart';
import 'package:waddle/presentation/screens/splash/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router() {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      routes: [
        // Splash (loading screen on cold start)
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Onboarding & Auth
        GoRoute(
          path: '/',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegistrationScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/account-created',
          name: 'accountCreated',
          builder: (context, state) => const AccountCreatedScreen(),
        ),
        GoRoute(
          path: '/questions',
          name: 'questions',
          builder: (context, state) {
            final recalculate = state.extra as bool? ?? false;
            return QuestionsScreen(recalculate: recalculate);
          },
        ),
        GoRoute(
          path: '/results',
          name: 'results',
          builder: (context, state) {
            final extra = state.extra;
            double goalOz = 80.0;
            bool recalculate = false;
            if (extra is Map) {
              goalOz = (extra['goalOz'] as num?)?.toDouble() ?? 80.0;
              recalculate = extra['recalculate'] as bool? ?? false;
            } else if (extra is double) {
              goalOz = extra;
            }
            return ResultsScreen(goalOz: goalOz, recalculate: recalculate);
          },
        ),

        // Main App
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const MainShell(),
        ),

        // Celebration
        GoRoute(
          path: '/congrats',
          name: 'congrats',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CongratsScreen(
              oldStreak: extra['oldStreak'] as int? ?? 0,
              newStreak: extra['newStreak'] as int? ?? 1,
            );
          },
        ),
        GoRoute(
          path: '/challenge-complete',
          name: 'challengeComplete',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ChallengeCompleteScreen(
              challengeIndex: extra['challengeIndex'] as int? ?? 0,
            );
          },
        ),
        GoRoute(
          path: '/challenge-failed',
          name: 'challengeFailed',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ChallengeFailedScreen(
              challengeIndex: extra['challengeIndex'] as int? ?? 0,
            );
          },
        ),
        GoRoute(
          path: '/unlock-reward',
          name: 'unlockReward',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return UnlockRewardScreen(
              type: extra['type'] as UnlockRewardType? ?? UnlockRewardType.duck,
              duckIndex: extra['duckIndex'] as int?,
              themeId: extra['themeId'] as String?,
            );
          },
        ),

        // Settings
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/health-sync',
          name: 'healthSync',
          builder: (context, state) => const HealthSyncScreen(),
        ),
        GoRoute(
          path: '/privacy-policy',
          name: 'privacyPolicy',
          builder: (context, state) => const PrivacyPolicyScreen(),
        ),
        GoRoute(
          path: '/terms-of-service',
          name: 'termsOfService',
          builder: (context, state) => const TermsOfServiceScreen(),
        ),

        // Profile / Social
        GoRoute(
          path: '/edit-profile',
          name: 'editProfile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/friends',
          name: 'friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        GoRoute(
          path: '/friend-profile',
          name: 'friendProfile',
          builder: (context, state) {
            final friendUid = state.extra as String? ?? '';
            return FriendProfileScreen(friendUid: friendUid);
          },
        ),
      ],
    );
  }
}
