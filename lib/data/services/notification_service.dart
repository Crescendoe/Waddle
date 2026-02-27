import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages all local hydration reminder notifications.
///
/// Persists user preferences to SharedPreferences and schedules/cancels
/// notifications via flutter_local_notifications accordingly.
class NotificationService {
  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin;

  // ── SharedPreferences keys ──
  static const _kEnabled = 'notif_enabled';
  static const _kIntervalHours = 'notif_interval_hours';
  static const _kMorningEnabled = 'notif_morning_enabled';
  static const _kMorningHour = 'notif_morning_hour';
  static const _kMorningMinute = 'notif_morning_minute';
  static const _kEveningEnabled = 'notif_evening_enabled';
  static const _kEveningHour = 'notif_evening_hour';
  static const _kEveningMinute = 'notif_evening_minute';
  static const _kGoalAlert = 'notif_goal_alert';
  static const _kHalfwayAlert = 'notif_halfway_alert';
  static const _kStreakReminder = 'notif_streak_reminder';
  static const _kSmartFrequency = 'notif_smart_frequency';
  static const _kSoundEnabled = 'notif_sound';
  static const _kVibrationEnabled = 'notif_vibration';
  static const _kQuietHoursEnabled = 'notif_quiet_hours_enabled';
  static const _kQuietStartHour = 'notif_quiet_start_hour';
  static const _kQuietStartMinute = 'notif_quiet_start_min';
  static const _kQuietEndHour = 'notif_quiet_end_hour';
  static const _kQuietEndMinute = 'notif_quiet_end_min';
  static const _kActiveStartHour = 'notif_active_start_hour';
  static const _kActiveEndHour = 'notif_active_end_hour';
  static const _kToneStyle =
      'notif_tone_style'; // friendly / minimal / motivational

  // ── Notification IDs ──
  static const int _morningId = 1001;
  static const int _eveningId = 1002;
  static const int _streakReminderId = 1003;
  static const int _intervalBaseId = 2000;

  // ── Channel info ──
  static const _channelId = 'hydration_reminders';
  static const _channelName = 'Hydration Reminders';
  static const _channelDesc = 'Reminds you to drink water throughout the day';
  static const _silentChannelId = 'hydration_silent';
  static const _silentChannelName = 'Silent Reminders';
  static const _silentChannelDesc = 'Low-priority hydration nudges';

  NotificationService({
    required SharedPreferences prefs,
    FlutterLocalNotificationsPlugin? plugin,
  })  : _prefs = prefs,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  // ══════════════════════════════════════════════════════════════
  // Getters (read persisted settings)
  // ══════════════════════════════════════════════════════════════

  bool get isEnabled => _prefs.getBool(_kEnabled) ?? true;
  int get intervalHours => _prefs.getInt(_kIntervalHours) ?? 2;

  // Morning / Evening
  bool get morningEnabled => _prefs.getBool(_kMorningEnabled) ?? true;
  int get morningHour => _prefs.getInt(_kMorningHour) ?? 8;
  int get morningMinute => _prefs.getInt(_kMorningMinute) ?? 0;
  bool get eveningEnabled => _prefs.getBool(_kEveningEnabled) ?? false;
  int get eveningHour => _prefs.getInt(_kEveningHour) ?? 20;
  int get eveningMinute => _prefs.getInt(_kEveningMinute) ?? 0;

  // Alerts
  bool get goalAlert => _prefs.getBool(_kGoalAlert) ?? true;
  bool get halfwayAlert => _prefs.getBool(_kHalfwayAlert) ?? true;
  bool get streakReminder => _prefs.getBool(_kStreakReminder) ?? true;

  // Smart & Style
  bool get smartFrequency => _prefs.getBool(_kSmartFrequency) ?? false;
  String get toneStyle => _prefs.getString(_kToneStyle) ?? 'friendly';

  // Sound & Vibration
  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? true;
  bool get vibrationEnabled => _prefs.getBool(_kVibrationEnabled) ?? true;

