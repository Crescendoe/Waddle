import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Import Firebase Messaging

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  RegistrationScreenState createState() => RegistrationScreenState();
}

class RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _saveUserToFirestore(String email, String username) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;

        // Get FCM token
        String? fcmToken;
        try {
          // Request permission for iOS and web if not already granted
          // For Android, this is not strictly necessary for getToken but good practice for notifications overall
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

          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            fcmToken = await FirebaseMessaging.instance.getToken();
            print('FCM Token retrieved: $fcmToken');
          } else {
            print('User declined or has not accepted FCM permission');
          }
        } catch (e) {
          print('Error getting FCM token: $e');
        }

        // Default FCM settings
        Map<String, dynamic> fcmSettings = {
          'notificationsEnabled':
              false, // Default to false, user can enable later
          'dailyReminderTime': null, // e.g., { 'hour': 9, 'minute': 0 }
          'reminderIntervalMinutes': null, // e.g., 60
          'timezone': null, // Can be set later by the app
        };

        // First, ensure the user document is created
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'username': username,
          'currentStreak': 0,
          'recordStreak': 0,
          'completedChallenges': 0,
          'companionsCollected': 0,
          'waterConsumed': 0.0,
          'waterGoal': 0.0,
          'goalMetToday': false,
          'nextEntryTime': DateTime.now().toIso8601String(),
          'lastResetDate': DateTime.now().toIso8601String(),
          // 'notificationTime': null, // Replaced by fcmSettings
          // 'notificationInterval': null, // Replaced by fcmSettings
          'activeChallengeIndex': null,
          'challenge1Active': false,
          'challenge2Active': false,
          'challenge3Active': false,
          'challenge4Active': false,
          'challenge5Active': false,
          'challenge6Active': false,
          'rememberMe': false,
          'challengeFailed': false,
          'challengeCompleted': false,
          'daysLeft': 14,
          // Add FCM related fields
          'fcmToken': fcmToken,
          'fcmTokenTimestamp': FieldValue.serverTimestamp(),
          'fcmSettings': fcmSettings,
        });

        // Then, create the waterLogs sub-collection for the user
        // This line is not strictly necessary as Firestore creates subcollections when you write to them.
        // However, it doesn't hurt.
        // await FirebaseFirestore.instance
        //     .collection('users')
        //     .doc(uid)
        //     .collection('waterLogs');
        // You can remove the above if you prefer, as adding a log later will create it.
      }
    } catch (e) {
      print('Error saving user data: $e'); // Log the error for debugging
      throw e; // Re-throw the error to be caught in the _register method
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return; // If form is not valid, don't proceed
    }
    setState(() {
      _isLoading = true; // Start loading
    });
    try {
      // Create user with Firebase Auth
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // User is now available in userCredential.user
      // Save user data to Firestore, including FCM token
      if (userCredential.user != null) {
        await _saveUserToFirestore(
            _emailController.text.trim(), _usernameController.text.trim());

        // No need to signInWithEmailAndPassword again, createUserWithEmailAndPassword already signs the user in.
        // The current user is FirebaseAuth.instance.currentUser or userCredential.user.

        // Navigate to questions screen
        if (mounted) {
          // Consider popping all routes until login/welcome if registration is deep in nav stack
          // Or simply replace to ensure user can't go back to registration
          Navigator.of(context).pushNamedAndRemoveUntil(
              '/accountCreated', (Route<dynamic> route) => false);
        }
      } else {
        throw Exception("User creation succeeded but user object is null.");
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      } else {
        message = 'An error occurred during registration. Please try again.';
        print('FirebaseAuthException code: ${e.code}, message: ${e.message}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print('Error during registration: $e'); // Log the error for debugging
      if (mounted) {
        if (e.toString().contains('network-request-failed')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Account Creation Failed'),
              content: const Text(
                  'Unable to connect to the server. Please check your internet connection and try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'An error occurred: ${e.toString().substring(0, (e.toString().length > 100) ? 100 : e.toString().length)}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(), // Optionally add a title: title: const Text('Register')
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Register',
                        style: GoogleFonts.cherryBombOne(
                          textStyle: Theme.of(context).textTheme.headlineMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your username';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]{3,15}$')
                              .hasMatch(value.trim())) {
                            return 'Username must be 3-15 characters and contain only letters and numbers';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          // Simpler password validation for now, adjust as needed
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          // Example: if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!?]{8,}$').hasMatch(value)) {
                          //   return 'Password must be 8+ chars, 1 letter, 1 number, ? or !';
                          // }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _register, // Disable button when loading
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text('Create Account'),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Disable button when loading
                                Navigator.pushNamed(context, '/login');
                              },
                        child: const Text('Already have an account? Log in'),
                      ),
                      const SizedBox(height: 10),
                      // Ensure the image path is correct and the asset is in pubspec.yaml
                      // Image.asset(
                      //     'lib/assets/images/wade_sitting_looking_up.png',
                      //     height: 100),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
