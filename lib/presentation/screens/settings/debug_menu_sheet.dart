import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/debug_mode_service.dart';
import 'package:waddle/data/services/notification_service.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';
import 'package:waddle/domain/entities/challenge.dart';
import 'package:waddle/domain/entities/duck_accessory.dart';
import 'package:waddle/domain/entities/duck_bond.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/domain/entities/seasonal_pack.dart';
import 'package:waddle/domain/entities/shop_item.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';

const _kGreen = Color(0xFF66BB6A);
const _kBg = Color(0xFF1A1A2E);
const _kCardBg = Colors.white10;
const _kDanger = Color(0xFFFF6B6B);

class DebugMenuSheet extends StatefulWidget {
  const DebugMenuSheet({super.key});

  @override
  State<DebugMenuSheet> createState() => _DebugMenuSheetState();
}

class _DebugMenuSheetState extends State<DebugMenuSheet> {
  // -- Stat overrides --
  double _streak = 0;
  double _waterOz = 0;
  double _goalOz = 80;
  double _totalOz = 0;
  int _totalDays = 0;
  int _totalDrinks = 0;
  int _totalGoalsMet = 0;
  int _totalHealthyPicks = 0;
  int _uniqueDrinks = 0;
  int _completedChallenges = 0;
  double _totalXp = 0;
  double _drops = 0;

  // -- Challenge toggles (6) --
  List<bool> _challengeActive = List.filled(6, false);

  // -- Inventory --
  int _streakFreezes = 0;
  int _doubleXpTokens = 0;
  int _cooldownSkips = 0;

  // -- Duck bonds --
  late List<int> _bondLevels;
  late List<bool> _bondOverrideEnabled;

  // -- Home ducks --
  late List<bool> _homeDuckToggles;

  // -- Subscription --
  bool _isSubscribed = false;

