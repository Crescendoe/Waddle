import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/debug_mode_service.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';

class DuckCollectionScreen extends StatelessWidget {
  const DuckCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationBlocState>(
      builder: (context, state) {
        if (state is! HydrationLoaded) {
          return const Center(child: WaddleLoader());
        }

        return GradientBackground(
          child: DefaultTabController(
            length: 2,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text('Collection', style: AppTextStyles.displaySmall)
                        .animate()
                        .fadeIn(),
                  ),

                  // ── Tab bar ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w600),
                        unselectedLabelStyle: AppTextStyles.bodySmall,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Ducks'),
                          Tab(text: 'Themes'),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  // ── Tab views ──────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      children: [
                        _DucksTab(loaded: state),
                        _ThemesTab(loaded: state),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Ducks tab — existing grid
// ═══════════════════════════════════════════════════════════════════════

class _DucksTab extends StatelessWidget {
  final HydrationLoaded loaded;
  const _DucksTab({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final hydration = loaded.hydration;
    final unlocked = DuckCompanions.countUnlocked(
      currentStreak: hydration.currentStreak,
      recordStreak: hydration.recordStreak,
      completedChallenges: hydration.completedChallenges,
      totalWaterConsumed: hydration.totalWaterConsumedOz,
      totalDaysLogged: hydration.totalDaysLogged,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked of ${DuckCompanions.all.length} collected',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: unlocked / DuckCompanions.all.length,
                    minHeight: 10,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final duck = DuckCompanions.all[index];
                final debugMode = GetIt.instance<DebugModeService>().isActive;
                final isUnlocked = debugMode ||
                    duck.unlockCondition.isUnlocked(
                      currentStreak: hydration.currentStreak,
                      recordStreak: hydration.recordStreak,
                      completedChallenges: hydration.completedChallenges,
                      totalWaterConsumed: hydration.totalWaterConsumedOz,
                      totalDaysLogged: hydration.totalDaysLogged,
                    );

                return _DuckCard(
                  duck: duck,
                  isUnlocked: isUnlocked,
                  onTap: () => _showDuckDetail(context, duck, isUnlocked),
                ).animate().fadeIn(delay: (100 + index * 50).ms);
              },
              childCount: DuckCompanions.all.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  void _showDuckDetail(
      BuildContext context, DuckCompanion duck, bool isUnlocked) {
    final duckIndex = DuckCompanions.all.indexOf(duck);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocBuilder<HydrationCubit, HydrationBlocState>(
        builder: (ctx, state) {
          final hydration = state is HydrationLoaded ? state.hydration : null;
          final isActiveBadge = hydration?.activeDuckIndex == duckIndex;
          final isCupDuck = hydration?.cupDuckIndex == duckIndex;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? duck.rarity.color.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isUnlocked
                        ? const Text('🦆', style: TextStyle(fontSize: 40))
                        : const Icon(Icons.egg_rounded,
                            size: 36, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isUnlocked ? duck.name : '???',
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: duck.rarity.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    duck.rarity.label,
                    style: TextStyle(
                      color: duck.rarity.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isUnlocked) ...[
                  Text(duck.description,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Badge button
                      _ActionChip(
                        icon: isActiveBadge
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        label: isActiveBadge ? 'Badge ✓' : 'Set as Badge',
                        isActive: isActiveBadge,
                        onTap: () {
                          context.read<HydrationCubit>().setActiveDuck(
                                isActiveBadge ? null : duckIndex,
                              );
                        },
                      ),
                      const SizedBox(width: 10),
                      // Cup button
                      _ActionChip(
                        icon: isCupDuck
                            ? Icons.water_drop_rounded
                            : Icons.water_drop_outlined,
                        label: isCupDuck ? 'In Cup ✓' : 'Float in Cup',
                        isActive: isCupDuck,
                        onTap: () {
                          context.read<HydrationCubit>().setCupDuck(
                                isCupDuck ? null : duckIndex,
                              );
                        },
                      ),
                    ],
                  ),
                ] else
                  Column(
                    children: [
                      const Icon(Icons.egg_rounded,
                          size: 24, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text(
                        'Unlock: ${duck.unlockCondition.displayText}',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Themes tab — new grid of unlockable background themes
// ═══════════════════════════════════════════════════════════════════════

class _ThemesTab extends StatelessWidget {
  final HydrationLoaded loaded;
  const _ThemesTab({required this.loaded});

  @override
  Widget build(BuildContext context) {
    final h = loaded.hydration;
    final unlocked = ThemeRewards.countUnlocked(
      recordStreak: h.recordStreak,
      totalDaysLogged: h.totalDaysLogged,
      completedChallenges: h.completedChallenges,
      totalOzConsumed: h.totalWaterConsumedOz,
      totalHealthyPicks: h.totalHealthyPicks,
      uniqueDrinks: h.uniqueDrinksLogged.length,
      totalGoalsMet: h.totalGoalsMet,
      totalDrinksLogged: h.totalDrinksLogged,
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unlocked of ${ThemeRewards.all.length} unlocked',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: unlocked / ThemeRewards.all.length,
                    minHeight: 10,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final theme = ThemeRewards.all[index];
                final debugMode = GetIt.instance<DebugModeService>().isActive;
                final isUnlocked = debugMode ||
                    theme.unlockCondition.isUnlocked(
                      recordStreak: h.recordStreak,
                      totalDaysLogged: h.totalDaysLogged,
                      completedChallenges: h.completedChallenges,
                      totalOzConsumed: h.totalWaterConsumedOz,
                      totalHealthyPicks: h.totalHealthyPicks,
                      uniqueDrinks: h.uniqueDrinksLogged.length,
                      totalGoalsMet: h.totalGoalsMet,
                      totalDrinksLogged: h.totalDrinksLogged,
                    );
                final isActive = h.activeThemeId == theme.id ||
                    (h.activeThemeId == null && theme.id == 'default');

                return _ThemeCard(
                  theme: theme,
                  isUnlocked: isUnlocked,
                  isActive: isActive,
                  onTap: () =>
                      _showThemeDetail(context, theme, isUnlocked, isActive),
                ).animate().fadeIn(delay: (100 + index * 50).ms);
              },
              childCount: ThemeRewards.all.length,
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  void _showThemeDetail(
      BuildContext context, ThemeReward theme, bool isUnlocked, bool isActive) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Gradient preview
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: theme.gradientColors,
                      )
                    : null,
                color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.15),
                border: Border.all(
                  color: isActive
                      ? AppColors.accent
                      : Colors.grey.withValues(alpha: 0.2),
                  width: isActive ? 3 : 1,
                ),
              ),
              child: Center(
                child: isUnlocked
                    ? Icon(theme.icon, size: 32, color: Colors.white)
                    : const Icon(Icons.lock_rounded,
                        size: 28, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              isUnlocked ? theme.name : '???',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),

            if (isUnlocked) ...[
              Text(
                theme.description,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (isActive)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Currently active',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.accent),
                      ),
                    ],
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    context.read<HydrationCubit>().setActiveTheme(
                          theme.id == 'default' ? null : theme.id,
                        );
                    Navigator.of(sheetCtx).pop();
                  },
                  icon: const Icon(Icons.palette_rounded, size: 18),
                  label: const Text('Apply theme'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
            ] else ...[
              const Icon(Icons.lock_outline_rounded,
                  size: 24, color: AppColors.textHint),
              const SizedBox(height: 8),
              Text(
                'Unlock: ${theme.unlockCondition.displayText}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Card widgets
// ═══════════════════════════════════════════════════════════════════════

class _DuckCard extends StatelessWidget {
  final DuckCompanion duck;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _DuckCard({
    required this.duck,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? duck.rarity.color.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? duck.rarity.color.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? duck.rarity.color.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isUnlocked
                    ? const Text('🦆', style: TextStyle(fontSize: 24))
                    : const Icon(Icons.egg_rounded,
                        size: 24, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked ? duck.name : '???',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? duck.rarity.color
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final ThemeReward theme;
  final bool isUnlocked;
  final bool isActive;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isUnlocked,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.accent
                : Colors.grey.withValues(alpha: 0.15),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gradient swatch
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: theme.gradientColors,
                      )
                    : null,
                color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.15),
              ),
              child: Center(
                child: isUnlocked
                    ? (isActive
                        ? const Icon(Icons.check_rounded,
                            size: 22, color: Colors.white)
                        : Icon(theme.icon, size: 22, color: Colors.white))
                    : const Icon(Icons.lock_rounded,
                        size: 20, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                isUnlocked ? theme.name : '???',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isUnlocked ? AppColors.textPrimary : AppColors.textHint,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Action chip for duck detail sheet
// ═══════════════════════════════════════════════════════════════════════

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isActive ? AppColors.accent : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.accent : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DuckRarityExtension on DuckRarity {
  Color get color {
    switch (this) {
      case DuckRarity.common:
        return const Color(0xFF78909C);
      case DuckRarity.uncommon:
        return const Color(0xFF66BB6A);
      case DuckRarity.rare:
        return const Color(0xFF42A5F5);
      case DuckRarity.epic:
        return const Color(0xFFAB47BC);
      case DuckRarity.legendary:
        return const Color(0xFFFFB300);
    }
  }

  String get label {
    switch (this) {
      case DuckRarity.common:
        return 'Common';
      case DuckRarity.uncommon:
        return 'Uncommon';
      case DuckRarity.rare:
        return 'Rare';
      case DuckRarity.epic:
        return 'Epic';
      case DuckRarity.legendary:
        return 'Legendary';
    }
  }
}
