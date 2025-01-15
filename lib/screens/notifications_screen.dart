import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart'; // Add this import

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  NotificationsScreenState createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TimeOfDay? selectedTime;
  int? selectedInterval;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    tz.initializeTimeZones(); // Initialize timezone
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    selectedTime = waterTracker.notificationTime;
    selectedInterval = waterTracker.notificationInterval;
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            'app_icon'); // Ensure 'app_icon' is correct
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permissions
    try {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print("Notification permissions granted");
      } else {
        print("Notification permissions denied");
      }
    } on PlatformException catch (e) {
      print("Error requesting notification permissions: $e");
    }
  }

  Future<void> _scheduleDailyNotification(TimeOfDay time) async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final newStatus = await Permission.notification.request();
      if (!newStatus.isGranted) {
        print("Notification permissions denied");
        return;
      }
    }

    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    waterTracker.notificationTime = time;
    await waterTracker.saveWaterData();

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

    print("Scheduling daily notification at ${time.format(context)}");
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Water Reminder',
      'Time to drink water!',
      scheduledDate, // Correctly passing the scheduled time with timezone
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Schedule daily
    );
    print("Daily notification scheduled");
  }

  Future<void> _scheduleIntervalNotification(int interval) async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final newStatus = await Permission.notification.request();
      if (!newStatus.isGranted) {
        print("Notification permissions denied");
        return;
      }
    }

    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    waterTracker.notificationInterval = interval;
    await waterTracker.saveWaterData();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'interval_reminder_channel', // Correct ID
      'Interval Reminder',
      channelDescription: 'Channel for interval water reminder',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Schedule the periodic notification
    print("Scheduling interval notification every $interval minutes");
    await flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      'Water Reminder',
      'Time to drink water!',
      _convertToRepeatInterval(
          interval), // Convert the interval to RepeatInterval
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    print("Interval notification scheduled");
  }

  RepeatInterval _convertToRepeatInterval(int interval) {
    // Convert custom minutes into RepeatInterval
    switch (interval) {
      case 15:
        return RepeatInterval
            .everyMinute; // Note: Flutter has limited intervals
      case 30:
        return RepeatInterval.everyMinute; // No native 30-minute interval
      case 60:
        return RepeatInterval.hourly;
      case 120:
        return RepeatInterval.hourly; // No native 2-hour interval
      default:
        return RepeatInterval.hourly;
    }
  }

  Future<void> _cancelNotifications() async {
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    waterTracker.notificationTime = null;
    waterTracker.notificationInterval = null;
    await waterTracker.saveWaterData();
    print("Cancelling all notifications");
    await flutterLocalNotificationsPlugin.cancelAll();
    print("All notifications cancelled");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Daily Reminder'),
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
                    await _scheduleDailyNotification(time);
                  }
                },
              ),
            ),
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
                    await _scheduleIntervalNotification(value);
                  }
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _cancelNotifications();
                setState(() {
                  selectedTime = null;
                  selectedInterval = null;
                });
              },
              child: const Text('Cancel All Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
