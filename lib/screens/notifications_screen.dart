import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  bool notificationsEnabled = false;
  TimeOfDay? selectedTime;
  int? selectedInterval;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadInitialSettingsFromProvider();
    _ensureFcmPermissionsAndToken();
  }

  void _loadInitialSettingsFromProvider() {
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    setState(() {
      notificationsEnabled = waterTracker.notificationsEnabled;
      selectedTime = waterTracker.notificationTime;
      selectedInterval = waterTracker.notificationInterval;
    });
  }

  Future<void> _ensureFcmPermissionsAndToken() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      _logger.w("FCM notifications permissions are denied.");
    }
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null && notificationsEnabled) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
        _logger.d("FCM token verified/updated during settings check: $token");
      }
    }
  }

  Future<void> _saveSettingsAndPreferences() async {
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    waterTracker.notificationsEnabled = notificationsEnabled;
    waterTracker.notificationTime = selectedTime;
    waterTracker.notificationInterval = selectedInterval;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logger.w("No user logged in. Cannot save FCM notification settings.");
      return;
    }

    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmSettings': {
          'notificationsEnabled': notificationsEnabled,
          'dailyReminderTime': selectedTime != null
              ? {'hour': selectedTime!.hour, 'minute': selectedTime!.minute}
              : null,
          'reminderIntervalMinutes': selectedInterval,
        },
        'fcmToken': fcmToken,
      }, SetOptions(merge: true));

      _logger.d('FCM notification preferences saved to Firestore.');
      _logger.d(
          'Enabled: $notificationsEnabled, Time: $selectedTime, Interval: $selectedInterval');

      if (notificationsEnabled) {
        await FirebaseMessaging.instance
            .subscribeToTopic('user_reminders_${user.uid}');
        await FirebaseMessaging.instance
            .subscribeToTopic('all_users_reminders');
        _logger.d('Subscribed to FCM topics.');
      } else {
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('user_reminders_${user.uid}');
        await FirebaseMessaging.instance
            .unsubscribeFromTopic('all_users_reminders');
        _logger.d('Unsubscribed from FCM topics.');
      }
    } catch (e) {
      _handleFirestoreError(e);
    }
  }

  void _handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      _logger.e('Firestore Error (${error.code}): ${error.message}');
    } else {
      _logger.e('Generic Firestore Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Reminder Notifications'),
              value: notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  notificationsEnabled = value;
                });
                await _saveSettingsAndPreferences();
              },
            ),
            if (notificationsEnabled) ...[
              const SizedBox(height: 20.0),
              ListTile(
                  title: const Text('Preferred Daily Reminder Time'),
                  subtitle: Text(selectedTime != null
                      ? 'Approx. at ${selectedTime!.format(context)}'
                      : 'Not set'),
                  trailing: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime:
                            selectedTime ?? TimeOfDay(hour: 8, minute: 0),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                        await _saveSettingsAndPreferences();
                      }
                    },
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime:
                          selectedTime ?? TimeOfDay(hour: 8, minute: 0),
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                      await _saveSettingsAndPreferences();
                    }
                  }),
              const SizedBox(height: 16.0),
              ListTile(
                title: const Text('Preferred Reminder Interval'),
                subtitle: Text(selectedInterval != null
                    ? 'Approx. every $selectedInterval minutes'
                    : 'Not set'),
                trailing: DropdownButton<int>(
                  value: selectedInterval,
                  hint: const Text("Select"),
                  items: [15, 30, 60, 90, 120]
                      .map((interval) => DropdownMenuItem<int>(
                            value: interval,
                            child: Text('$interval min'),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        selectedInterval = value;
                      });
                      await _saveSettingsAndPreferences();
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Note: Notifications are sent by our server based on these preferences. "
                "Actual delivery may vary slightly. Ensure your app has internet access "
                "and notification permissions enabled in your phone's settings.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                    "Reminder notifications are currently disabled. Enable them to receive "
                    "hydration reminders via push notifications."),
              )
            ],
          ],
        ),
      ),
    );
  }
}
