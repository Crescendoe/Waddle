import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/debug_mode_service.dart';
import 'package:waddle/data/services/notification_service.dart';
import 'package:waddle/domain/entities/challenge.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';

/// Full-screen debug menu shown as a modal bottom sheet when debug mode
/// is active.  Provides quick triggers for every screen, state override
/// sliders, and diagnostic actions.
class DebugMenuSheet extends StatefulWidget {
  const DebugMenuSheet({super.key});

  @override
  State<DebugMenuSheet> createState() => _DebugMenuSheetState();
}

class _DebugMenuSheetState extends State<DebugMenuSheet> {
  // ── editable overrides (initialised from current state) ──
  double _streak = 0;
  double _waterOz = 0;
  double _goalOz = 80;
  double _totalOz = 0;
  int _totalDays = 0;
  int _totalDrinks = 0;
  int _totalGoalsMet = 0;
  int _completedChallenges = 0;
  double _totalXp = 0;
  double _drops = 0;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    if (state is HydrationLoaded) {
      final h = state.hydration;
      _streak = h.currentStreak.toDouble();
      _waterOz = h.waterConsumedOz;
      _goalOz = h.waterGoalOz;
      _totalOz = h.totalWaterConsumedOz;
      _totalDays = h.totalDaysLogged;
      _totalDrinks = h.totalDrinksLogged;
      _totalGoalsMet = h.totalGoalsMet;
      _completedChallenges = h.completedChallenges;
      _totalXp = h.totalXp.toDouble();
      _drops = h.drops.toDouble();
    }
  }

  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle + title
              _buildHeader(),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  children: [
                    _section('Screen Triggers'),
                    _triggerTile(
                      icon: Icons.emoji_events_rounded,
                      label: 'Congrats Screen',
                      subtitle: 'Trigger goal-reached celebration',
                      onTap: _triggerCongrats,
                    ),
                    _triggerTile(
                      icon: Icons.military_tech_rounded,
                      label: 'Challenge Completed',
                      subtitle: 'Fire ChallengeCompleted event',
                      onTap: _triggerChallengeCompleted,
                    ),
                    _triggerTile(
                      icon: Icons.heart_broken_rounded,
                      label: 'Challenge Failed',
                      subtitle: 'Fire ChallengeFailed event',
                      onTap: _triggerChallengeFailed,
                    ),
                    _triggerTile(
                      icon: Icons.celebration_rounded,
                      label: 'Onboarding Complete',
                      subtitle: 'Navigate to account-created screen',
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('accountCreated');
                      },
                    ),
                    _triggerTile(
                      icon: Icons.quiz_rounded,
                      label: 'Questionnaire',
                      subtitle: 'Open onboarding questions',
                      onTap: () {
                        Navigator.pop(context);
                        context.pushNamed('questions', extra: true);
                      },
                    ),
                    const SizedBox(height: 12),
                    _section('Timers & Cooldowns'),
                    _triggerTile(
                      icon: Icons.timer_off_rounded,
                      label: 'Reset Entry Cooldown',
                      subtitle:
                          'Clear the ${AppConstants.entryTimerMinutes}-min wait',
                      onTap: _resetEntryCooldown,
                    ),
                    _triggerTile(
                      icon: Icons.today_rounded,
                      label: 'Force Daily Reset',
                      subtitle: 'Simulate midnight reset (clears today data)',
                      onTap: _forceDailyReset,
                    ),
                    _triggerTile(
                      icon: Icons.star_rounded,
                      label: 'Award XP (+50)',
                      subtitle: 'Add 50 XP to trigger bar animation & toast',
                      onTap: _awardDebugXp,
                    ),
                    _triggerTile(
                      icon: Icons.water_drop_rounded,
                      label: 'Award Drops (+25)',
                      subtitle: 'Add 25 drops to trigger count-up & toast',
                      onTap: _awardDebugDrops,
                    ),
                    _triggerTile(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Award XP + Drops',
                      subtitle: 'Add 50 XP & 25 drops simultaneously',
                      onTap: _awardDebugBoth,
                    ),
                    const SizedBox(height: 12),
                    _section('Notifications'),
                    _triggerTile(
                      icon: Icons.notifications_active_rounded,
                      label: 'Goal Reached Notification',
                      subtitle: 'Fire the goal-met push notification',
                      onTap: _fireGoalNotification,
                    ),
                    _triggerTile(
                      icon: Icons.notifications_rounded,
                      label: 'Halfway Notification',
                      subtitle: 'Fire the 50% milestone notification',
                      onTap: _fireHalfwayNotification,
                    ),
                    const SizedBox(height: 12),
                    _section('State Overrides'),
                    _sliderTile(
                      label: 'Current Streak',
                      value: _streak,
                      min: 0,
                      max: 365,
                      divisions: 365,
                      display: '${_streak.toInt()} days',
                      onChanged: (v) => setState(() => _streak = v),
                    ),
                    _sliderTile(
                      label: 'Water Consumed',
                      value: _waterOz,
                      min: 0,
                      max: 200,
                      divisions: 200,
                      display: '${_waterOz.toStringAsFixed(1)} oz',
                      onChanged: (v) => setState(() => _waterOz = v),
                    ),
                    _sliderTile(
                      label: 'Water Goal',
                      value: _goalOz,
                      min: 20,
                      max: 200,
                      divisions: 180,
                      display: '${_goalOz.toStringAsFixed(0)} oz',
                      onChanged: (v) => setState(() => _goalOz = v),
                    ),
                    _sliderTile(
                      label: 'Total Water (lifetime)',
                      value: _totalOz.clamp(0, 50000),
                      min: 0,
                      max: 50000,
                      divisions: 500,
                      display: '${_totalOz.toStringAsFixed(0)} oz',
                      onChanged: (v) => setState(() => _totalOz = v),
                    ),
                    _stepperTile(
                      label: 'Total Days Logged',
                      value: _totalDays,
                      onChanged: (v) => setState(() => _totalDays = v),
                    ),
                    _stepperTile(
                      label: 'Total Drinks Logged',
                      value: _totalDrinks,
                      onChanged: (v) => setState(() => _totalDrinks = v),
                    ),
                    _stepperTile(
                      label: 'Total Goals Met',
                      value: _totalGoalsMet,
                      onChanged: (v) => setState(() => _totalGoalsMet = v),
                    ),
                    _stepperTile(
                      label: 'Completed Challenges',
                      value: _completedChallenges,
                      max: 6,
                      onChanged: (v) =>
                          setState(() => _completedChallenges = v),
                    ),
                    _sliderTile(
                      label: 'Total XP',
                      value: _totalXp.clamp(0, 50000),
                      min: 0,
                      max: 50000,
                      divisions: 500,
                      display: '${_totalXp.toInt()} XP',
                      onChanged: (v) => setState(() => _totalXp = v),
                    ),
                    _sliderTile(
                      label: 'Drops Balance',
                      value: _drops.clamp(0, 5000),
                      min: 0,
                      max: 5000,
                      divisions: 500,
                      display: '${_drops.toInt()} 💧',
                      onChanged: (v) => setState(() => _drops = v),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _applyOverrides,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Apply Overrides'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66BB6A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _section('Danger Zone'),
                    _triggerTile(
                      icon: Icons.restart_alt_rounded,
                      label: 'Reset All Stats to Zero',
                      subtitle: 'Wipe lifetime counters (streak, totals, etc.)',
                      onTap: _resetAllStats,
                      color: const Color(0xFFFF6B6B),
                    ),
                    _triggerTile(
                      icon: Icons.bug_report_rounded,
                      label: 'Deactivate Debug Mode',
                      subtitle: 'Restore real state and close menu',
                      onTap: _deactivateAndClose,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  //  UI helpers
  // ════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.bug_report_rounded,
                  color: Color(0xFF66BB6A), size: 28),
              const SizedBox(width: 10),
              Text(
                'Debug Menu',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white54),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: const Color(0xFF66BB6A),
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _triggerTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 24),
        title: Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            )),
        subtitle: Text(subtitle,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white54, fontSize: 12)),
        trailing:
            Icon(Icons.play_arrow_rounded, color: color.withValues(alpha: 0.6)),
        onTap: onTap,
      ),
    );
  }

  Widget _sliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70)),
                Text(display,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF66BB6A),
                        fontWeight: FontWeight.w700)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF66BB6A),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFF66BB6A),
                overlayColor: const Color(0xFF66BB6A).withValues(alpha: 0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperTile({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 9999,
  }) {
    return Card(
      color: Colors.white.withValues(alpha: 0.06),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.white38, size: 22),
              onPressed: value > min
                  ? () => onChanged((value - 1).clamp(min, max))
                  : null,
            ),
            SizedBox(
              width: 50,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFF66BB6A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.white38, size: 22),
              onPressed: value < max
                  ? () => onChanged((value + 1).clamp(min, max))
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  Actions
  // ════════════════════════════════════════════════════════════

  void _triggerCongrats() {
    Navigator.pop(context);
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    final oldStreak =
        state is HydrationLoaded ? state.hydration.currentStreak : 0;
    context.pushNamed('congrats', extra: {
      'oldStreak': oldStreak,
      'newStreak': oldStreak + 1,
    });
  }

  void _triggerChallengeCompleted() {
    Navigator.pop(context);
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    if (state is HydrationLoaded) {
      // Pick the first active challenge, or default to index 0
      final idx = state.hydration.activeChallengeIndex ?? 0;
      final challenge = Challenges.all[idx];
      _showChallengeResultDialog(
        title: 'Challenge Complete! 🎉',
        subtitle: challenge.title,
        message: 'You crushed the "${challenge.title}" challenge!',
        color: const Color(0xFF66BB6A),
        icon: Icons.military_tech_rounded,
      );
    }
  }

  void _triggerChallengeFailed() {
    Navigator.pop(context);
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    if (state is HydrationLoaded) {
      final idx = state.hydration.activeChallengeIndex ?? 0;
      final challenge = Challenges.all[idx];
      _showChallengeResultDialog(
        title: 'Challenge Failed',
        subtitle: challenge.title,
        message:
            'You didn\'t complete "${challenge.title}" this time. Try again!',
        color: const Color(0xFFFF6B6B),
        icon: Icons.heart_broken_rounded,
      );
    }
  }

  void _showChallengeResultDialog({
    required String title,
    required String subtitle,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(subtitle,
                  style: AppTextStyles.labelLarge.copyWith(color: color)),
            ),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetEntryCooldown() {
    final cubit = context.read<HydrationCubit>();
    cubit.resetEntryTimer();
    _showSnack('Entry cooldown reset ✓');
  }

  void _forceDailyReset() {
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    if (state is HydrationLoaded) {
      cubit.debugOverrideState(
        waterConsumedOz: 0,
        goalMetToday: false,
        clearNextEntryTime: true,
      );
      setState(() => _waterOz = 0);
      _showSnack('Daily reset applied ✓');
    }
  }

  void _fireGoalNotification() {
    try {
      getIt<NotificationService>().showGoalReachedNotification();
      _showSnack('Goal notification fired ✓');
    } catch (e) {
      _showSnack('Notification error: $e');
    }
  }

  void _fireHalfwayNotification() {
    try {
      getIt<NotificationService>().showHalfwayNotification();
      _showSnack('Halfway notification fired ✓');
    } catch (e) {
      _showSnack('Notification error: $e');
    }
  }

  void _applyOverrides() {
    final cubit = context.read<HydrationCubit>();
    cubit.debugOverrideState(
      currentStreak: _streak.toInt(),
      recordStreak: _streak.toInt(),
      waterConsumedOz: _waterOz,
      waterGoalOz: _goalOz,
      totalWaterConsumedOz: _totalOz,
      totalDaysLogged: _totalDays,
      totalDrinksLogged: _totalDrinks,
      totalGoalsMet: _totalGoalsMet,
      completedChallenges: _completedChallenges,
      totalXp: _totalXp.toInt(),
      drops: _drops.toInt(),
    );
    _showSnack('Overrides applied ✓');
  }

  void _resetAllStats() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset All Stats?'),
        content: const Text(
          'This will zero out all debug-mode stats (streak, totals, etc.). '
          'Real data is untouched — it restores when you exit debug mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final cubit = context.read<HydrationCubit>();
              cubit.debugOverrideState(
                currentStreak: 0,
                recordStreak: 0,
                waterConsumedOz: 0,
                waterGoalOz: AppConstants.defaultWaterGoalOz,
                totalWaterConsumedOz: 0,
                totalDaysLogged: 0,
                totalDrinksLogged: 0,
                totalGoalsMet: 0,
                completedChallenges: 0,
                totalXp: 0,
                drops: 0,
                goalMetToday: false,
                clearNextEntryTime: true,
              );
              setState(() {
                _streak = 0;
                _waterOz = 0;
                _goalOz = AppConstants.defaultWaterGoalOz;
                _totalOz = 0;
                _totalDays = 0;
                _totalDrinks = 0;
                _totalGoalsMet = 0;
                _completedChallenges = 0;
                _totalXp = 0;
                _drops = 0;
              });
              _showSnack('All stats reset to zero ✓');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _deactivateAndClose() {
    final debugService = getIt<DebugModeService>();
    final cubit = context.read<HydrationCubit>();
    debugService.deactivate();
    cubit.deactivateDebugMode();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug mode deactivated'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ── XP / Drops debug triggers ──────────────────────────────────

  void _awardDebugXp() {
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    if (state is HydrationLoaded) {
      final newXp = state.hydration.totalXp + 50;
      cubit.debugOverrideState(totalXp: newXp);
      setState(() => _totalXp = newXp.toDouble());
      _showSnack('+50 XP awarded ✓');
    }
  }

  void _awardDebugDrops() {
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    if (state is HydrationLoaded) {
      final newDrops = state.hydration.drops + 25;
      cubit.debugOverrideState(drops: newDrops);
      setState(() => _drops = newDrops.toDouble());
      _showSnack('+25 drops awarded ✓');
    }
  }

  void _awardDebugBoth() {
    final cubit = context.read<HydrationCubit>();
    final state = cubit.state;
    if (state is HydrationLoaded) {
      final newXp = state.hydration.totalXp + 50;
      final newDrops = state.hydration.drops + 25;
      cubit.debugOverrideState(totalXp: newXp, drops: newDrops);
      setState(() {
        _totalXp = newXp.toDouble();
        _drops = newDrops.toDouble();
      });
      _showSnack('+50 XP & +25 drops awarded ✓');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2D2D44),
      ),
    );
  }
}
