import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart'; // Import Logger

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool notificationsEnabled = false;
  TimeOfDay? selectedTime;
  int? selectedInterval;
  final Logger _logger = Logger(); // Initialize Logger

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones();
    _loadInitialSettings(); // Load settings in initState
  }

  void _loadInitialSettings() {
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    notificationsEnabled = waterTracker.notificationsEnabled;
    selectedTime = waterTracker.notificationTime;
    selectedInterval = waterTracker.notificationInterval;
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _logger.d('Notification clicked: ${response.payload}');
      },
    );

    if (initialized == null || !initialized) {
      _logger.e("Failed to initialize notifications");
      return;
    }

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        _logger.d("Notification permissions granted");
      } else {
        _logger.w("Notification permissions denied: $status");
        setState(() {
          notificationsEnabled = false;
        });
        final waterTracker = Provider.of<WaterTracker>(context, listen: false);
        waterTracker.notificationsEnabled = false;
        await _saveSettingsToFirestore();
      }
    } catch (e) {
      _logger.e("Error requesting notification permissions: $e");
    }
  }

  Future<void> _scheduleDailyNotification(TimeOfDay time) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder',
      channelDescription: 'Channel for daily water reminder',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Time to drink water',
      enableVibration: true,
      playSound: true,
      onlyAlertOnce: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // Use a unique ID (0 for daily)
        'Water Reminder',
        'Time to drink water and log your intake!',
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      _logger.d('Daily notification scheduled for: $scheduledDate');
    } catch (e) {
      _logger.e('Error scheduling daily notification: $e');
    }
  }

  Future<void> _scheduleIntervalNotification(int interval) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'interval_reminder_channel',
      'Interval Reminder',
      channelDescription: 'Channel for interval water reminder',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ticker: 'Time to drink water',
      enableVibration: true,
      playSound: true,
      onlyAlertOnce: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    try {
      await flutterLocalNotificationsPlugin.periodicallyShow(
        1, // Use a different ID (1 for interval)
        'Water Reminder',
        'Drink water to stay hydrated!',
        RepeatInterval.everyMinute, // Use interval
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode
            .exactAllowWhileIdle, //for  interval notifications as well
      );
      _logger.d('Interval notification scheduled for every $interval minutes');
    } catch (e) {
      _logger.e('Error scheduling interval notification: $e');
    }
  }

  Future<void> _cancelNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    _logger.d('All notifications cancelled');
  }

  Future<void> _saveSettingsToFirestore() async {
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    waterTracker.notificationsEnabled = notificationsEnabled;
    waterTracker.notificationTime = selectedTime;
    waterTracker.notificationInterval = selectedInterval;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'notificationsEnabled': notificationsEnabled,
          'notificationTime': selectedTime != null
              ? {
                  'hour': selectedTime!.hour,
                  'minute': selectedTime!.minute
                } // Store as map
              : null,
          'notificationInterval': selectedInterval,
        });
        _logger.d('Firestore settings updated.');
      }
    } catch (e) {
      _handleFirestoreError(e);
    }
    await waterTracker.saveWaterData(); // Ensure shared preferences is updated
    _updateNotificationSchedule(); // Call this after saving to Firestore
  }

  void _updateNotificationSchedule() {
    if (notificationsEnabled) {
      if (selectedTime != null) {
        _scheduleDailyNotification(selectedTime!);
      }
      if (selectedInterval != null) {
        _scheduleIntervalNotification(selectedInterval!);
      }
    } else {
      _cancelNotifications();
    }
  }

  void _handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      _logger.e('Firestore Error (${error.code}): ${error.message}');
      switch (error.code) {
        case 'permission-denied':
          break;
        case 'not-found':
          break;
        default:
      }
    } else {
      _logger.e('Generic Firestore Error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  notificationsEnabled = value;
                });
                await _saveSettingsToFirestore();
              },
            ),
            if (notificationsEnabled) ...[
              const SizedBox(height: 20.0),
              ListTile(
                title: const Text('Daily Reminder Time'),
                subtitle: Text(selectedTime != null
                    ? 'Scheduled at ${selectedTime!.format(context)}'
                    : 'Not set'),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime ?? TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        selectedTime = time;
                      });
                      await _saveSettingsToFirestore();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                title: const Text('Interval Reminder'),
                subtitle: Text(selectedInterval != null
                    ? 'Every $selectedInterval minutes'
                    : 'Not set'),
                trailing: DropdownButton<int>(
                  value: selectedInterval,
                  items: [15, 30, 60, 120]
                      .map((interval) => DropdownMenuItem<int>(
                            value: interval,
                            child: Text('$interval minutes'),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        selectedInterval = value;
                      });
                      await _saveSettingsToFirestore();
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
