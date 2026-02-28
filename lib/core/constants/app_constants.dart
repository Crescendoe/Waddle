/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Waddle';
  static const String appVersion = '0.9.5';
  static const String developerName = 'William Wyler';
  static const String supportEmail = 'crescendoedd@gmail.com';

  // Water defaults
  static const double defaultWaterGoalOz = 80.0;
  static const double ozPerCup = 8.0;
  static const int entryTimerMinutes = 30;
  static const int challengeDurationDays = 14;

  // Streak tier thresholds
  static const int bronzeThreshold = 10;
  static const int silverThreshold = 15;
  static const int goldThreshold = 20;
  static const int platinumThreshold = 30;

  // Drink logging
  static const int logDebounceSeconds = 60;
  static const double maxDrinkOz = 40.0;
  static const int sliderDivisions = 40;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String waterLogsSubcollection = 'waterLogs';

  // SharedPreferences keys
  static const String prefRememberMe = 'rememberMe';
  static const String prefSavedUid = 'savedUid';
  static const String prefSavedEmail = 'remembered_email';
  static const String prefSavedPassword = 'remembered_password';
  static const String prefWaterConsumed = 'waterConsumed';
  static const String prefWaterGoal = 'waterGoal';
  static const String prefCurrentStreak = 'currentStreak';
  static const String prefRecordStreak = 'recordStreak';
  static const String prefGoalMetToday = 'goalMetToday';
  static const String prefLastResetDate = 'lastResetDate';
  static const String prefNextEntryTime = 'nextEntryTime';
  static const String prefActiveChallengeIndex = 'activeChallengeIndex';
  static const String prefFavoriteDrinks = 'favoriteDrinks';

  // FCM Topics
  static const String fcmTopicAllUsers = 'all_users_reminders';
  static String fcmTopicUser(String uid) => 'user_reminders_$uid';

  // Mascot images
  static const String mascotDefault = 'lib/assets/images/wade_default.png';
  static const String mascotWave = 'lib/assets/images/wade_wave.png';
  static const String mascotRunning = 'lib/assets/images/wade_running.png';
  static const String mascotFloating = 'lib/assets/images/wade_floating.png';
  static const String mascotFlying = 'lib/assets/images/wade_flying.png';
  static const String mascotSitting =
      'lib/assets/images/wade_sitting_looking_up.png';
  static const String cupImage = 'lib/assets/images/cup.png';

  // Challenge mascot images
  static const List<String> challengeImages = [
    'lib/assets/images/wade_nothing_but_water.png',
    'lib/assets/images/wade_tea_time.png',
    'lib/assets/images/wade_caffeine_cut.png',
    'lib/assets/images/wade_sugar_free_sips.png',
    'lib/assets/images/wade_dairy_free_refresh.png',
    'lib/assets/images/wade_vitamin_vitality.png',
  ];
}
