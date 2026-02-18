import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/presentation/widgets/water_cup.dart';
import 'package:waddle/presentation/screens/main/drink_selection_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _cooldownTimer;
  bool _showCups = false;
  bool _logsExpanded = false;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
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
          context.pushNamed('congrats');
        }
        if (state is ChallengeCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Challenge completed! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
          context.read<HydrationCubit>().acknowledgeChallengeResult();
        }
        if (state is ChallengeFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Challenge failed. Try again!'),
              backgroundColor: Colors.red,
            ),
          );
          context.read<HydrationCubit>().acknowledgeChallengeResult();
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

        return GradientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(hydration, loaded),
                  const SizedBox(height: 16),
                  _buildWaterCupSection(loaded),
                  const SizedBox(height: 20),
                  _buildDrinkButton(hydration),
                  const SizedBox(height: 20),
                  _buildTodayLogs(loaded),
                  const SizedBox(height: 20),
                  if (hydration.hasActiveChallenge)
                    _buildChallengeCard(hydration),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(HydrationState hydration, HydrationLoaded loaded) {
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
              color: AppColors.primary,
              title: 'Drinks Logged',
              body:
                  'This counts every drink you log today — water, coffee, soda, everything!\n\nHonest tracking gives you the most accurate view of your hydration. Every log counts.',
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add_check_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    '${loaded.todayLogs.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(),
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
          ).animate().fadeIn(),
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
        ).animate().fadeIn().slideX(begin: 0.2),
      ],
    ).animate().fadeIn();
  }

  Widget _buildWaterCupSection(HydrationLoaded state) {
    final hydration = state.hydration;
    final cupSize = MediaQuery.of(context).size.width * 0.78;
    return Column(
      children: [
        // Cup
        GestureDetector(
          onTap: () => setState(() => _showCups = !_showCups),
          child: AnimatedWaterCup(
            currentOz: state.displayedWater,
            goalOz: hydration.waterGoalOz,
            size: cupSize.clamp(240.0, 380.0),
            showCups: _showCups,
            onTapToggle: () => setState(() => _showCups = !_showCups),
          ),
        ),
        const SizedBox(height: 10),
        // Oz / cups readout
        Text(
          _showCups
              ? '${(state.displayedWater / 8).toStringAsFixed(1)} / ${(hydration.waterGoalOz / 8).toStringAsFixed(1)} cups'
              : '${state.displayedWater.toStringAsFixed(0)} / ${hydration.waterGoalOz.toStringAsFixed(0)} oz',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildDrinkButton(HydrationState hydration) {
    final onCooldown = hydration.isEntryOnCooldown;
    final cooldown = hydration.cooldownRemaining;

    return GestureDetector(
      onTap: onCooldown ? null : () => _showDrinkSheet(hydration),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: onCooldown
              ? AppColors.textHint.withValues(alpha: 0.25)
              : const Color(0xFF0288D1),
          borderRadius: BorderRadius.circular(30),
          boxShadow: onCooldown
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF0288D1).withValues(alpha: 0.35),
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
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95));
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
    final visibleLogs = state.todayLogs.reversed.take(visibleCount);

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
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        size: 18, color: AppColors.accent),
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
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _logsExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
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
    ).animate().fadeIn(delay: 700.ms);
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
