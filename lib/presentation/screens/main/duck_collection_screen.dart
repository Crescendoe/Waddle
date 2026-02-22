import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/debug_mode_service.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/domain/entities/shop_item.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/widgets/duck_avatar.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/core/utils/session_animation_tracker.dart';

class DuckCollectionScreen extends StatelessWidget {
  const DuckCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationBlocState>(
      builder: (context, state) {
        if (state is! HydrationLoaded) {
          return const Center(child: WaddleLoader());
        }

        final _animate = SessionAnimationTracker.shouldAnimate(
            SessionAnimationTracker.duckCollection);

        return GradientBackground(
          child: DefaultTabController(
            length: 3,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Text('Collection', style: AppTextStyles.displaySmall)
                        .animateOnce(_animate)
                        .fadeIn(),
                  ),

                  // ── Tab bar ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: ActiveThemeColors.of(context)
                            .primary
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        indicator: BoxDecoration(
                          color: ActiveThemeColors.of(context).primary,
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
                          Tab(text: 'Market'),
                        ],
                      ),
                    ),
                  ).animateOnce(_animate).fadeIn(delay: 100.ms),

                  const SizedBox(height: 12),

                  // ── Tab views ──────────────────────────────────────
                  Expanded(
                    child: TabBarView(
                      children: [
                        _DucksTab(loaded: state, animate: _animate),
                        _ThemesTab(loaded: state, animate: _animate),
                        _MarketTab(loaded: state, animate: _animate),
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
  final bool animate;
  const _DucksTab({required this.loaded, required this.animate});

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
                    backgroundColor: ActiveThemeColors.of(context)
                        .primary
                        .withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                        ActiveThemeColors.of(context).accent),
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
                ).animateOnce(animate).fadeIn(delay: (100 + index * 50).ms);
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
          final isHomeDuck =
              hydration?.homeDuckIndices.contains(duckIndex) ?? false;
          final homeCount = hydration?.homeDuckIndices.length ?? 0;

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
                    child: DuckAvatar(
                      duck: duck,
                      size: 70,
                      locked: !isUnlocked,
                    ),
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
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
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
                      // Add to Home (combines cup float + home screen overlay)
                      _ActionChip(
                        icon: isHomeDuck
                            ? Icons.home_rounded
                            : Icons.home_outlined,
                        label: isHomeDuck
                            ? 'Home ✓'
                            : homeCount >= 3
                                ? 'Home 3/3'
                                : 'Add to Home',
                        isActive: isHomeDuck,
                        onTap: homeCount >= 3 && !isHomeDuck
                            ? null
                            : () {
                                context
                                    .read<HydrationCubit>()
                                    .toggleHomeDuck(duckIndex);
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
  final bool animate;
  const _ThemesTab({required this.loaded, required this.animate});

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
                    backgroundColor: ActiveThemeColors.of(context)
                        .primary
                        .withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(
                        ActiveThemeColors.of(context).accent),
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
                ).animateOnce(animate).fadeIn(delay: (100 + index * 50).ms);
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
                    backgroundColor: ActiveThemeColors.of(sheetCtx).primary,
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
                child: DuckAvatar(
                  duck: duck,
                  size: 42,
                  locked: !isUnlocked,
                ),
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
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tc = ActiveThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: !enabled
              ? Colors.grey.withValues(alpha: 0.06)
              : isActive
                  ? tc.accent.withValues(alpha: 0.12)
                  : tc.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !enabled
                ? Colors.grey.withValues(alpha: 0.15)
                : isActive
                    ? tc.accent.withValues(alpha: 0.4)
                    : tc.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: !enabled
                    ? Colors.grey
                    : isActive
                        ? tc.accent
                        : tc.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: !enabled
                    ? Colors.grey
                    : isActive
                        ? tc.accent
                        : tc.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Market tab — vibrant shop with personality
// ═══════════════════════════════════════════════════════════════════════

class _MarketTab extends StatelessWidget {
  final HydrationLoaded loaded;
  final bool animate;
  const _MarketTab({required this.loaded, required this.animate});

  @override
  Widget build(BuildContext context) {
    final hydration = loaded.hydration;
    final tc = ActiveThemeColors.of(context);
    final drops = hydration.drops;
    final inventory = hydration.inventory;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Wallet strip ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tc.primary,
                      tc.primary.withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: tc.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.water_drop_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$drops',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'drops',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (inventory.doubleXpActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFFD54F).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded,
                                color: Color(0xFFFFD54F), size: 16),
                            SizedBox(width: 3),
                            Text(
                              '2× XP',
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Icon(Icons.storefront_rounded,
                          color: Colors.white.withValues(alpha: 0.30),
                          size: 28),
                  ],
                ),
              )
                  .animateOnce(animate)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.06, end: 0),