  // -- Unlock-all toggles --
  bool _unlockAllAccessories = false;
  bool _unlockAllThemes = false;
  bool _claimAllSeasonalPacks = false;

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
      _totalHealthyPicks = h.totalHealthyPicks;
      _uniqueDrinks = h.uniqueDrinksLogged.length;
      _completedChallenges = h.completedChallenges;
      _totalXp = h.totalXp.toDouble();
      _drops = h.drops.toDouble();
      _challengeActive = List<bool>.from(h.challengeActive);
      _streakFreezes = h.inventory.streakFreezes;
      _doubleXpTokens = h.inventory.doubleXpTokens;
      _cooldownSkips = h.inventory.cooldownSkips;
      _bondLevels = List.filled(DuckCompanions.all.length, 1);
      _bondOverrideEnabled = List.filled(DuckCompanions.all.length, false);
      for (final entry in h.duckBonds.entries) {
        if (entry.key >= 0 && entry.key < _bondLevels.length) {
          _bondLevels[entry.key] = entry.value.bondLevel;
          _bondOverrideEnabled[entry.key] = true;
        }
      }
      _homeDuckToggles = List.filled(DuckCompanions.all.length, false);
      for (final idx in h.homeDuckIndices) {
        if (idx >= 0 && idx < _homeDuckToggles.length) {
          _homeDuckToggles[idx] = true;
        }
      }
      _isSubscribed = h.isSubscribed;
      _unlockAllAccessories =
          h.ownedAccessoryIds.length == DuckAccessories.all.length;
      _unlockAllThemes = h.purchasedThemeIds.length >=
          ThemeRewards.all.where((t) => t.isPurchasable).length;
      _claimAllSeasonalPacks =
          h.claimedSeasonalPackIds.length == SeasonalPacks.all.length;
    }
  }

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
            color: _kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _buildHeader(),
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
                    _section('Timers & Quick Awards'),
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
                      label: 'Total Healthy Picks',
                      value: _totalHealthyPicks,
                      onChanged: (v) => setState(() => _totalHealthyPicks = v),
                    ),
                    _stepperTile(
                      label: 'Unique Drinks Logged',
                      value: _uniqueDrinks,
                      max: 30,
                      onChanged: (v) => setState(() => _uniqueDrinks = v),
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
                      display: '${_drops.toInt()}',
                      onChanged: (v) => setState(() => _drops = v),
                    ),
                    const SizedBox(height: 8),
                    _applyButton(
                      label: 'Apply Stat Overrides',
                      onPressed: _applyStatOverrides,
                    ),
                    const SizedBox(height: 12),
                    _section('Challenge Toggles'),
                    _infoCard(
                        'Toggle individual challenges on/off. Tap Apply to commit.'),
                    for (int i = 0; i < Challenges.all.length; i++)
                      _switchTile(
                        label: Challenges.all[i].title,
                        value: _challengeActive[i],
                        onChanged: (v) =>
                            setState(() => _challengeActive[i] = v),
                      ),
                    const SizedBox(height: 8),
                    _applyButton(
                      label: 'Apply Challenge Toggles',
                      onPressed: _applyChallengeOverrides,
                    ),
                    const SizedBox(height: 12),
                    _section('Inventory'),
                    _stepperTile(
                      label: 'Streak Freezes',
                      value: _streakFreezes,
                      max: 10,
                      onChanged: (v) => setState(() => _streakFreezes = v),
                    ),
                    _stepperTile(
                      label: 'Double XP Tokens',
                      value: _doubleXpTokens,
                      max: 10,
                      onChanged: (v) => setState(() => _doubleXpTokens = v),
                    ),
                    _stepperTile(
                      label: 'Cooldown Skips',
                      value: _cooldownSkips,
                      max: 10,
                      onChanged: (v) => setState(() => _cooldownSkips = v),
                    ),
                    const SizedBox(height: 8),
                    _applyButton(
                      label: 'Apply Inventory',
                      onPressed: _applyInventoryOverrides,
                    ),
                    const SizedBox(height: 12),
                    _section('Subscription'),
                    _switchTile(
                      label: 'Waddle+ Subscriber',
                      value: _isSubscribed,
                      onChanged: (v) {
                        setState(() => _isSubscribed = v);
                        _cubit.debugOverrideState(isSubscribed: v);
                        _showSnack(v ? 'Waddle+ enabled' : 'Waddle+ disabled');
                      },
                    ),
                    const SizedBox(height: 12),
                    _section('Accessories'),
                    _switchTile(
                      label: 'Unlock All Accessories',
                      value: _unlockAllAccessories,
                      onChanged: (v) {
                        setState(() => _unlockAllAccessories = v);
                        if (v) {
                          _cubit.debugOverrideState(
                            ownedAccessoryIds:
                                DuckAccessories.all.map((a) => a.id).toList(),
                          );
                          _showSnack(
                              'All ${DuckAccessories.all.length} accessories unlocked');
                        } else {
                          _cubit.debugOverrideState(ownedAccessoryIds: []);
                          _showSnack('Accessories cleared');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _section('Seasonal Packs'),
                    _switchTile(
                      label: 'Claim All Seasonal Packs',
                      value: _claimAllSeasonalPacks,
                      onChanged: (v) {
                        setState(() => _claimAllSeasonalPacks = v);
                        if (v) {
                          final allIds =
                              SeasonalPacks.all.map((p) => p.id).toList();
                          final allAccIds =
                              SeasonalPacks.allAccessoryIds.toList();
                          final current = (_cubit.state as HydrationLoaded)
                              .hydration
                              .ownedAccessoryIds;
                          final merged = {...current, ...allAccIds}.toList();
                          _cubit.debugOverrideState(
                            claimedSeasonalPackIds: allIds,
                            ownedAccessoryIds: merged,
                          );
                          _showSnack(
                              'All ${allIds.length} seasonal packs claimed');
                        } else {
                          _cubit.debugOverrideState(claimedSeasonalPackIds: []);
                          _showSnack('Seasonal pack claims cleared');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _section('Themes'),
                    _switchTile(
                      label: 'Unlock All Purchasable Themes',
                      value: _unlockAllThemes,
                      onChanged: (v) {
                        setState(() => _unlockAllThemes = v);
                        if (v) {
                          final ids = ThemeRewards.all
                              .where((t) => t.isPurchasable)
                              .map((t) => t.id)
                              .toList();
                          _cubit.debugOverrideState(purchasedThemeIds: ids);
                          _showSnack('${ids.length} themes unlocked');
                        } else {
                          _cubit.debugOverrideState(purchasedThemeIds: []);
                          _showSnack('Purchased themes cleared');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _section('Duck Bonds'),
                    _infoCard('Enable a duck to override its bond level. '
                        'Use the slider to set level 1-${DuckBondLevels.maxLevel}. '
                        'Tap Apply to commit.'),
                    _triggerTile(
                      icon: Icons.expand_more_rounded,
                      label: 'Configure Duck Bonds...',
                      subtitle: 'Set bond levels for individual ducks',
                      onTap: () => _showBondEditor(context),
                    ),
                    const SizedBox(height: 12),
                    _section('Home Ducks'),
                    _infoCard(
                        'Toggle which ducks appear on the home screen (max 3). '
                        'Tap Apply to commit.'),
                    _triggerTile(
                      icon: Icons.home_rounded,
                      label: 'Configure Home Ducks...',
                      subtitle: _homeDuckSummary(),
                      onTap: () => _showHomeDuckEditor(context),
                    ),
                    const SizedBox(height: 20),
                    _section('Danger Zone'),
                    _triggerTile(
                      icon: Icons.restart_alt_rounded,
                      label: 'Reset All Stats to Zero',
                      subtitle: 'Wipe lifetime counters (streak, totals, etc.)',
                      onTap: _resetAllStats,
                      color: _kDanger,
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

  HydrationCubit get _cubit => context.read<HydrationCubit>();

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
              const Icon(Icons.bug_report_rounded, color: _kGreen, size: 28),
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
          color: _kGreen,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoCard(String text) {
    return Card(
      color: _kCardBg,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Colors.white38, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: Colors.white54, fontSize: 12)),
            ),
          ],
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
      color: _kCardBg,
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

  Widget _switchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: _kCardBg,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            )),
        value: value,
        onChanged: onChanged,
        activeThumbColor: _kGreen,
        inactiveTrackColor: Colors.white12,
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
      color: _kCardBg,
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
                    style: AppTextStyles.bodySmall
                        .copyWith(color: _kGreen, fontWeight: FontWeight.w700)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _kGreen,
                inactiveTrackColor: Colors.white12,
                thumbColor: _kGreen,
                overlayColor: _kGreen.withValues(alpha: 0.2),
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
      color: _kCardBg,
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
                  color: _kGreen,
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

  Widget _applyButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // -- Sub-editors --

  void _showBondEditor(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sbCtx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, ctrl) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded,
                              color: _kGreen, size: 22),
                          const SizedBox(width: 8),
                          Text('Duck Bond Levels',
                              style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sbCtx),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white54),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      Expanded(
                        child: ListView.builder(
                          controller: ctrl,
                          itemCount: DuckCompanions.all.length,
                          itemBuilder: (_, i) {
                            final duck = DuckCompanions.all[i];
                            return Card(
                              color: _kCardBg,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '#$i ${duck.name}',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: _bondOverrideEnabled[i]
                                                  ? Colors.white
                                                  : Colors.white38,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Switch(
                                          value: _bondOverrideEnabled[i],
                                          onChanged: (v) {
                                            setSheetState(() {
                                              _bondOverrideEnabled[i] = v;
                                            });
                                            setState(() {});
                                          },
                                          activeThumbColor: _kGreen,
                                        ),
                                      ],
                                    ),
                                    if (_bondOverrideEnabled[i]) ...[
                                      Row(
                                        children: [
                                          Text('Lv ${_bondLevels[i]}',
                                              style: AppTextStyles.bodySmall
                                                  .copyWith(
                                                color: _kGreen,
                                                fontWeight: FontWeight.w700,
                                              )),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderThemeData(
                                                activeTrackColor: _kGreen,
                                                inactiveTrackColor:
                                                    Colors.white12,
                                                thumbColor: _kGreen,
                                                overlayColor: _kGreen
                                                    .withValues(alpha: 0.2),
                                                trackHeight: 2,
                                              ),
                                              child: Slider(
                                                value:
                                                    _bondLevels[i].toDouble(),
                                                min: 1,
                                                max: DuckBondLevels.maxLevel
                                                    .toDouble(),
                                                divisions:
                                                    DuckBondLevels.maxLevel - 1,
                                                onChanged: (v) {
                                                  setSheetState(() {
                                                    _bondLevels[i] = v.toInt();
                                                  });
                                                  setState(() {});
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _applyBondOverrides();
                            Navigator.pop(sbCtx);
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Apply Bond Levels'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showHomeDuckEditor(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sbCtx, setSheetState) {
            final activeCount = _homeDuckToggles.where((v) => v).length;
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, ctrl) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.home_rounded,
                              color: _kGreen, size: 22),
                          const SizedBox(width: 8),
                          Text('Home Ducks ($activeCount/3)',
                              style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(sbCtx),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white54),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      Expanded(
                        child: ListView.builder(
                          controller: ctrl,
                          itemCount: DuckCompanions.all.length,
                          itemBuilder: (_, i) {
                            final duck = DuckCompanions.all[i];
                            final enabled = _homeDuckToggles[i];
                            return Card(
                              color: _kCardBg,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: SwitchListTile(
                                dense: true,
                                title: Text(
                                  '#$i ${duck.name}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color:
                                        enabled ? Colors.white : Colors.white38,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                value: enabled,
                                activeThumbColor: _kGreen,
                                onChanged: (v) {
                                  final currentCount =
                                      _homeDuckToggles.where((x) => x).length;
                                  if (v && currentCount >= 3) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Max 3 home ducks'),
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                    return;
                                  }
                                  setSheetState(() {
                                    _homeDuckToggles[i] = v;
                                  });
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _applyHomeDuckOverrides();
                            Navigator.pop(sbCtx);
                          },
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Apply Home Ducks'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _homeDuckSummary() {
    final indices = <int>[];
    for (int i = 0; i < _homeDuckToggles.length; i++) {
      if (_homeDuckToggles[i]) indices.add(i);
    }
    if (indices.isEmpty) return 'No home ducks set';
    final names = indices.map((i) => DuckCompanions.all[i].name).join(', ');
    return '${indices.length}/3: $names';
  }

  // -- Apply actions --

  void _applyStatOverrides() {
    List<String>? uniqueList;
    final currentState = _cubit.state;
    if (currentState is HydrationLoaded) {
      final current = currentState.hydration.uniqueDrinksLogged;
      if (_uniqueDrinks != current.length) {
        if (_uniqueDrinks < current.length) {
          uniqueList = current.sublist(0, _uniqueDrinks);
        } else {
          uniqueList = List<String>.from(current);
          for (int i = current.length; i < _uniqueDrinks; i++) {
            uniqueList.add('debug_drink_$i');
          }
        }
      }
    }

    _cubit.debugOverrideState(
      currentStreak: _streak.toInt(),
      recordStreak: _streak.toInt(),
      waterConsumedOz: _waterOz,
      waterGoalOz: _goalOz,
      totalWaterConsumedOz: _totalOz,
      totalDaysLogged: _totalDays,
      totalDrinksLogged: _totalDrinks,
      totalGoalsMet: _totalGoalsMet,
      totalHealthyPicks: _totalHealthyPicks,
      uniqueDrinksLogged: uniqueList,
      completedChallenges: _completedChallenges,
      totalXp: _totalXp.toInt(),
      drops: _drops.toInt(),
    );
    _showSnack('Stat overrides applied');
  }

  void _applyChallengeOverrides() {
    _cubit.debugOverrideState(
      challengeActive: List<bool>.from(_challengeActive),
    );
    _showSnack('Challenge toggles applied');
  }

  void _applyInventoryOverrides() {
    _cubit.debugOverrideState(
      inventory: UserInventory(
        streakFreezes: _streakFreezes,
        doubleXpTokens: _doubleXpTokens,
        cooldownSkips: _cooldownSkips,
      ),
    );
    _showSnack('Inventory overrides applied');
  }

  void _applyBondOverrides() {
    final currentState = _cubit.state;
    if (currentState is! HydrationLoaded) return;

    final bonds = Map<int, DuckBondData>.from(currentState.hydration.duckBonds);
    for (int i = 0; i < _bondOverrideEnabled.length; i++) {
      if (_bondOverrideEnabled[i]) {
        final existing = bonds[i] ?? const DuckBondData();
        bonds[i] = existing.copyWith(bondLevel: _bondLevels[i]);
      }
    }
    _cubit.debugOverrideState(duckBonds: bonds);
    final count = _bondOverrideEnabled.where((v) => v).length;
    _showSnack('Bond levels applied for $count ducks');
  }

  void _applyHomeDuckOverrides() {
    final indices = <int>[];
    for (int i = 0; i < _homeDuckToggles.length; i++) {
      if (_homeDuckToggles[i]) indices.add(i);
    }
    _cubit.debugOverrideState(homeDuckIndices: indices);
    _showSnack('Home ducks set: ${indices.length}');
  }

  // -- Screen triggers --

  void _triggerCongrats() {
    Navigator.pop(context);
    final state = _cubit.state;
    final oldStreak =
        state is HydrationLoaded ? state.hydration.currentStreak : 0;
    context.pushNamed('congrats', extra: {
      'oldStreak': oldStreak,
      'newStreak': oldStreak + 1,
    });
  }

  void _triggerChallengeCompleted() {
    Navigator.pop(context);
    final state = _cubit.state;
    if (state is HydrationLoaded) {
      final idx = state.hydration.activeChallengeIndex ?? 0;
      final challenge = Challenges.all[idx];
      _showChallengeResultDialog(
        title: 'Challenge Complete!',
        subtitle: challenge.title,
        message: 'You crushed the "${challenge.title}" challenge!',
        color: _kGreen,
        icon: Icons.military_tech_rounded,
      );
    }
  }

  void _triggerChallengeFailed() {
    Navigator.pop(context);
    final state = _cubit.state;
    if (state is HydrationLoaded) {
      final idx = state.hydration.activeChallengeIndex ?? 0;
      final challenge = Challenges.all[idx];
      _showChallengeResultDialog(
        title: 'Challenge Failed',
        subtitle: challenge.title,
        message:
            'You didn\'t complete "${challenge.title}" this time. Try again!',
        color: _kDanger,
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

  // -- Timer / quick award actions --

  void _resetEntryCooldown() {
    _cubit.resetEntryTimer();
    _showSnack('Entry cooldown reset');
  }

  void _forceDailyReset() {
    final state = _cubit.state;
    if (state is HydrationLoaded) {
      _cubit.debugOverrideState(
        waterConsumedOz: 0,
        goalMetToday: false,
        clearNextEntryTime: true,
      );
      setState(() => _waterOz = 0);
      _showSnack('Daily reset applied');
    }
  }

  void _awardDebugXp() {
    final state = _cubit.state;
    if (state is HydrationLoaded) {
      final newXp = state.hydration.totalXp + 50;
      _cubit.debugOverrideState(totalXp: newXp);
      setState(() => _totalXp = newXp.toDouble());
      _showSnack('+50 XP awarded');
    }
  }

  void _awardDebugDrops() {
    final state = _cubit.state;
    if (state is HydrationLoaded) {
      final newDrops = state.hydration.drops + 25;
      _cubit.debugOverrideState(drops: newDrops);
      setState(() => _drops = newDrops.toDouble());
      _showSnack('+25 drops awarded');
    }
  }

  void _awardDebugBoth() {
    final state = _cubit.state;
    if (state is HydrationLoaded) {
      final newXp = state.hydration.totalXp + 50;
      final newDrops = state.hydration.drops + 25;
      _cubit.debugOverrideState(totalXp: newXp, drops: newDrops);
      setState(() {
        _totalXp = newXp.toDouble();
        _drops = newDrops.toDouble();
      });
      _showSnack('+50 XP & +25 drops awarded');
    }
  }

  // -- Notification actions --

  void _fireGoalNotification() {
    try {
      getIt<NotificationService>().showGoalReachedNotification();
      _showSnack('Goal notification fired');
    } catch (e) {
      _showSnack('Notification error: $e');
    }
  }

  void _fireHalfwayNotification() {
    try {
      getIt<NotificationService>().showHalfwayNotification();
      _showSnack('Halfway notification fired');
    } catch (e) {
      _showSnack('Notification error: $e');
    }
  }

  // -- Danger zone --

  void _resetAllStats() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset All Stats?'),
        content: const Text(
          'This will zero out all debug-mode stats (streak, totals, '
          'inventory, bonds, etc.). Real data is untouched \u2014 it '
          'restores when you exit debug mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cubit.debugOverrideState(
                currentStreak: 0,
                recordStreak: 0,
                waterConsumedOz: 0,
                waterGoalOz: AppConstants.defaultWaterGoalOz,
                totalWaterConsumedOz: 0,
                totalDaysLogged: 0,
                totalDrinksLogged: 0,
                totalGoalsMet: 0,
                totalHealthyPicks: 0,
                uniqueDrinksLogged: [],
                completedChallenges: 0,
                challengeActive: List.filled(6, false),
                totalXp: 0,
                drops: 0,
                goalMetToday: false,
                clearNextEntryTime: true,
                inventory: const UserInventory(),
                duckBonds: const {},
                ownedAccessoryIds: [],
                purchasedThemeIds: [],
                claimedSeasonalPackIds: [],
                homeDuckIndices: [],
                isSubscribed: false,
              );
              setState(() {
                _streak = 0;
                _waterOz = 0;
                _goalOz = AppConstants.defaultWaterGoalOz;
                _totalOz = 0;
                _totalDays = 0;
                _totalDrinks = 0;
                _totalGoalsMet = 0;
                _totalHealthyPicks = 0;
                _uniqueDrinks = 0;
                _completedChallenges = 0;
                _totalXp = 0;
                _drops = 0;
                _challengeActive = List.filled(6, false);
                _streakFreezes = 0;
                _doubleXpTokens = 0;
                _cooldownSkips = 0;
                _isSubscribed = false;
                _unlockAllAccessories = false;
                _unlockAllThemes = false;
                _claimAllSeasonalPacks = false;
                _bondOverrideEnabled =
                    List.filled(DuckCompanions.all.length, false);
                _bondLevels = List.filled(DuckCompanions.all.length, 1);
                _homeDuckToggles =
                    List.filled(DuckCompanions.all.length, false);
              });
              _showSnack('All stats reset to zero');
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
    debugService.deactivate();
    _cubit.deactivateDebugMode();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug mode deactivated'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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