  // Quiet Hours
  bool get quietHoursEnabled => _prefs.getBool(_kQuietHoursEnabled) ?? false;
  int get quietStartHour => _prefs.getInt(_kQuietStartHour) ?? 22;
  int get quietStartMinute => _prefs.getInt(_kQuietStartMinute) ?? 0;
  int get quietEndHour => _prefs.getInt(_kQuietEndHour) ?? 7;
  int get quietEndMinute => _prefs.getInt(_kQuietEndMinute) ?? 0;

  // Active window (which hours interval reminders fire)
  int get activeStartHour => _prefs.getInt(_kActiveStartHour) ?? 7;
  int get activeEndHour => _prefs.getInt(_kActiveEndHour) ?? 21;

  // ══════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      debugPrint('Timezone detection failed, using UTC fallback: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Create channels
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );
    await androidImpl?.createNotificationChannel(
      const AndroidNotificationChannel(
        _silentChannelId,
        _silentChannelName,
        description: _silentChannelDesc,
        importance: Importance.low,
      ),
    );

    const androidSettings = AndroidInitializationSettings('app_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      await androidImpl?.requestNotificationsPermission();
    }

    await rescheduleAll();
  }

  // ══════════════════════════════════════════════════════════════
  // Setters (persist + reschedule)
  // ══════════════════════════════════════════════════════════════

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(_kEnabled, value);
    await rescheduleAll();
  }

  Future<void> setIntervalHours(int hours) async {
    await _prefs.setInt(_kIntervalHours, hours);
    await rescheduleAll();
  }

  Future<void> setMorningReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    await _prefs.setBool(_kMorningEnabled, enabled);
    if (hour != null) await _prefs.setInt(_kMorningHour, hour);
    if (minute != null) await _prefs.setInt(_kMorningMinute, minute);
    await rescheduleAll();
  }

  Future<void> setEveningReminder({
    required bool enabled,
    int? hour,
    int? minute,
  }) async {
    await _prefs.setBool(_kEveningEnabled, enabled);
    if (hour != null) await _prefs.setInt(_kEveningHour, hour);
    if (minute != null) await _prefs.setInt(_kEveningMinute, minute);
    await rescheduleAll();
  }

  Future<void> setGoalAlert(bool value) async {
    await _prefs.setBool(_kGoalAlert, value);
  }

  Future<void> setHalfwayAlert(bool value) async {
    await _prefs.setBool(_kHalfwayAlert, value);
  }

  Future<void> setStreakReminder(bool value) async {
    await _prefs.setBool(_kStreakReminder, value);
    await rescheduleAll();
  }

  Future<void> setSmartFrequency(bool value) async {
    await _prefs.setBool(_kSmartFrequency, value);
    await rescheduleAll();
  }

  Future<void> setToneStyle(String style) async {
    await _prefs.setString(_kToneStyle, style);
    // No reschedule needed — tone applied at display time
  }

  Future<void> setSoundEnabled(bool value) async {
    await _prefs.setBool(_kSoundEnabled, value);
    // Channel controls sound on Android; reschedule not needed
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _prefs.setBool(_kVibrationEnabled, value);
  }

  Future<void> setQuietHours({
    required bool enabled,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
  }) async {
    await _prefs.setBool(_kQuietHoursEnabled, enabled);
    if (startHour != null) await _prefs.setInt(_kQuietStartHour, startHour);
    if (startMinute != null) {
      await _prefs.setInt(_kQuietStartMinute, startMinute);
    }
    if (endHour != null) await _prefs.setInt(_kQuietEndHour, endHour);
    if (endMinute != null) await _prefs.setInt(_kQuietEndMinute, endMinute);
    await rescheduleAll();
  }

  Future<void> setActiveWindow(
      {required int startHour, required int endHour}) async {
    await _prefs.setInt(_kActiveStartHour, startHour);
    await _prefs.setInt(_kActiveEndHour, endHour);
    await rescheduleAll();
  }

  // ══════════════════════════════════════════════════════════════
  // Immediate notifications (goal met, halfway, etc.)
  // ══════════════════════════════════════════════════════════════

  Future<void> showGoalReachedNotification() async {
    if (!isEnabled || !goalAlert) return;
    if (_isInQuietHours()) return;

    final msgs = _goalMessages();
    await _plugin.show(9999, msgs.$1, msgs.$2, _notificationDetails());
  }

  Future<void> showHalfwayNotification() async {
    if (!isEnabled || !halfwayAlert) return;
    if (_isInQuietHours()) return;

    final msgs = _halfwayMessages();
    await _plugin.show(9998, msgs.$1, msgs.$2, _notificationDetails());
  }

  Future<void> showFCMNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _notificationDetails());
  }

  // ══════════════════════════════════════════════════════════════
  // Core scheduling engine
  // ══════════════════════════════════════════════════════════════

  Future<void> rescheduleAll() async {
    await _plugin.cancelAll();
    if (!isEnabled) return;

    await _scheduleIntervalReminders();

    if (morningEnabled) {
      final msgs = _morningMessages();
      await _scheduleDailyNotification(
        id: _morningId,
        hour: morningHour,
        minute: morningMinute,
        title: msgs.$1,
        body: msgs.$2,
      );
    }

    if (eveningEnabled) {
      final msgs = _eveningMessages();
      await _scheduleDailyNotification(
        id: _eveningId,
        hour: eveningHour,
        minute: eveningMinute,
        title: msgs.$1,
        body: msgs.$2,
      );
    }

    if (streakReminder) {
      // Schedule a daily 2pm nudge for streak protection
      await _scheduleDailyNotification(
        id: _streakReminderId,
        hour: 14,
        minute: 0,
        title: _streakTitle(),
        body: _streakBody(),
      );
    }
  }

  Future<void> _scheduleIntervalReminders() async {
    final interval = intervalHours;
    final start = activeStartHour;
    final end = activeEndHour;
    int slotIndex = 0;
    for (int hour = start; hour <= end; hour += interval) {
      if (_isHourInQuietWindow(hour)) continue;

      final msgs = _intervalMessages(slotIndex);
      await _scheduleDailyNotification(
        id: _intervalBaseId + slotIndex,
        hour: hour,
        minute: 0,
        title: msgs.$1,
        body: msgs.$2,
      );
      slotIndex++;
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Quiet hours helpers
  // ══════════════════════════════════════════════════════════════

  bool _isInQuietHours() {
    if (!quietHoursEnabled) return false;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final startMin = quietStartHour * 60 + quietStartMinute;
    final endMin = quietEndHour * 60 + quietEndMinute;
    if (startMin <= endMin) {
      return nowMin >= startMin && nowMin < endMin;
    }
    // Wraps midnight (e.g. 22:00 → 07:00)
    return nowMin >= startMin || nowMin < endMin;
  }

  bool _isHourInQuietWindow(int hour) {
    if (!quietHoursEnabled) return false;
    final startMin = quietStartHour * 60 + quietStartMinute;
    final endMin = quietEndHour * 60 + quietEndMinute;
    final hMin = hour * 60;
    if (startMin <= endMin) {
      return hMin >= startMin && hMin < endMin;
    }
    return hMin >= startMin || hMin < endMin;
  }

  // ══════════════════════════════════════════════════════════════
  // Notification details (respects sound/vibration prefs)
  // ══════════════════════════════════════════════════════════════

  NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'app_icon',
        playSound: soundEnabled,
        enableVibration: vibrationEnabled,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: soundEnabled,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Tone-aware message system
  // ══════════════════════════════════════════════════════════════

  (String, String) _intervalMessages(int slot) {
    switch (toneStyle) {
      case 'minimal':
        return _minimalInterval(slot);
      case 'motivational':
        return _motivationalInterval(slot);
      default:
        return _friendlyInterval(slot);
    }
  }

  (String, String) _morningMessages() {
    switch (toneStyle) {
      case 'minimal':
        return ('Morning', 'Time to hydrate.');
      case 'motivational':
        return (
          'Rise & Hydrate! 💪',
          'Champions start the day with water. Let\'s go!'
        );
      default:
        return (
          'Good Morning! ☀️',
          'Start your day right — drink a glass of water!'
        );
    }
  }

  (String, String) _eveningMessages() {
    switch (toneStyle) {
      case 'minimal':
        return ('Evening', 'Log your last drinks.');
      case 'motivational':
        return (
          'Final Round! 🏆',
          'Finish strong — every ounce counts toward your goal!'
        );
      default:
        return (
          'Evening Check-in 🌙',
          'How\'s your hydration? Log your last drinks for the day.'
        );
    }
  }

  (String, String) _goalMessages() {
    switch (toneStyle) {
      case 'minimal':
        return ('Goal met', 'Daily target reached.');
      case 'motivational':
        return (
          'CRUSHED IT! 🏅',
          'You demolished your water goal today. Legendary!'
        );
      default:
        return (
          'Goal Reached! 🎉',
          'Congratulations! You\'ve met your daily water goal!'
        );
    }
  }

  (String, String) _halfwayMessages() {
    switch (toneStyle) {
      case 'minimal':
        return ('50%', 'Halfway to your goal.');
      case 'motivational':
        return (
          'Halfway There! 🔥',
          'You\'re on fire — keep pushing to the finish line!'
        );
      default:
        return (
          'Halfway There! 💧',
          'Great progress! You\'re 50% to your daily goal.'
        );
    }
  }

  String _streakTitle() {
    switch (toneStyle) {
      case 'minimal':
        return 'Streak check';
      case 'motivational':
        return 'Protect Your Streak! 🔥';
      default:
        return 'Don\'t Break Your Streak! 🦆';
    }
  }

  String _streakBody() {
    switch (toneStyle) {
      case 'minimal':
        return 'Log a drink to keep your streak.';
      case 'motivational':
        return 'You\'ve worked too hard to lose it now — log a drink!';
      default:
        return 'Your duck is cheering you on — log a drink to keep going!';
    }
  }

  // ── Friendly tone (default) ──

  static (String, String) _friendlyInterval(int slot) {
    const msgs = [
      ('Time to Hydrate! 💧', 'Your body needs water — take a sip!'),
      ('Water Break! 🚰', 'A quick glass of water keeps you energized.'),
      (
        'Stay Hydrated! 💙',
        'Don\'t forget to hydrate! Your duck is counting on you.'
      ),
      ('Drink Up! 🥤', 'Keep the streak going — log a drink!'),
      (
        'Hydration Check! 🦆',
        'Staying hydrated helps you focus and feel great.'
      ),
      ('Water Time! 💦', 'Water is your superpower — drink some now!'),
      (
        'Sip Alert! 🌊',
        'Your hydration journey continues — one sip at a time.'
      ),
      ('Thirsty? 💧', 'A few ounces can make a big difference!'),
    ];
    final m = msgs[slot % msgs.length];
    return (m.$1, m.$2);
  }

  // ── Minimal tone ──

  static (String, String) _minimalInterval(int slot) {
    const msgs = [
      ('Water', 'Time for a drink.'),
      ('Hydrate', 'Take a sip.'),
      ('Reminder', 'Have some water.'),
      ('Water', 'Stay on track.'),
      ('Hydrate', 'Keep going.'),
      ('Water', 'Quick sip.'),
      ('Reminder', 'Drink up.'),
      ('Hydrate', 'Don\'t forget.'),
    ];
    final m = msgs[slot % msgs.length];
    return (m.$1, m.$2);
  }

  // ── Motivational tone ──

  static (String, String) _motivationalInterval(int slot) {
    const msgs = [
      ('Let\'s GO! 💪', 'Every sip fuels your greatness. Drink up!'),
      ('Stay Sharp! 🧠', 'Hydration = focus. You\'ve got this!'),
      ('Power Up! ⚡', 'Water is rocket fuel for your body. Launch it!'),
      ('Beast Mode! 🔥', 'Champions hydrate. Be a champion.'),
      ('Level Up! 🎮', 'One more glass and you\'re crushing it!'),
      ('No Excuses! 💯', 'Your future self will thank you. Drink now!'),
      ('Unstoppable! 🚀', 'Keep that momentum — grab some water!'),
      ('Winner\'s Move! 🏆', 'Successful people stay hydrated. That\'s you.'),
    ];
    final m = msgs[slot % msgs.length];
    return (m.$1, m.$2);
  }
}
