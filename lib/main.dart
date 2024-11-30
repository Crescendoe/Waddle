import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'package:waterly/screens/accountCreated_screen.dart';
import 'package:waterly/screens/congrats_screen.dart';
import 'package:waterly/screens/login_screen.dart';
import 'package:waterly/screens/main_screen.dart';
import 'package:waterly/screens/questions_screen.dart';
import 'package:waterly/screens/registration_screen.dart';
import 'package:waterly/screens/results_screen.dart';
import 'package:waterly/screens/welcome_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => WaterTracker()..loadWaterData(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waterly',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/accountCreated': (context) => const AccountCreatedScreen(),
        '/questions': (context) => const QuestionsScreen(),
        '/home': (context) => const MainScreen(),
        '/congrats': (context) => const CongratsScreen(),
        '/results': (context) => const ResultsScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
