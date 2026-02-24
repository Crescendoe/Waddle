import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/drink_type.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/screens/celebration/unlock_reward_screen.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/presentation/widgets/water_cup.dart';
import 'package:waddle/presentation/screens/main/drink_selection_sheet.dart';

import 'package:waddle/core/utils/session_animation_tracker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _cooldownTimer;
  bool _showDrinkDetails = false;
  bool _logsExpanded = false;
  late final bool _animate =
      SessionAnimationTracker.shouldAnimate(SessionAnimationTracker.home);

  // ── XP / Drops animation tracking ──────────────────────────────
  int _prevTotalXp = -1;
  int _prevDrops = -1;
  int _toastXp = 0;
  int _toastDrops = 0;
  bool _showToast = false;
  Timer? _toastTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _toastTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTicker() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _showDrinkSheet(HydrationState hydration) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DrinkSelectionSheet(
        activeChallengeIndex: hydration.activeChallengeIndex,
        onDrinkSelected: (drinkName, amountOz, waterRatio) {
          context
              .read<HydrationCubit>()
              .addWater(amountOz, drinkName, waterRatio);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HydrationCubit, HydrationBlocState>(
      listener: (context, state) {
        if (state is GoalReached) {
          HapticFeedback.heavyImpact();
          context.pushNamed(
            'congrats',
            extra: {
              'oldStreak': state.oldStreak,
              'newStreak': state.newStreak,
            },
          );
        }
        if (state is ChallengeCompleted) {
          HapticFeedback.heavyImpact();
          context.pushNamed(
            'challengeComplete',
            extra: {'challengeIndex': state.challengeIndex},
          );
        }
        if (state is ChallengeFailed) {
          HapticFeedback.mediumImpact();
          context.pushNamed(
            'challengeFailed',
            extra: {'challengeIndex': state.challengeIndex},
          );
        }
        if (state is LeveledUp) {
          HapticFeedback.heavyImpact();
          context.pushNamed(
            'levelUp',
            extra: {
              'oldLevel': state.oldLevel,
              'newLevel': state.newLevel,
              'dropsAwarded': state.dropsAwarded,
            },
          );
        }
        if (state is RewardUnlocked) {
          HapticFeedback.mediumImpact();
          // Show the first unlocked duck, or first unlocked theme
          if (state.newDuckIndices.isNotEmpty) {
            context.pushNamed(
              'unlockReward',
              extra: {
                'type': UnlockRewardType.duck,
                'duckIndex': state.newDuckIndices.first,
              },
            );
          } else if (state.newThemeIds.isNotEmpty) {
            context.pushNamed(
              'unlockReward',
              extra: {
                'type': UnlockRewardType.theme,
                'themeId': state.newThemeIds.first,
              },
            );
          }
        }
        // Track XP / drops changes for animated toast
        if (state is HydrationLoaded) {
          final h = state.hydration;
          if (_prevTotalXp >= 0) {
            final xpDelta = h.totalXp - _prevTotalXp;
            final dropsDelta = h.drops - _prevDrops;
            if (xpDelta > 0 || dropsDelta > 0) {
              setState(() {
                _toastXp = xpDelta;
                _toastDrops = dropsDelta;
                _showToast = true;
              });
              _toastTimer?.cancel();
              _toastTimer = Timer(const Duration(seconds: 2), () {
                if (mounted) setState(() => _showToast = false);
              });
            }
          }
          _prevTotalXp = h.totalXp;
          _prevDrops = h.drops;
        }
      },
      builder: (context, state) {
        if (state is HydrationLoading || state is HydrationInitial) {
          return const Center(child: WaddleLoader());
        }
        if (state is HydrationError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(state.message, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context
                      .read<HydrationCubit>()
                      .loadData(context.read<HydrationCubit>().userId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final loaded = state is HydrationLoaded ? state : null;
        if (loaded == null) return const SizedBox.shrink();

        final hydration = loaded.hydration;

        // Start cooldown ticker if needed
        if (hydration.isEntryOnCooldown) {
          _startCooldownTicker();
        }

        return Stack(
          children: [
            GradientBackground(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      _buildHeader(hydration, loaded),
                      const SizedBox(height: 6),
                      _buildXpStrip(hydration),
                      const SizedBox(height: 14),
                      _buildWaterCupSection(loaded),
                      const SizedBox(height: 20),
                      _buildDrinkButton(hydration),
                      const SizedBox(height: 20),
                      _buildTodayLogs(loaded),
                      if (hydration.hasActiveChallenge) ...[
                        const SizedBox(height: 14),
                        _buildChallengeCard(hydration),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Reward toast overlay
            _buildRewardToastOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildHeader(HydrationState hydration, HydrationLoaded loaded) {
    final tc = ActiveThemeColors.of(context);
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good ${_timeGreeting()}!',
                style: AppTextStyles.headlineSmall),
            Text(
              hydration.goalMetToday
                  ? 'Goal reached! Keep it up 💧'
                  : '${hydration.remainingOz.toStringAsFixed(0)} oz to go',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Drinks logged badge (always positive)
        if (loaded.todayLogs.isNotEmpty)
          GestureDetector(
            onTap: () => _showBadgeTip(
              context,
              icon: Icons.playlist_add_check_rounded,
              color: tc.primary,
              title: 'Drinks Logged',
              body:
                  'This counts every drink you log today — water, coffee, soda, everything!\n\nHonest tracking gives you the most accurate view of your hydration. Every log counts.',
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tc.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tc.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add_check_rounded,
                      size: 14, color: tc.primary),
                  const SizedBox(width: 3),
                  Text(
                    '${loaded.todayLogs.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tc.primary,
                    ),
                  ),
                ],
              ),
            ),
          ).animateOnce(_animate).fadeIn(),
        // Healthy picks badge (bonus — only shows when > 0)
        if (loaded.healthyPicksToday > 0)
          GestureDetector(
            onTap: () => _showBadgeTip(
              context,
              icon: Icons.eco_rounded,
              color: const Color(0xFF2E7D32),
              title: 'Healthy Picks',
              body:
                  'This counts drinks rated Excellent or Good — like water, tea, coffee, and milk.\n\nIt only goes up! Logging other drinks won\'t lower this number.',
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco_rounded,
                      size: 14, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 3),
                  Text(
                    '${loaded.healthyPicksToday}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ).animateOnce(_animate).fadeIn(),
        // Streak badge
        GestureDetector(
          onTap: () => _showBadgeTip(
            context,
            icon: Icons.local_fire_department_rounded,
            color: hydration.streakTier.color,
            title: 'Daily Streak',
            body:
                'Your streak grows each day you meet your water goal.\n\nCurrent: ${hydration.currentStreak} days\nBest: ${hydration.recordStreak} days\nTier: ${hydration.streakTier.label}',
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: hydration.streakTier.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hydration.streakTier.color.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 18, color: hydration.streakTier.color),
                const SizedBox(width: 4),
                Text(
                  '${hydration.currentStreak}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: hydration.streakTier.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ).animateOnce(_animate).fadeIn().slideX(begin: 0.2),
      ],
    ).animateOnce(_animate).fadeIn();
  }

  /// Ultra-slim XP strip — level label, progress bar with XP count, drops counter.
  Widget _buildXpStrip(HydrationState hydration) {
    final tc = ActiveThemeColors.of(context);
    final level = hydration.level;
    final progress = hydration.levelProgress;
    final xpInto = hydration.xpIntoLevel;
    final xpNeeded = hydration.xpToNext;

    return Row(
      children: [
        // Level label
        Text(
          'Lvl $level',
          style: TextStyle(
            color: tc.primary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        // Thin progress bar (animated)
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) =>
                  LinearProgressIndicator(
                value: animatedProgress,
                minHeight: 5,
                backgroundColor: tc.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(tc.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // XP count
        Text(
          '$xpInto/$xpNeeded',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        // Drops balance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tc.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop, size: 15, color: tc.accent),
              const SizedBox(width: 3),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(end: hydration.drops.toDouble()),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, animatedDrops, _) => Text(
                  '${animatedDrops.round()}',
                  style: TextStyle(
                    color: tc.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Floating reward toast that appears just below the XP strip.
  Widget _buildRewardToastOverlay() {
    final tc = ActiveThemeColors.of(context);
    return Positioned(
      top: MediaQuery.of(context).padding.top + 82,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: tc.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_toastXp > 0) ...[
                  Icon(Icons.star_rounded, size: 16, color: tc.primary),
                  const SizedBox(width: 4),
                  Text(
                    '+$_toastXp XP',
                    style: TextStyle(
                      color: tc.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_toastXp > 0 && _toastDrops > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                if (_toastDrops > 0) ...[
                  Icon(Icons.water_drop, size: 16, color: tc.accent),
                  const SizedBox(width: 4),
                  Text(
                    '+$_toastDrops',
                    style: TextStyle(
                      color: tc.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          )
              .animate(target: _showToast ? 1 : 0)
              .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
              .slideY(
                  begin: -0.5,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOutCubic),
        ),
      ),
    );
  }

  Widget _buildWaterCupSection(HydrationLoaded state) {
    final hydration = state.hydration;
    final cupSize = MediaQuery.of(context).size.width * 0.78;
    return Column(
      children: [
        // Cup
        AnimatedWaterCup(
          currentOz: state.displayedWater,
          goalOz: hydration.waterGoalOz,
          size: cupSize.clamp(240.0, 380.0),
          showDetails: _showDrinkDetails,
          todayLogs: state.todayLogs,
          cupDuckCount: hydration.homeDuckIndices.length,
          cupDuckIndices: hydration.homeDuckIndices,
          onTapToggle: () =>
              setState(() => _showDrinkDetails = !_showDrinkDetails),
        ),
        const SizedBox(height: 10),
        if (state.todayLogs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _showDrinkDetails
                  ? 'Tap cup to hide details'
                  : 'Tap cup for drink breakdown',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
                fontSize: 11,
              ),
            ),
          ),
      ],
    ).animateOnce(_animate).fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildDrinkButton(HydrationState hydration) {
    final onCooldown = hydration.isEntryOnCooldown;
    final cooldown = hydration.cooldownRemaining;
    final tc = ActiveThemeColors.of(context);

    return GestureDetector(
      onTap: onCooldown ? null : () => _showDrinkSheet(hydration),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: onCooldown
              ? AppColors.textHint.withValues(alpha: 0.25)
              : tc.primary,
          borderRadius: BorderRadius.circular(30),
          boxShadow: onCooldown
              ? []
              : [
                  BoxShadow(
                    color: tc.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              onCooldown ? Icons.timer_rounded : Icons.water_drop_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              onCooldown
                  ? 'Wait ${cooldown.inMinutes}:${(cooldown.inSeconds % 60).toString().padLeft(2, '0')}'
                  : 'Log a Drink',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    )
        .animateOnce(_animate)
        .fadeIn(delay: 500.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildTodayLogs(HydrationLoaded state) {
    if (state.todayLogs.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            MascotImage(
              assetPath: AppConstants.mascotSitting,
              size: 80,
            ),
            const SizedBox(height: 12),
            Text('No drinks logged yet today',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                )),
            Text('Tap the button above to start!',
                style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    final visibleCount = _logsExpanded ? state.todayLogs.length : 3;
    final sortedLogs = List.of(state.todayLogs)
      ..sort((a, b) => b.entryTime.compareTo(a.entryTime));
    final visibleLogs = sortedLogs.take(visibleCount);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Today's Log", style: AppTextStyles.labelLarge),
              const Spacer(),
              Text('${state.todayLogs.length} entries',
                  style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          ...visibleLogs.map((log) {
            final drink = DrinkTypes.byName(log.drinkName);
            final drinkColor = drink?.color ?? AppColors.accent;
            final drinkIcon = drink?.icon ?? Icons.water_drop_rounded;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: drinkColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(drinkIcon, size: 18, color: drinkColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log.drinkName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        Text(
                          '${log.amountOz.toStringAsFixed(1)} oz → ${log.waterContentOz.toStringAsFixed(1)} oz water',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTime(log.entryTime),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _confirmRemoveLog(log),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textHint),
                  ),
                ],
              ),
            );
          }),
          if (state.todayLogs.length > 3)
            Center(
              child: GestureDetector(
                onTap: () => setState(() => _logsExpanded = !_logsExpanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _logsExpanded
                            ? 'Show less'
                            : 'Show all ${state.todayLogs.length} entries',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ActiveThemeColors.of(context).primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _logsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: ActiveThemeColors.of(context).primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 600.ms);
  }

  Widget _buildChallengeCard(HydrationState hydration) {
    final challenge = hydration.activeChallengeIndex!;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset(
            AppConstants.challengeImages[challenge],
            width: 48,
            height: 48,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.emoji_events_rounded, size: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Challenge',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    )),
                Text('${hydration.challengeDaysLeft} days left',
                    style: AppTextStyles.labelLarge),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 700.ms);
  }

  void _confirmRemoveLog(dynamic log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Entry?'),
        content: Text('Remove ${log.drinkName} (${log.amountOz} oz)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HydrationCubit>().removeLog(log);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  void _showBadgeTip(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
