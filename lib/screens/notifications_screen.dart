import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones();
    final waterTracker = context.read<WaterTracker>();
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
        debugPrint('Notification clicked: ${response.payload}');
      },
    );

    if (initialized == null || !initialized) {
      debugPrint("Failed to initialize notifications");
    }

    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        debugPrint("Notification permissions granted");
      }
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
  }

  Future<void> _scheduleDailyNotification(TimeOfDay time) async {
    final now = TimeOfDay.now();
    final scheduledDate = tz.TZDateTime.now(tz.local).add(Duration(
        hours: time.hour - now.hour, minutes: time.minute - now.minute));

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder',
      channelDescription: 'Channel for daily water reminder',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Water Reminder',
      'Time to drink water and log your intake!',
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _saveSettingsToFirestore() async {
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    waterTracker.notificationsEnabled = notificationsEnabled;
    waterTracker.notificationTime = selectedTime;
    waterTracker.notificationInterval = selectedInterval;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(waterTracker.userId)
        .update({
      'notificationsEnabled': notificationsEnabled,
      'notificationTime': selectedTime != null
          ? {'hour': selectedTime!.hour, 'minute': selectedTime!.minute}
          : null,
      'notificationInterval': selectedInterval,
    });

    if (notificationsEnabled && selectedTime != null) {
      await _scheduleDailyNotification(selectedTime!);
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
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
                      initialTime: TimeOfDay.now(),
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
