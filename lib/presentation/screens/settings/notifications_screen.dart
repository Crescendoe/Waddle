import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/notification_service.dart';
import 'package:waddle/presentation/widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _service;

  // Master
  late bool _remindersEnabled;
  // Schedule
  late int _intervalHours;
  late bool _morningReminder;
  late TimeOfDay _morningTime;
  late bool _eveningReminder;
  late TimeOfDay _eveningTime;
  late int _activeStartHour;
  late int _activeEndHour;
  // Alerts
  late bool _goalReminder;
  late bool _halfwayAlert;
  late bool _streakReminder;
  // Smart
  late bool _smartFrequency;
  late String _toneStyle;
  // Delivery
  late bool _soundEnabled;
  late bool _vibrationEnabled;
  // Quiet hours
  late bool _quietHoursEnabled;
  late TimeOfDay _quietStart;
  late TimeOfDay _quietEnd;

  @override
  void initState() {
    super.initState();
    _service = getIt<NotificationService>();
    _loadSettings();
  }

  void _loadSettings() {
    _remindersEnabled = _service.isEnabled;
    _intervalHours = _service.intervalHours;
    _morningReminder = _service.morningEnabled;
    _morningTime =
        TimeOfDay(hour: _service.morningHour, minute: _service.morningMinute);
    _eveningReminder = _service.eveningEnabled;
    _eveningTime =
        TimeOfDay(hour: _service.eveningHour, minute: _service.eveningMinute);
    _activeStartHour = _service.activeStartHour;
    _activeEndHour = _service.activeEndHour;
    _goalReminder = _service.goalAlert;
    _halfwayAlert = _service.halfwayAlert;
    _streakReminder = _service.streakReminder;
    _smartFrequency = _service.smartFrequency;
    _toneStyle = _service.toneStyle;
    _soundEnabled = _service.soundEnabled;
    _vibrationEnabled = _service.vibrationEnabled;
    _quietHoursEnabled = _service.quietHoursEnabled;
    _quietStart = TimeOfDay(
        hour: _service.quietStartHour, minute: _service.quietStartMinute);
    _quietEnd =
        TimeOfDay(hour: _service.quietEndHour, minute: _service.quietEndMinute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Master toggle ──
            _buildMasterToggle(),
            const SizedBox(height: 16),

            if (_remindersEnabled) ...[
              // ── Schedule section ──
              _sectionLabel('Schedule'),
              _buildIntervalCard(),
              const SizedBox(height: 12),
              _buildActiveWindowCard(),
              const SizedBox(height: 12),
              _buildScheduledRemindersCard(),
              const SizedBox(height: 20),

              // ── Alerts section ──
              _sectionLabel('Alerts & Milestones'),
              _buildAlertsCard(),
              const SizedBox(height: 20),

              // ── Personalization section ──
              _sectionLabel('Personalization'),
              _buildToneCard(),
              const SizedBox(height: 12),
              _buildSmartCard(),
              const SizedBox(height: 20),

              // ── Delivery section ──
              _sectionLabel('Delivery'),
              _buildDeliveryCard(),
              const SizedBox(height: 12),
              _buildQuietHoursCard(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Section builders
  // ══════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textHint,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildMasterToggle() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SwitchListTile(
        title: Text('Hydration Reminders',
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          _remindersEnabled
              ? 'You\'ll receive reminders throughout the day'
              : 'All notifications are paused',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        value: _remindersEnabled,
        onChanged: (v) {
          setState(() => _remindersEnabled = v);
          _service.setEnabled(v);
        },
        activeTrackColor: AppColors.primary,
        secondary: Icon(
          _remindersEnabled
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_rounded,
          color: _remindersEnabled ? AppColors.primary : AppColors.textHint,
        ),
      ),
    ).animate().fadeIn();
  }

  // ── Schedule cards ──

  Widget _buildIntervalCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reminder Frequency', style: AppTextStyles.labelLarge),
          const SizedBox(height: 4),
          Text('How often you\'d like a nudge',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Every $_intervalHours ${_intervalHours == 1 ? 'hour' : 'hours'}',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          Slider(
            value: _intervalHours.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: '$_intervalHours hr',
            onChanged: (v) {
              setState(() => _intervalHours = v.toInt());
              _service.setIntervalHours(v.toInt());
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Frequent',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint, fontSize: 11)),
              Text('Relaxed',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint, fontSize: 11)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildActiveWindowCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Active Hours', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Interval reminders only fire during this window',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _timeChip(
                  label: 'Start',
                  value: _formatHour(_activeStartHour),
                  onTap: () => _pickActiveHour(isStart: true),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 18, color: AppColors.textHint),
              ),
              Expanded(
                child: _timeChip(
                  label: 'End',
                  value: _formatHour(_activeEndHour),
                  onTap: () => _pickActiveHour(isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildScheduledRemindersCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _switchTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: Colors.amber,
            title: 'Morning Kickstart',
            subtitle: _morningReminder
                ? '${_formatTime(_morningTime)}  •  tap to change'
                : 'Off',
            value: _morningReminder,
            onChanged: (v) {
              setState(() => _morningReminder = v);
              _service.setMorningReminder(enabled: v);
            },
            onSubtitleTap:
                _morningReminder ? () => _pickTime(isMorning: true) : null,
          ),
          const Divider(height: 1, indent: 56),
          _switchTile(
            icon: Icons.nights_stay_rounded,
            iconColor: AppColors.primary,
            title: 'Evening Check-in',
            subtitle: _eveningReminder
                ? '${_formatTime(_eveningTime)}  •  tap to change'
                : 'Off',
            value: _eveningReminder,
            onChanged: (v) {
              setState(() => _eveningReminder = v);
              _service.setEveningReminder(enabled: v);
            },
            onSubtitleTap:
                _eveningReminder ? () => _pickTime(isMorning: false) : null,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ── Alerts card ──

  Widget _buildAlertsCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _switchTile(
            icon: Icons.celebration_rounded,
            iconColor: AppColors.accent,
            title: 'Goal Reached',
            subtitle: 'Celebrate hitting your daily target',
            value: _goalReminder,
            onChanged: (v) {
              setState(() => _goalReminder = v);
              _service.setGoalAlert(v);
            },
          ),
          const Divider(height: 1, indent: 56),
          _switchTile(
            icon: Icons.flag_rounded,
            iconColor: Colors.orange,
            title: 'Halfway There',
            subtitle: 'Get a boost when you hit 50%',
            value: _halfwayAlert,
            onChanged: (v) {
              setState(() => _halfwayAlert = v);
              _service.setHalfwayAlert(v);
            },
          ),
          const Divider(height: 1, indent: 56),
          _switchTile(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.deepOrange,
            title: 'Streak Protector',
            subtitle: 'Daily 2 PM check to protect your streak',
            value: _streakReminder,
            onChanged: (v) {
              setState(() => _streakReminder = v);
              _service.setStreakReminder(v);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── Tone card ──

  Widget _buildToneCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Notification Tone', style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text('Choose how your reminders talk to you',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _toneOption('friendly', 'Friendly', '🦆'),
              const SizedBox(width: 8),
              _toneOption('minimal', 'Minimal', '🔔'),
              const SizedBox(width: 8),
              _toneOption('motivational', 'Hype', '🔥'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _tonePreview(),
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildSmartCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _switchTile(
        icon: Icons.auto_awesome_rounded,
        iconColor: Colors.purple,
        title: 'Smart Frequency',
        subtitle: 'Fewer reminders on days you\'re already on track',
        value: _smartFrequency,
        onChanged: (v) {
          setState(() => _smartFrequency = v);
          _service.setSmartFrequency(v);
        },
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  // ── Delivery card ──

  Widget _buildDeliveryCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _switchTile(
            icon: Icons.volume_up_rounded,
            iconColor: AppColors.primary,
            title: 'Sound',
            subtitle: 'Play a sound with notifications',
            value: _soundEnabled,
            onChanged: (v) {
              setState(() => _soundEnabled = v);
              _service.setSoundEnabled(v);
            },
          ),
          const Divider(height: 1, indent: 56),
          _switchTile(
            icon: Icons.vibration_rounded,
            iconColor: AppColors.primary,
            title: 'Vibration',
            subtitle: 'Vibrate when a notification arrives',
            value: _vibrationEnabled,
            onChanged: (v) {
              setState(() => _vibrationEnabled = v);
              _service.setVibrationEnabled(v);
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildQuietHoursCard() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SwitchListTile(
            title: Row(
              children: [
                const Icon(Icons.do_not_disturb_on_rounded,
                    size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text('Quiet Hours',
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _quietHoursEnabled
                    ? 'No notifications ${_formatTime(_quietStart)} – ${_formatTime(_quietEnd)}'
                    : 'Silence notifications during sleep or focus time',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            value: _quietHoursEnabled,
            onChanged: (v) {
              setState(() => _quietHoursEnabled = v);
              _service.setQuietHours(enabled: v);
            },
            activeTrackColor: AppColors.primary,
          ),
          if (_quietHoursEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _timeChip(
                    label: 'From',
                    value: _formatTime(_quietStart),
                    onTap: () => _pickQuietTime(isStart: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 18, color: AppColors.textHint),
                ),
                Expanded(
                  child: _timeChip(
                    label: 'Until',
                    value: _formatTime(_quietEnd),
                    onTap: () => _pickQuietTime(isStart: false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  // ══════════════════════════════════════════════════════════════
  // Reusable widgets
  // ══════════════════════════════════════════════════════════════

  Widget _switchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onSubtitleTap,
  }) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title,
          style:
              AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: GestureDetector(
        onTap: onSubtitleTap,
        child: Text(subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: onSubtitleTap != null && value
                  ? AppColors.primary
                  : AppColors.textSecondary,
            )),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
    );
  }

  Widget _toneOption(String key, String label, String emoji) {
    final selected = _toneStyle == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _toneStyle = key);
          _service.setToneStyle(key);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeChip({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Pickers
  // ══════════════════════════════════════════════════════════════

  Future<void> _pickTime({required bool isMorning}) async {
    final initial = isMorning ? _morningTime : _eveningTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    setState(() {
      if (isMorning) {
        _morningTime = picked;
      } else {
        _eveningTime = picked;
      }
    });

    if (isMorning) {
      _service.setMorningReminder(
          enabled: true, hour: picked.hour, minute: picked.minute);
    } else {
      _service.setEveningReminder(
          enabled: true, hour: picked.hour, minute: picked.minute);
    }
  }

  Future<void> _pickActiveHour({required bool isStart}) async {
    final initial = isStart ? _activeStartHour : _activeEndHour;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial, minute: 0),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _activeStartHour = picked.hour;
      } else {
        _activeEndHour = picked.hour;
      }
    });
    _service.setActiveWindow(
        startHour: _activeStartHour, endHour: _activeEndHour);
  }

  Future<void> _pickQuietTime({required bool isStart}) async {
    final initial = isStart ? _quietStart : _quietEnd;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _quietStart = picked;
      } else {
        _quietEnd = picked;
      }
    });
    _service.setQuietHours(
      enabled: true,
      startHour: _quietStart.hour,
      startMinute: _quietStart.minute,
      endHour: _quietEnd.hour,
      endMinute: _quietEnd.minute,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Helpers
  // ══════════════════════════════════════════════════════════════

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatHour(int hour) {
    final tod = TimeOfDay(hour: hour, minute: 0);
    final h = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final p = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:00 $p';
  }

  String _tonePreview() {
    switch (_toneStyle) {
      case 'minimal':
        return '"Water — Time for a drink."';
      case 'motivational':
        return '"Let\'s GO! 💪 Every sip fuels your greatness!"';
      default:
        return '"Time to Hydrate! 💧 Your body needs water — take a sip!"';
    }
  }
}
