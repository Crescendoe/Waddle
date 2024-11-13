import 'package:flutter/material.dart';
import 'package:waterly/screens/congrats_screen.dart';
import 'package:waterly/screens/registration_screen.dart';
import 'package:waterly/screens/welcome_screen.dart';
import 'package:waterly/screens/questions_screen.dart';
import 'package:waterly/screens/home_screen.dart';
import 'package:waterly/screens/accountCreated_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waterly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/accountCreated': (context) => const AccountCreatedScreen(),
        '/questions': (context) => const QuestionsScreen(),
        '/home': (context) => const HomeScreen(
              waterGoal: 0.0,
            ),
        '/congrats': (context) => const CongratsScreen(),
      },
    );
  }
}
