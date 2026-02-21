import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/drink_type.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/water_log.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/core/utils/session_animation_tracker.dart';

class StreaksScreen extends StatefulWidget {
  const StreaksScreen({super.key});

  @override
  State<StreaksScreen> createState() => _StreaksScreenState();
}

class _StreaksScreenState extends State<StreaksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDay;
  bool _calendarLoaded = false;
  late final bool _animate =
      SessionAnimationTracker.shouldAnimate(SessionAnimationTracker.streaks);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_calendarLoaded) {
        context.read<HydrationCubit>().loadCalendarData();
        _calendarLoaded = true;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationBlocState>(
      builder: (context, state) {
        if (state is! HydrationLoaded) {
          return const Center(child: WaddleLoader());
        }

        final hydration = state.hydration;

        return GradientBackground(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed header: title + hero + stats
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Streaks', style: AppTextStyles.displaySmall)
                          .animateOnce(_animate)
                          .fadeIn(),
                      const SizedBox(height: 12),
                      _buildStreakHero(hydration),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: ActiveThemeColors.of(context)
                                .primary
                                .withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: ActiveThemeColors.of(context).primary,
                      unselectedLabelColor: AppColors.textHint,
                      labelStyle: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: AppTextStyles.labelMedium,
                      tabs: const [
                        Tab(text: 'Calendar'),
                        Tab(text: 'Progress'),
                        Tab(text: 'Drinks'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCalendarTab(state),
                      _buildProgressTab(hydration),
                      _buildDrinksTab(state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Calendar Tab ─────────────────────────────────────────────────

  Widget _buildCalendarTab(HydrationLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _buildCalendar(state),
          if (_selectedDay != null) ...[
            const SizedBox(height: 12),
            _buildDayLogs(state),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Progress Tab ─────────────────────────────────────────────────

  Widget _buildProgressTab(HydrationState hydration) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          _buildTierProgress(hydration),
          const SizedBox(height: 16),
          _buildTierLegend(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStreakHero(HydrationState hydration) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Mascot
          MascotImage(
            assetPath: hydration.currentStreak >= 10
                ? AppConstants.mascotRunning
                : AppConstants.mascotDefault,
            size: 72,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 32,
                      color: hydration.streakTier.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${hydration.currentStreak}',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 44,
                        color: hydration.streakTier.color,
                      ),
                    ),
                  ],
                ),
                Text('Day Streak', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 6),
                // Tier badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: hydration.streakTier.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hydration.streakTier.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(hydration.streakTier.icon,
                          size: 14, color: hydration.streakTier.color),
                      const SizedBox(width: 4),
                      Text(
                        '${hydration.streakTier.label} Tier',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: hydration.streakTier.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 200.ms);
  }

  // ── Calendar ─────────────────────────────────────────────────────

  Widget _buildCalendar(HydrationLoaded state) {
    final now = DateTime.now();
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday % 7; // Sun=0

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(year, month - 1);
                }),
              ),
              Text(
                _monthName(month) + ' $year',
                style: AppTextStyles.labelLarge,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _focusedMonth.year == now.year &&
                        _focusedMonth.month == now.month
                    ? null
                    : () => setState(() {
                          _focusedMonth = DateTime(year, month + 1);
                        }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Day-of-week headers
          Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHint,
                            )),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Calendar grid
          ...List.generate(
            ((daysInMonth + firstWeekday + 6) / 7).floor(),
            (week) {
              return Row(
                children: List.generate(7, (weekday) {
                  final dayIndex = week * 7 + weekday - firstWeekday + 1;
                  if (dayIndex < 1 || dayIndex > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final date = DateTime(year, month, dayIndex);
                  final isToday = date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                  final isFuture = date.isAfter(now);
                  final isSelected = _selectedDay != null &&
                      _selectedDay!.year == date.year &&
                      _selectedDay!.month == date.month &&
                      _selectedDay!.day == date.day;

                  // Look up calendar data
                  final dayKey = DateTime(date.year, date.month, date.day);
                  final goalMet = state.calendarDays[dayKey];
                  // goalMet == true → goal achieved, goalMet == false → logged but not met, null → no data

                  return Expanded(
                    child: GestureDetector(
                      onTap: isFuture
                          ? null
                          : () {
                              setState(() => _selectedDay = date);
                              context
                                  .read<HydrationCubit>()
                                  .selectCalendarDay(date);
                            },
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ActiveThemeColors.of(context)
                                  .primary
                                  .withValues(alpha: 0.2)
                              : goalMet == true
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : goalMet == false
                                      ? AppColors.accent.withValues(alpha: 0.08)
                                      : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday
                              ? Border.all(
                                  color: ActiveThemeColors.of(context).primary,
                                  width: 1.5)
                              : isSelected
                                  ? Border.all(
                                      color:
                                          ActiveThemeColors.of(context).primary,
                                      width: 1)
                                  : null,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$dayIndex',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                                  color: isFuture
                                      ? AppColors.textHint
                                          .withValues(alpha: 0.4)
                                      : isSelected
                                          ? ActiveThemeColors.of(context)
                                              .primary
                                          : AppColors.textPrimary,
                                ),
                              ),
                              if (goalMet == true)
                                Icon(Icons.check_circle_rounded,
                                    size: 10, color: AppColors.success),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _calendarLegendItem(AppColors.success, 'Goal Met'),
              const SizedBox(width: 16),
              _calendarLegendItem(AppColors.accent, 'Logged'),
              const SizedBox(width: 16),
              _calendarLegendItem(
                  ActiveThemeColors.of(context).primary, 'Today'),
            ],
          ),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 500.ms);
  }

  Widget _calendarLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textHint,
            )),
      ],
    );
  }

  // ── Day Log Viewer ───────────────────────────────────────────────

  Widget _buildDayLogs(HydrationLoaded state) {
    final logs = state.selectedDayLogs;
    final day = _selectedDay!;
    final isToday = day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;

    final totalOz = logs.fold<double>(0, (sum, l) => sum + l.waterContentOz);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 18, color: ActiveThemeColors.of(context).primary),
              const SizedBox(width: 8),
              Text(
                isToday
                    ? 'Today\'s Log'
                    : '${_monthName(day.month)} ${day.day}, ${day.year}',
                style: AppTextStyles.labelLarge,
              ),
              const Spacer(),
              Text(
                '${totalOz.toStringAsFixed(0)} oz total',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No drinks logged on this day',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            ...logs.map((log) => _buildLogEntry(log)),
        ],
      ),
    ).animateOnce(_animate).fadeIn(duration: 200.ms);
  }

  Widget _buildLogEntry(WaterLog log) {
    final drinkType = DrinkTypes.byName(log.drinkName);
    final drinkIcon = drinkType?.icon ?? Icons.water_drop_rounded;
    final drinkColor = drinkType?.color ?? AppColors.accent;

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
        ],
      ),
    );
  }

  Widget _buildTierProgress(HydrationState hydration) {
    final tiers = [
      (StreakTier.bronze, AppConstants.bronzeThreshold),
      (StreakTier.silver, AppConstants.silverThreshold),
      (StreakTier.gold, AppConstants.goldThreshold),
      (StreakTier.platinum, AppConstants.platinumThreshold),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tier Progress', style: AppTextStyles.labelLarge),
          const SizedBox(height: 16),
          ...tiers.map((tier) {
            final progress =
                (hydration.currentStreak / tier.$2).clamp(0.0, 1.0);
            final achieved = hydration.currentStreak >= tier.$2;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    tier.$1.icon,
                    size: 24,
                    color: achieved ? tier.$1.color : AppColors.textHint,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tier.$1.label,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                )),
                            Text(
                              achieved
                                  ? '✓'
                                  : '${hydration.currentStreak}/${tier.$2}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: achieved
                                    ? Colors.green
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: ActiveThemeColors.of(context)
                                .primary
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              achieved
                                  ? tier.$1.color
                                  : ActiveThemeColors.of(context)
                                      .primary
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 600.ms);
  }

  Widget _buildTierLegend() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How Streaks Work', style: AppTextStyles.labelLarge),
          const SizedBox(height: 12),
          _legendItem(Icons.water_drop_rounded,
              'Meet your daily water goal to keep your streak alive'),
          _legendItem(Icons.nights_stay_rounded,
              'Your streak resets at midnight if you missed your goal'),
          _legendItem(Icons.pets_rounded,
              'Higher streaks unlock rare duck companions!'),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 800.ms);
  }

  Widget _legendItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppTextStyles.bodySmall),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  // ── Drinks Analytics Tab ─────────────────────────────────────────

  Widget _buildDrinksTab(HydrationLoaded state) {
    final allLogs = <WaterLog>[
      ...state.todayLogs,
    ];

    if (allLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotImage(assetPath: AppConstants.mascotSitting, size: 100),
            const SizedBox(height: 16),
            Text(
              'Log some drinks to see analytics!',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Aggregate by drink name
    final drinkMap = <String, _DrinkStats>{};
    for (final log in allLogs) {
      drinkMap.update(
        log.drinkName,
        (s) => _DrinkStats(
          count: s.count + 1,
          totalOz: s.totalOz + log.amountOz,
        ),
        ifAbsent: () => _DrinkStats(count: 1, totalOz: log.amountOz),
      );
    }

    // Sort by count descending
    final sortedEntries = drinkMap.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    final topCount = sortedEntries.first.value.count;

    // Category breakdown
    final categoryMap = <String, double>{};
    for (final entry in sortedEntries) {
      final drink = DrinkTypes.byName(entry.key);
      final category = drink?.category.name ?? 'Other';
      final label = category[0].toUpperCase() + category.substring(1);
      categoryMap.update(
        label,
        (v) => v + entry.value.totalOz,
        ifAbsent: () => entry.value.totalOz,
      );
    }
    final totalOzAll = categoryMap.values.fold<double>(0, (s, v) => s + v);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _AnalyticCard(
                  icon: Icons.local_drink_rounded,
                  label: 'Total Drinks',
                  value: '${allLogs.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnalyticCard(
                  icon: Icons.category_rounded,
                  label: 'Unique Types',
                  value: '${drinkMap.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AnalyticCard(
                  icon: Icons.water_drop_rounded,
                  label: 'Total oz',
                  value: totalOzAll.toStringAsFixed(0),
                ),
              ),
            ],
          ).animateOnce(_animate).fadeIn(),
          const SizedBox(height: 20),

          // Favourite drink
          Text('Most Logged', style: AppTextStyles.headlineSmall)
              .animateOnce(_animate)
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          ...sortedEntries.take(8).map((entry) {
            final drink = DrinkTypes.byName(entry.key);
            final fraction = entry.value.count / topCount;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    drink?.icon ?? Icons.water_drop_rounded,
                    size: 18,
                    color: drink?.color ?? AppColors.water,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: Text(
                      entry.key,
                      style: AppTextStyles.bodySmall
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 14,
                        backgroundColor: ActiveThemeColors.of(context)
                            .primary
                            .withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(
                          drink?.color ?? AppColors.water,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${entry.value.count}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ActiveThemeColors.of(context).primary,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ).animateOnce(_animate).fadeIn(
                delay: (150 + sortedEntries.toList().indexOf(entry) * 50).ms);
          }),
          const SizedBox(height: 20),

          // Category breakdown
          Text('By Category', style: AppTextStyles.headlineSmall)
              .animateOnce(_animate)
              .fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          ...categoryMap.entries.map((entry) {
            final fraction = totalOzAll > 0 ? entry.value / totalOzAll : 0.0;
            final pct = (fraction * 100).toStringAsFixed(0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: EdgeInsets.zero,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text('$pct%',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.accent)),
                    const SizedBox(width: 8),
                    Text('${entry.value.toStringAsFixed(0)} oz',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ).animateOnce(_animate).fadeIn(delay: 250.ms);
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Helper types for drink analytics
// ═══════════════════════════════════════════════════════════════════════

class _DrinkStats {
  final int count;
  final double totalOz;
  const _DrinkStats({required this.count, required this.totalOz});
}

class _AnalyticCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AnalyticCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ActiveThemeColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Icon(icon, size: 22, color: tc.accent),
          const SizedBox(height: 6),
          Text(value,
              style: AppTextStyles.headlineSmall.copyWith(color: tc.primary)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
