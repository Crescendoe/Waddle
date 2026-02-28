import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/debug_mode_service.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';
import 'package:waddle/domain/entities/duck_accessory.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/domain/entities/iap_products.dart';
import 'package:waddle/domain/entities/seasonal_pack.dart';
import 'package:waddle/domain/entities/shop_item.dart';
import 'package:waddle/data/services/iap_service.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/widgets/duck_avatar.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/presentation/widgets/market_confirmation.dart';
import 'package:waddle/presentation/screens/celebration/unlock_reward_screen.dart';
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
      totalHealthyPicks: hydration.totalHealthyPicks,
      totalGoalsMet: hydration.totalGoalsMet,
      totalDrinksLogged: hydration.totalDrinksLogged,
      uniqueDrinks: hydration.uniqueDrinksLogged.length,
      challengeActive: hydration.challengeActive,
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
                      totalHealthyPicks: hydration.totalHealthyPicks,
                      totalGoalsMet: hydration.totalGoalsMet,
                      totalDrinksLogged: hydration.totalDrinksLogged,
                      uniqueDrinks: hydration.uniqueDrinksLogged.length,
                      challengeActive: hydration.challengeActive,
                    );

                final bondNickname = hydration.duckBonds[duck.index]?.nickname;
                final isHomeDuck =
                    hydration.homeDuckIndices.contains(duck.index);
                final isBadgeDuck = hydration.activeDuckIndex == duck.index;

                return _DuckCard(
                  duck: duck,
                  isUnlocked: isUnlocked,
                  nickname: (bondNickname != null && bondNickname.isNotEmpty)
                      ? bondNickname
                      : null,
                  isHomeDuck: isHomeDuck,
                  isBadgeDuck: isBadgeDuck,
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

    // Unlocked ducks → navigate to full detail/dress-up screen
    if (isUnlocked) {
      context.pushNamed('duckDetail', extra: duckIndex);
      return;
    }

    // Locked ducks → bottom sheet showing unlock requirements
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
                color: Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DuckAvatar(
                  duck: duck,
                  size: 70,
                  locked: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('???', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            const Icon(Icons.egg_rounded, size: 24, color: AppColors.textHint),
            const SizedBox(height: 8),
            Text(
              'Unlock: ${duck.unlockCondition.displayText}',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
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
      level: h.level,
      purchasedThemeIds: h.purchasedThemeIds,
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
                      level: h.level,
                      purchasedThemeIds: h.purchasedThemeIds,
                      themeId: theme.id,
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
                theme.isPurchasable
                    ? '${theme.price} Drops'
                    : 'Unlock: ${theme.unlockCondition.displayText}',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (theme.isPurchasable) ...[
                const SizedBox(height: 4),
                Text(
                  theme.description,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textHint),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                BlocBuilder<HydrationCubit, HydrationBlocState>(
                  builder: (ctx, st) {
                    final drops =
                        st is HydrationLoaded ? st.hydration.drops : 0;
                    final canAfford = drops >= theme.price;
                    return FilledButton.icon(
                      onPressed: canAfford
                          ? () async {
                              final cubit = ctx.read<HydrationCubit>();
                              final ok = await cubit.purchaseTheme(theme);
                              if (ok && sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop();
                                HapticFeedback.mediumImpact();
                                if (context.mounted) {
                                  context.pushNamed(
                                    'unlockReward',
                                    extra: {
                                      'type': UnlockRewardType.theme,
                                      'themeId': theme.id,
                                    },
                                  );
                                }
                              }
                            }
                          : null,
                      icon: const Icon(Icons.water_drop_rounded, size: 18),
                      label: Text(canAfford
                          ? 'Buy for ${theme.price} Drops'
                          : 'Need ${theme.price - drops} more Drops'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ActiveThemeColors.of(sheetCtx).primary,
                      ),
                    );
                  },
                ),
              ],
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
  final String? nickname;
  final bool isHomeDuck;
  final bool isBadgeDuck;
  final VoidCallback onTap;

  const _DuckCard({
    required this.duck,
    required this.isUnlocked,
    this.nickname,
    this.isHomeDuck = false,
    this.isBadgeDuck = false,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? duck.rarity.color.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: DuckAvatar(
                    duck: duck,
                    size: 56,
                    locked: !isUnlocked,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUnlocked ? (nickname ?? duck.name) : '???',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isUnlocked ? AppColors.textPrimary : AppColors.textHint,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Rarity dot (always centered) + status icons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
              if (isUnlocked && (isBadgeDuck || isHomeDuck))
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isBadgeDuck)
                        Icon(Icons.star_rounded,
                            size: 12, color: Colors.amber.shade700),
                      if (isBadgeDuck && isHomeDuck) const SizedBox(width: 2),
                      if (isHomeDuck)
                        Icon(Icons.home_rounded,
                            size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
            ],
          ),
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
                    : theme.isPurchasable
                        ? Icon(theme.icon, size: 20, color: Colors.grey)
                        : const Icon(Icons.lock_rounded,
                            size: 20, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                isUnlocked
                    ? theme.name
                    : theme.isPurchasable
                        ? theme.name
                        : '???',
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
// Market tab — category-based shop
// ═══════════════════════════════════════════════════════════════════════

enum _MarketCategory { items, accessories, themes, getDrops, waddlePlus }

class _MarketTab extends StatefulWidget {
  final HydrationLoaded loaded;
  final bool animate;
  const _MarketTab({required this.loaded, required this.animate});

  @override
  State<_MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<_MarketTab> {
  _MarketCategory _selected = _MarketCategory.items;

  @override
  Widget build(BuildContext context) {
    final hydration = widget.loaded.hydration;
    final tc = ActiveThemeColors.of(context);
    final drops = hydration.drops;
    final inventory = hydration.inventory;
    final animate = widget.animate;

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
                    if (hydration.isSubscribed)
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
                            Icon(Icons.verified_rounded,
                                color: Color(0xFFFFD54F), size: 16),
                            SizedBox(width: 3),
                            Text(
                              'Supporter',
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (inventory.doubleXpActive)
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

              const SizedBox(height: 12),

              // ── Category chips ──
              SizedBox(
                height: 36,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.75, 0.88, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 24),
                    children: [
                      _categoryChip(
                        tc: tc,
                        label: 'Items',
                        icon: Icons.shopping_bag_rounded,
                        category: _MarketCategory.items,
                      ),
                      const SizedBox(width: 8),
                      _categoryChip(
                        tc: tc,
                        label: 'Accessories',
                        icon: Icons.checkroom_rounded,
                        category: _MarketCategory.accessories,
                      ),
                      const SizedBox(width: 8),
                      _categoryChip(
                        tc: tc,
                        label: 'Themes',
                        icon: Icons.palette_rounded,
                        category: _MarketCategory.themes,
                      ),
                      const SizedBox(width: 8),
                      _categoryChip(
                        tc: tc,
                        label: 'Drops',
                        icon: Icons.add_circle_outline_rounded,
                        category: _MarketCategory.getDrops,
                      ),
                      const SizedBox(width: 8),
                      _categoryChip(
                        tc: tc,
                        label: 'Waddle+',
                        icon: Icons.verified_rounded,
                        category: _MarketCategory.waddlePlus,
                        accentColor: hydration.isSubscribed
                            ? const Color(0xFF66BB6A)
                            : const Color(0xFFFFD54F),
                      ),
                    ],
                  ),
                ),
              ).animateOnce(animate).fadeIn(delay: 120.ms),

              const SizedBox(height: 14),

              // ── Category content ──
              if (_selected == _MarketCategory.items) ...[
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
                  );
                }),
              ],

              if (_selected == _MarketCategory.accessories) ...[
                Text(
                  'Dress up your ducks with fun cosmetics!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // ── Active seasonal / holiday packs ──
                ...() {
                  final activePacks = SeasonalPacks.currentlyAvailable;
                  if (activePacks.isEmpty) return <Widget>[];
                  return <Widget>[
                    Row(
                      children: [
                        const Icon(Icons.card_giftcard_rounded,
                            size: 16, color: Color(0xFFFFD54F)),
                        const SizedBox(width: 6),
                        Text(
                          'Seasonal Packs',
                          style: AppTextStyles.labelLarge.copyWith(
                            fontSize: 13,
                            color: const Color(0xFFFFD54F),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFD54F).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Limited Time',
                            style: TextStyle(
                              color: const Color(0xFFFFD54F)
                                  .withValues(alpha: 0.85),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...activePacks.map((pack) {
                      final claimed =
                          hydration.claimedSeasonalPackIds.contains(pack.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SeasonalPackCard(
                          pack: pack,
                          claimed: claimed,
                          isSubscribed: hydration.isSubscribed,
                          drops: drops,
                          themeColors: tc,
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ];
                }(),

                // Group by slot
                for (final slot in AccessorySlot.values) ...[
                  Text(
                    slot.label,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  ...DuckAccessories.forSlot(slot).map((acc) {
                    final owned = hydration.ownedAccessoryIds.contains(acc.id);
                    final canBuy =
                        !acc.subscriberOnly || hydration.isSubscribed;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MarketAccessoryCard(
                        accessory: acc,
                        drops: drops,
                        owned: owned,
                        canBuy: canBuy,
                        themeColors: tc,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ],

              if (_selected == _MarketCategory.themes) ...[
                ...List.generate(ThemeRewards.purchasable.length, (i) {
                  final theme = ThemeRewards.purchasable[i];
                  final owned = hydration.purchasedThemeIds.contains(theme.id);
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            i < ThemeRewards.purchasable.length - 1 ? 10 : 0),
                    child: _MarketThemeCard(
                      theme: theme,
                      drops: drops,
                      owned: owned,
                      themeColors: tc,
                    ),
                  );
                }),
              ],

              if (_selected == _MarketCategory.getDrops) ...[
                Text(
                  'Top up your Drops stash instantly',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ...List.generate(DropBundles.all.length, (i) {
                  final bundle = DropBundles.all[i];
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: i < DropBundles.all.length - 1 ? 10 : 0),
                    child: _DropBundleCard(bundle: bundle, themeColors: tc),
                  );
                }),
              ],

              if (_selected == _MarketCategory.waddlePlus)
                _WaddlePlusSection(
                  isSubscribed: hydration.isSubscribed,
                  themeColors: tc,
                  animate: false,
                ),

              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _categoryChip({
    required ActiveThemeColors tc,
    required String label,
    required IconData icon,
    required _MarketCategory category,
    Color? accentColor,
  }) {
    final isActive = _selected == category;
    final color = accentColor ?? tc.primary;

    return GestureDetector(
      onTap: () => setState(() => _selected = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? null
              : Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isActive ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Accessory card for market ───────────────────────────────────────

class _MarketAccessoryCard extends StatelessWidget {
  final DuckAccessory accessory;
  final int drops;
  final bool owned;
  final bool canBuy;
  final ActiveThemeColors themeColors;

  const _MarketAccessoryCard({
    required this.accessory,
    required this.drops,
    required this.owned,
    required this.canBuy,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accessory.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(accessory.icon, color: accessory.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      accessory.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: accessory.rarity.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        accessory.rarity.label,
                        style: TextStyle(
                          color: accessory.rarity.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    if (accessory.subscriberOnly) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.streakGold),
                    ],
                  ],
                ),
                Text(accessory.description,
                    style: AppTextStyles.bodySmall, maxLines: 1),
              ],
            ),
          ),
          if (owned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Owned ✓',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else if (!canBuy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 12, color: AppColors.streakGold),
                  const SizedBox(width: 3),
                  Text(
                    'Waddle+',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: drops >= accessory.price
                  ? () async {
                      final confirmed = await showMarketConfirmation(
                        context,
                        action: 'purchase',
                        itemName: accessory.name,
                        cost: accessory.price,
                      );
                      if (confirmed && context.mounted) {
                        final ok = await context
                            .read<HydrationCubit>()
                            .purchaseAccessory(accessory.id);
                        HapticFeedback.mediumImpact();
                        if (ok && context.mounted) {
                          context.pushNamed(
                            'unlockReward',
                            extra: {
                              'type': UnlockRewardType.accessory,
                              'accessoryId': accessory.id,
                            },
                          );
                        }
                      }
                    }
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: drops >= accessory.price
                      ? themeColors.primary.withValues(alpha: 0.12)
                      : AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${accessory.price} 💧',
                  style: TextStyle(
                    color: drops >= accessory.price
                        ? themeColors.primary
                        : AppColors.textHint,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Seasonal pack card ─────────────────────────────────────────────

class _SeasonalPackCard extends StatelessWidget {
  final SeasonalPack pack;
  final bool claimed;
  final bool isSubscribed;
  final int drops;
  final ActiveThemeColors themeColors;

  const _SeasonalPackCard({
    required this.pack,
    required this.claimed,
    required this.isSubscribed,
    required this.drops,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = isSubscribed;
    final canAfford = isFree || drops >= pack.price;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pack.color.withValues(alpha: 0.18),
            pack.color.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: pack.color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: pack.color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(pack.icon, color: pack.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        pack.description,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (claimed)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Claimed ✓',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: canAfford
                        ? () async {
                            final confirmed = await showMarketConfirmation(
                              context,
                              action: isFree ? 'claim' : 'purchase',
                              itemName: '${pack.name} Pack',
                              cost: isFree ? 0 : pack.price,
                            );
                            if (confirmed && context.mounted) {
                              final success = await context
                                  .read<HydrationCubit>()
                                  .claimSeasonalPack(pack.id);
                              HapticFeedback.mediumImpact();
                              if (success && context.mounted) {
                                context.pushNamed(
                                  'seasonalPackUnlock',
                                  extra: pack.id,
                                );
                              }
                            }
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFree
                            ? const Color(0xFF66BB6A).withValues(alpha: 0.14)
                            : canAfford
                                ? themeColors.primary.withValues(alpha: 0.12)
                                : AppColors.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isFree ? 'Free ✦' : '${pack.price} 💧',
                        style: TextStyle(
                          color: isFree
                              ? const Color(0xFF66BB6A)
                              : canAfford
                                  ? themeColors.primary
                                  : AppColors.textHint,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Accessory & theme preview row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Theme chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pack.theme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: pack.theme.primaryColor.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette_rounded,
                          size: 14, color: pack.theme.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        pack.theme.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pack.theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Accessory chips
                ...pack.accessories.map((acc) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: acc.color.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(acc.icon, size: 14, color: acc.color),
                        const SizedBox(width: 4),
                        Text(
                          acc.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
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
    final bool canActivate;
    switch (item.id) {
      case 'double_xp':
        canActivate = inventory.doubleXpTokens > 0 && !inventory.doubleXpActive;
        break;
      case 'cooldown_skip':
        canActivate = inventory.cooldownSkips > 0;
        break;
      default:
        canActivate = false;
    }
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
                      maxLines: 4,
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
                                    final confirmed =
                                        await showMarketConfirmation(
                                      context,
                                      action: 'purchase',
                                      itemName: item.name,
                                      cost: item.price,
                                    );
                                    if (!confirmed || !context.mounted) return;
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
                              final confirmed = await showMarketConfirmation(
                                context,
                                action: 'use',
                                itemName: item.name,
                              );
                              if (!confirmed || !context.mounted) return;
                              final cubit = context.read<HydrationCubit>();
                              switch (item.id) {
                                case 'double_xp':
                                  await cubit.activateDoubleXp();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            '⚡ Double XP activated for 24 hours!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  break;
                                case 'cooldown_skip':
                                  final ok = await cubit.useCooldownSkip();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(ok
                                            ? '⏩ Quest cooldown skipped!'
                                            : 'No active cooldown to skip.'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                  break;
                              }
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

// ─── Market theme card ───────────────────────────────────────────────

class _MarketThemeCard extends StatelessWidget {
  final ThemeReward theme;
  final int drops;
  final bool owned;
  final ActiveThemeColors themeColors;

  const _MarketThemeCard({
    required this.theme,
    required this.drops,
    required this.owned,
    required this.themeColors,
  });

  Color get _tierColor {
    switch (theme.tier) {
      case ThemeTier.common:
        return const Color(0xFF78909C);
      case ThemeTier.uncommon:
        return const Color(0xFF66BB6A);
      case ThemeTier.rare:
        return const Color(0xFF42A5F5);
      case ThemeTier.epic:
        return const Color(0xFFAB47BC);
      case ThemeTier.legendary:
        return const Color(0xFFFFB300);
      case ThemeTier.free:
        return const Color(0xFF90CAF9);
    }
  }

  String get _tierLabel {
    switch (theme.tier) {
      case ThemeTier.common:
        return 'Common';
      case ThemeTier.uncommon:
        return 'Uncommon';
      case ThemeTier.rare:
        return 'Rare';
      case ThemeTier.epic:
        return 'Epic';
      case ThemeTier.legendary:
        return 'Legendary';
      case ThemeTier.free:
        return 'Free';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAfford = drops >= theme.price;
    final canBuy = canAfford && !owned;
    final dark = HSLColor.fromColor(_tierColor)
        .withLightness(
            (HSLColor.fromColor(_tierColor).lightness - 0.25).clamp(0.0, 1.0))
        .toColor();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _tierColor.withValues(alpha: 0.16),
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
            // ── Gradient preview strip ──
            Container(
              width: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.gradientColors,
                ),
              ),
              child: Center(
                child: Icon(theme.icon, color: Colors.white, size: 26),
              ),
            ),

            // ── Content ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            theme.name,
                            style: TextStyle(
                              color: dark,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tierColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _tierLabel,
                            style: TextStyle(
                              color: _tierColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      theme.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: canBuy
                                ? () async {
                                    HapticFeedback.mediumImpact();
                                    final confirmed =
                                        await showMarketConfirmation(
                                      context,
                                      action: 'purchase',
                                      itemName: theme.name,
                                      cost: theme.price,
                                    );
                                    if (!confirmed || !context.mounted) return;
                                    final ok = await context
                                        .read<HydrationCubit>()
                                        .purchaseTheme(theme);
                                    if (ok && context.mounted) {
                                      HapticFeedback.mediumImpact();
                                      context.pushNamed(
                                        'unlockReward',
                                        extra: {
                                          'type': UnlockRewardType.theme,
                                          'themeId': theme.id,
                                        },
                                      );
                                    }
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                gradient: canBuy
                                    ? LinearGradient(
                                        colors: [_tierColor, dark],
                                      )
                                    : null,
                                color: canBuy ? null : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: canBuy
                                    ? [
                                        BoxShadow(
                                          color: _tierColor.withValues(
                                              alpha: 0.30),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: owned
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              size: 14,
                                              color: canBuy
                                                  ? Colors.white
                                                  : AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Owned',
                                            style: TextStyle(
                                              color: canBuy
                                                  ? Colors.white
                                                  : AppColors.textHint,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.water_drop,
                                              size: 13,
                                              color: canBuy
                                                  ? Colors.white
                                                  : AppColors.textHint),
                                          const SizedBox(width: 3),
                                          Text(
                                            canAfford
                                                ? '${theme.price} Drops'
                                                : 'Need ${theme.price - drops} more',
                                            style: TextStyle(
                                              color: canBuy
                                                  ? Colors.white
                                                  : AppColors.textHint,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
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

// ─── Drop Bundle card (real-money IAP) ──────────────────────────────

class _DropBundleCard extends StatelessWidget {
  final DropBundle bundle;
  final ActiveThemeColors themeColors;

  const _DropBundleCard({required this.bundle, required this.themeColors});

  @override
  Widget build(BuildContext context) {
    final iap = GetIt.instance<IapService>();
    final storePrice = iap.priceFor(bundle.productId);
    final displayPrice = storePrice ?? bundle.displayPrice;

    final dark = HSLColor.fromColor(bundle.color)
        .withLightness(
            (HSLColor.fromColor(bundle.color).lightness - 0.25).clamp(0.0, 1.0))
        .toColor();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: bundle.color.withValues(alpha: 0.16),
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
                    bundle.color.withValues(alpha: 0.30),
                    bundle.color.withValues(alpha: 0.12),
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
                        bundle.color.withValues(alpha: 0.50),
                        bundle.color.withValues(alpha: 0.22),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: bundle.color.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(bundle.icon, color: dark, size: 22),
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
                    Row(
                      children: [
                        Text(
                          bundle.name,
                          style: TextStyle(
                            color: dark,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (bundle.popular) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Popular',
                              style: TextStyle(
                                color: Color(0xFFFF9800),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        if (bundle.bestValue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF66BB6A)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Best Value',
                              style: TextStyle(
                                color: Color(0xFF66BB6A),
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
                              '${bundle.drops}',
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
                    Text(
                      bundle.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        await iap.purchaseDropBundle(bundle);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [bundle.color, dark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: bundle.color.withValues(alpha: 0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            displayPrice,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
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

// ─── Waddle+ subscription section ─────────────────────────────────

class _WaddlePlusSection extends StatelessWidget {
  final bool isSubscribed;
  final ActiveThemeColors themeColors;
  final bool animate;

  const _WaddlePlusSection({
    required this.isSubscribed,
    required this.themeColors,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final iap = GetIt.instance<IapService>();
    const accentGold = Color(0xFFFFD54F);
    const accentGoldDark = Color(0xFFF9A825);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: accentGold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Waddle+',
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isSubscribed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF66BB6A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Supporter',
                            style: TextStyle(
                              color: Color(0xFF66BB6A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!isSubscribed) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Support a solo developer & unlock perks',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Image.asset(
              'lib/assets/images/wade_wave.png',
              width: 56,
              height: 56,
            ),
          ],
        ),

        // ── Subscriber thank-you or pitch ──
        if (isSubscribed) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentGold.withValues(alpha: 0.10),
                  const Color(0xFF66BB6A).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentGold.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE57373), size: 28),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for your support!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Waddle is built by a solo developer, and your '
                  'subscription helps keep it alive and growing. '
                  'You\'re officially a Waddle Supporter — your name '
                  'may appear in the credits of future updates!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.60),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 8),

        // ── Perk list ──
        ...List.generate(SubscriptionPerks.all.length, (i) {
          final perk = SubscriptionPerks.all[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: perk.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: perk.color.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: perk.color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(perk.icon, color: perk.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          perk.title,
                          style: TextStyle(
                            color: perk.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          perk.description,
                          style: TextStyle(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.85),
                            fontSize: 11,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSubscribed)
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF66BB6A), size: 18),
                ],
              ),
            ),
          );
        }),

        // ── Subscription buttons ──
        if (!isSubscribed) ...[
          const SizedBox(height: 6),
          ...Subscriptions.all.map((tier) {
            final storePrice = iap.priceFor(tier.productId);
            final displayPrice = storePrice ?? tier.displayPrice;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  await iap.purchaseSubscription(tier);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [accentGold, accentGoldDark],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: accentGold.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Subscribe $displayPrice',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (tier.savings != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tier.savings!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          // Restore purchases link
          Center(
            child: GestureDetector(
              onTap: () async {
                await iap.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking for previous purchases...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
