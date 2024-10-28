import 'package:flutter/material.dart';
import 'package:waterly/screens/welcome_screen.dart';
import 'package:waterly/screens/questions_screen.dart';
import 'package:waterly/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsApp.debugAllowBannerOverride = false;
    return MaterialApp(
      title: 'Waterly',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/questions': (context) => const QuestionsScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
