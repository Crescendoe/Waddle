import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  bool rememberMe = false;
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final uid = user.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    rememberMe = userDoc['rememberMe'] ?? false;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) =>
          WaterTracker(username: FirebaseAuth.instance.currentUser?.uid ?? '')
            ..loadWaterData(),
      child: MyApp(
          isFirstTime: isFirstTime,
          isLoggedIn: isLoggedIn,
          rememberMe: rememberMe),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  final bool isLoggedIn;
  final bool rememberMe;

  const MyApp(
      {super.key,
      required this.isFirstTime,
      required this.isLoggedIn,
      required this.rememberMe});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waddle',
      debugShowCheckedModeBanner: false,
      initialRoute:
          isFirstTime || !isLoggedIn ? '/' : (rememberMe ? '/home' : '/login'),
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
