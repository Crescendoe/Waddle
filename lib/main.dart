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
  bool rememberMe =
      prefs.getBool('rememberMe') ?? false; // Retrieve rememberMe state
  String? savedUid = prefs.getString('savedUid'); // Retrieve saved UID

  User? user;
  if (rememberMe && savedUid != null) {
    // Automatically log in the user if rememberMe is true and UID is saved
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(savedUid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      user = FirebaseAuth.instance.currentUser;
    }
  } else {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        // Save rememberMe and UID locally
        await prefs.setBool('rememberMe', rememberMe);
        await prefs.setString('savedUid', uid);
      }
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => WaterTracker(username: savedUid ?? user?.uid ?? '')
        ..loadWaterData(), // Ensure data is loaded after initialization
      child: MyApp(rememberMe: rememberMe),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool rememberMe;

  const MyApp({super.key, required this.rememberMe});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waddle',
      debugShowCheckedModeBanner: false,
      initialRoute: !rememberMe ? '/' : '/home', // Adjust initial route
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
