import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _debugTapCount = 0;
  bool _isDebugMenuVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Account Settings'),
                subtitle: Text('Update your account information'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AccountSettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.contact_support),
                title: Text('Contact Support'),
                subtitle: Text('Reach out for support or help'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Contact Support'),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text('Email: crescendoedd@gmail.com'),
                              SizedBox(height: 10),
                              Text('Github: @crescendoe'),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                subtitle: Text('Learn more about the app'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('About This App'),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text('App Name: Waddle'),
                              SizedBox(height: 10),
                              Text('Version: 0.2.1'),
                              SizedBox(height: 10),
                              Text('Developed by: William Wyler'),
                              SizedBox(height: 10),
                              Text(
                                  'Built for   BPA 24-25 PS WSAP Mobile Applications '),
                              SizedBox(height: 10),
                              Text('Credits:'),
                              Text(' - Developer: William Wyler'),
                              Text(' - Art: @Boopintroop'),
                              Text(' - Instructor: James Calkins'),
                              SizedBox(height: 10),
                              Text('Technical Details:'),
                              Text(' - Flutter SDK: 2.5.0'),
                              Text(' - Dart SDK: 2.14.0'),
                              Text(' - Firebase: Auth, Firestore'),
                              Text(' - State Management: Provider'),
                              Text(' - Local Storage: Shared Preferences'),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: Text('Close'),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text('Logout'),
                onTap: () => _logout(context),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _debugTapCount++;
                  if (_debugTapCount >= 10) {
                    _isDebugMenuVisible = true;
                  }
                });
              },
              child: Icon(Icons.opacity, size: 40, color: Colors.blueAccent),
            ),
          ),
          if (_isDebugMenuVisible)
            Center(
              child: AlertDialog(
                title: Text('Debug Menu'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text('Disable Next Entry Timer'),
                      value: context.read<WaterTracker>().nextEntryTime == null,
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            context.read<WaterTracker>().nextEntryTime = null;
                          } else {
                            context.read<WaterTracker>().nextEntryTime =
                                DateTime.now().add(Duration(minutes: 15));
                          }
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isDebugMenuVisible = false;
                        _debugTapCount = 0;
                      });
                    },
                    child: Text('Close'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _logout(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'rememberMe': false,
      });
    }

    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('remembered_email');
    await prefs.remove('remembered_password');
    Navigator.pushReplacementNamed(context, '/login');
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Edit Profile'),
            subtitle: Text('Update your profile information'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Edit Profile'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text('Profile editing form goes here.'),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text('Change Password'),
            subtitle: Text('Update your password'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Change Password'),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text('Password change form goes here.'),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