              const SizedBox(height: 14),

              // ── Item cards ──
              ...List.generate(ShopItems.all.length, (i) {
                final item = ShopItems.all[i];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: i < ShopItems.all.length - 1 ? 10 : 0),
                  child: _MarketItemCard(
                    item: item,
                    drops: drops,
                    inventory: inventory,
                    themeColors: tc,
                  ),
                )
                    .animateOnce(animate)
                    .fadeIn(delay: (150 + i * 80).ms, duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, duration: 350.ms);
              }),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Individual item card ────────────────────────────────────────────

class _MarketItemCard extends StatelessWidget {
  final ShopItem item;
  final int drops;
  final UserInventory inventory;
  final ActiveThemeColors themeColors;

  const _MarketItemCard({
    required this.item,
    required this.drops,
    required this.inventory,
    required this.themeColors,
  });

  Color get _darkColor {
    final hsl = HSLColor.fromColor(item.color);
    return hsl.withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final owned = inventory.countOf(item.id);
    final canAfford = drops >= item.price;
    final canBuy = canAfford && inventory.canPurchase(item);
    final isDoubleXp = item.id == 'double_xp';
    final canActivate =
        isDoubleXp && inventory.doubleXpTokens > 0 && !inventory.doubleXpActive;
    final maxed = !inventory.canPurchase(item);

    final dark = _darkColor;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Colored side strip with icon ──
            Container(
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    item.color.withValues(alpha: 0.30),
                    item.color.withValues(alpha: 0.12),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.color.withValues(alpha: 0.50),
                        item.color.withValues(alpha: 0.22),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(item.icon, color: dark, size: 22),
                ),
              ),
            ),

            // ── Content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + owned + price row
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: dark,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (owned > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: dark.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '×$owned',
                              style: TextStyle(
                                color: dark,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop, size: 13, color: dark),
                            const SizedBox(width: 2),
                            Text(
                              '${item.price}',
                              style: TextStyle(
                                color: dark,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Description
                    Text(
                      item.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // ── Action row ──
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: canBuy
                                ? () async {
                                    HapticFeedback.mediumImpact();
                                    await context
                                        .read<HydrationCubit>()
                                        .purchaseShopItem(item);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                gradient: canBuy
                                    ? LinearGradient(
                                        colors: [item.color, dark],
                                      )
                                    : null,
                                color: canBuy ? null : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: canBuy
                                    ? [
                                        BoxShadow(
                                          color: item.color
                                              .withValues(alpha: 0.30),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  maxed
                                      ? 'Max Owned'
                                      : canAfford
                                          ? 'Buy Now'
                                          : 'Not enough drops',
                                  style: TextStyle(
                                    color: canBuy
                                        ? Colors.white
                                        : AppColors.textHint,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (canActivate) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              await context
                                  .read<HydrationCubit>()
                                  .activateDoubleXp();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFF9A825),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD54F)
                                        .withValues(alpha: 0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 3),
                                  Text(
                                    'Use',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
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
