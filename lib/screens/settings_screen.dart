import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
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
                          Text('Version: 0.1.0'),
                          SizedBox(height: 10),
                          Text('Developed by: William Wyler'),
                          SizedBox(height: 10),
                          Text(
                              'Built for   BPA 24-25 PS WSAP Mobile Applications '),
                          Text('Credits:'),
                          Text(' - Developer: William Wyler'),
                          Text(' - Art: Kaylin Steppe-Mize'),
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
