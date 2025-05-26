import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FCM
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notifications
import 'package:waterly/firebase_options.dart'; // Import Firebase Options
import 'package:waterly/models/water_tracker.dart';
import 'package:waterly/screens/accountCreated_screen.dart';
import 'package:waterly/screens/congrats_screen.dart';
import 'package:waterly/screens/login_screen.dart';
import 'package:waterly/screens/main_screen.dart';
import 'package:waterly/screens/notifications_screen.dart';
import 'package:waterly/screens/questions_screen.dart';
import 'package:waterly/screens/registration_screen.dart';
import 'package:waterly/screens/results_screen.dart';
import 'package:waterly/screens/settings_screen.dart';
import 'package:waterly/screens/welcome_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:waterly/screens/forgot_password_screen.dart';
import 'package:logger/logger.dart';

// Initialize Logger
final Logger _logger = Logger();

/// Define a top-level named handler which background/terminated messages will
/// call.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _logger.i('Handling a background message: ${message.messageId}');
  _logger.d('Background Message data: ${message.data}');
  if (message.notification != null) {
    _logger.d(
        'Background Message also contained a notification: ${message.notification!.title}');
  }
}

/// Create a [AndroidNotificationChannel] for heads up notifications
late AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set the background messaging handler early on, as a top-level function
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // For iOS, request permission for foreground presentation options
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize SharedPreferences and user session
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool rememberMe = prefs.getBool('rememberMe') ?? false;
  String? savedUid;
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (rememberMe && prefs.getString('savedUid') != null) {
    savedUid = prefs.getString('savedUid');
  } else if (currentUser != null) {
    savedUid = currentUser.uid;
    if (rememberMe) {
      await prefs.setString('savedUid', savedUid!);
    }
  }

  final String effectiveUserId = savedUid ?? '';

  runApp(
    ChangeNotifierProvider(
      create: (context) => WaterTracker(username: effectiveUserId)
        ..loadWaterData(), // WaterTracker's _initialize will call loadWaterData
      child: MyApp(rememberMe: rememberMe, currentUserId: effectiveUserId),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool rememberMe;
  final String currentUserId;

  const MyApp(
      {super.key, required this.rememberMe, required this.currentUserId});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupFCMInteractionsAndUserDataSync();
  }

  Future<void> _initializeLocalNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            'app_icon'); // Ensure 'app_icon.png' exists

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) {
      _logger.d(
          'flutter_local_notifications: onDidReceiveNotificationResponse triggered');
      String? payload = notificationResponse.payload;
      if (payload != null) {
        _logger.d('Notification payload: $payload');
        // TODO: Handle notification tap when app is in foreground (e.g., navigate)
      }
    },
        onDidReceiveBackgroundNotificationResponse:
            _onDidReceiveBackgroundNotificationResponse);
  }

  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    _logger.d(
        'flutter_local_notifications: onDidReceiveBackgroundNotificationResponse triggered');
    // Handle background tap for local notifications shown by this plugin.
  }

  Future<void> _setupFCMInteractionsAndUserDataSync() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    _logger.i('User granted FCM permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('FCM Permissions Authorized');
      if (widget.currentUserId.isNotEmpty) {
        await _ensureAndSyncUserData(widget.currentUserId);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _logger.i('FCM Token Refreshed: $newToken');
        if (widget.currentUserId.isNotEmpty) {
          _ensureAndSyncUserData(widget.currentUserId, freshToken: newToken);
        }
      });
    } else {
      _logger.w('FCM Permissions Denied or Not Determined');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.i('FCM onMessage received (foreground)');
      RemoteNotification? notification = message.notification;
      if (notification != null && mounted) {
        _logger.d(
            'Foreground message also contained a notification: ${notification.title}');
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: 'app_icon',
              playSound: true,
              enableVibration: true,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data['payload'] as String? ?? message.messageId,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _logger.i('FCM onMessageOpenedApp received (app was in background)');
      _logger.d('Message data: ${message.data}');
      // TODO: Navigate based on message data
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        _logger.i('FCM getInitialMessage received (app was terminated)');
        _logger.d('Message data: ${message.data}');
        // TODO: Navigate based on message data (often needs a delay or post-frame callback)
      }
    });
  }

  Future<void> _ensureAndSyncUserData(String userId,
      {String? freshToken}) async {
    if (userId.isEmpty) {
      _logger.w('User ID is empty, cannot sync user data.');
      return;
    }

    try {
      String? currentFcmToken =
          freshToken ?? await FirebaseMessaging.instance.getToken();

      if (currentFcmToken == null) {
        _logger.w(
            'Failed to get FCM token for user $userId. FCM token field may not be updated.');
      }

      _logger.i('Ensuring user data and FCM token for user $userId.');
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      DocumentSnapshot userDocSnapshot = await userDocRef.get();

      Map<String, dynamic> dataToUpdate = {};

      if (currentFcmToken != null) {
        dataToUpdate['fcmToken'] = currentFcmToken;
      }
      dataToUpdate['fcmTokenTimestamp'] = FieldValue.serverTimestamp();

      final Map<String, dynamic> defaultExpectedFields = {
        'currentStreak': 0,
        'recordStreak': 0,
        'completedChallenges': 0,
        'companionsCollected': 0,
        'waterConsumed': 0.0,
        'waterGoal': 2000.0,
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
        'fcmSettings': {
          'notificationsEnabled': false,
          'dailyReminderTime': null,
          'reminderIntervalMinutes': null,
          'timezone': null,
        },
      };

      if (userDocSnapshot.exists) {
        Map<String, dynamic>? existingUserData =
            userDocSnapshot.data() as Map<String, dynamic>?;
        if (existingUserData != null) {
          defaultExpectedFields.forEach((key, defaultValue) {
            if (!existingUserData.containsKey(key)) {
              dataToUpdate[key] = defaultValue;
              _logger.d(
                  'User $userId: Adding missing field "$key" with default: $defaultValue');
            }
          });

          if (!existingUserData.containsKey('lastResetDate')) {
            dataToUpdate['lastResetDate'] = DateTime.now().toIso8601String();
            _logger.d(
                'User $userId: Adding missing "lastResetDate" with current time.');
          }
          if (!existingUserData.containsKey('nextEntryTime')) {
            dataToUpdate['nextEntryTime'] = DateTime.now().toIso8601String();
            _logger.d(
                'User $userId: Adding missing "nextEntryTime" with current time (adjust if null is valid).');
          }
          if (!existingUserData.containsKey('email') &&
              FirebaseAuth.instance.currentUser?.email != null) {
            dataToUpdate['email'] = FirebaseAuth.instance.currentUser!.email;
            _logger.d('User $userId: Adding missing "email" from Auth.');
          }
          if (!existingUserData.containsKey('username')) {
            _logger.w(
                'User $userId: Missing "username" field. It was not defaulted.');
          }
        }
      } else {
        _logger.w(
            'User document for $userId does not exist in Firestore. Creating with defaults.');
        defaultExpectedFields.forEach((key, defaultValue) {
          dataToUpdate[key] = defaultValue;
        });
        dataToUpdate['lastResetDate'] = DateTime.now().toIso8601String();
        dataToUpdate['nextEntryTime'] = DateTime.now().toIso8601String();
        if (FirebaseAuth.instance.currentUser?.email != null) {
          dataToUpdate['email'] = FirebaseAuth.instance.currentUser!.email;
        }
        // Username would be missing if creating doc here unless fetched from registration input
        // For simplicity, if doc doesn't exist, we're only adding known defaults + auth email
      }

      if (dataToUpdate.isNotEmpty) {
        await userDocRef.set(dataToUpdate, SetOptions(merge: true));
        _logger.d('User data sync and backfill complete for user $userId.');
      }
    } catch (e) {
      _logger.e('Error ensuring/syncing user data for user $userId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    String determinedInitialRoute = '/';
    if (widget.currentUserId.isNotEmpty) {
      // If there's an effective user ID, go to home
      determinedInitialRoute = '/home';
    }
    // Note: widget.rememberMe might further influence this if you have a scenario where
    // currentUserId is empty but rememberMe implies a previous state.
    // However, currentUserId being non-empty is a stronger indicator of an active session.

    return MaterialApp(
      title: 'Waddle',
      debugShowCheckedModeBanner: false,
      initialRoute: determinedInitialRoute,
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/accountCreated': (context) => const AccountCreatedScreen(),
        '/questions': (context) => const QuestionsScreen(),
        '/home': (context) => const MainScreen(),
        '/congrats': (context) => const CongratsScreen(),
        '/results': (context) => const ResultsScreen(),
        '/login': (context) => const LoginScreen(),
        '/settings': (context) => SettingsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
