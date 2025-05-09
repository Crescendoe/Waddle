import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isLoading = false; // Add this line

  Future<void> _saveUserToFirestore(String email, String username) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;

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
          'notificationTime': null,
          'notificationInterval': null,
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
        });

        // Then, create the waterLogs sub-collection for the user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('waterLogs');
      }
    } catch (e) {
      print('Error saving user data: $e'); // Log the error for debugging
      throw e; // Re-throw the error to be caught in the _register method
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await _saveUserToFirestore(
          _emailController.text, _usernameController.text);

      // Automatically log in the user
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Navigate to questions screen
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/accountCreated');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else {
        message = 'An unknown error occurred.';
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
          // Show a popup dialog for connection issues
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Account Creation Failed'),
              content: const Text(
                  'Unable to connect to the server. Please check your internet connection and try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred. Please try again.')),
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
      appBar: AppBar(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          if (!RegExp(r'^[a-zA-Z0-9]{3,15}$').hasMatch(value)) {
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (!RegExp(
                                  r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d!?]{8,}$')
                              .hasMatch(value)) {
                            return 'Password must be 8+ chars, 1 letter, 1 number, ? or !';
                          }
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
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await _register();
                          }
                        },
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
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text('Already have an account? Log in'),
                      ),
                      const SizedBox(height: 10),
                      Image.asset(
                          'lib/assets/images/wade_sitting_looking_up.png',
                          height: 100),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
