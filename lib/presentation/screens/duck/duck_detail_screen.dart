import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/duck_accessory.dart';
import 'package:waddle/domain/entities/duck_bond.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/presentation/widgets/duck_avatar.dart';

/// Full-screen duck detail / dress-up screen for an owned duck.
class DuckDetailScreen extends StatefulWidget {
  final int duckIndex;
  const DuckDetailScreen({super.key, required this.duckIndex});

  @override
  State<DuckDetailScreen> createState() => _DuckDetailScreenState();
}

class _DuckDetailScreenState extends State<DuckDetailScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _nameCtrl;
  late final FocusNode _nameFocus;
  bool _feedAnimating = false;
  bool _justLeveledUp = false;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    final state = context.read<HydrationCubit>().state;
    final bond = (state is HydrationLoaded)
        ? state.hydration.duckBonds[widget.duckIndex]
        : null;
    _nameCtrl = TextEditingController(text: bond?.nickname ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  DuckCompanion get _duck => DuckCompanions.all[widget.duckIndex];

  @override
  Widget build(BuildContext context) {
    final themeColors = ActiveThemeColors.of(context);

    return BlocBuilder<HydrationCubit, HydrationBlocState>(
      builder: (context, state) {
        if (state is! HydrationLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final h = state.hydration;
        final bond = h.duckBonds[widget.duckIndex] ?? const DuckBondData();
        final passive = DuckPassives.all[widget.duckIndex];
        final isActiveBadge = h.activeDuckIndex == widget.duckIndex;
        final isHomeDuck = h.homeDuckIndices.contains(widget.duckIndex);
        final homeCount = h.homeDuckIndices.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              bond.nickname ?? _duck.name,
              style: AppTextStyles.headlineSmall,
            ),
            centerTitle: true,
            actions: [
              // Rarity badge
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _duck.rarity.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _duck.rarity.label,
                  style: TextStyle(
                    color: _duck.rarity.color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── Duck avatar with bond ring ──────────────────────
                _DuckAvatarSection(
                  duck: _duck,
                  duckIndex: widget.duckIndex,
                  bond: bond,
                  ownedAccessoryIds: h.ownedAccessoryIds,
                  feedAnimating: _feedAnimating,
                  justLeveledUp: _justLeveledUp,
                )
                    .animate()
                    .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 20),

                // ── Rename field ────────────────────────────────────
                _RenameField(
                  controller: _nameCtrl,
                  focusNode: _nameFocus,
                  defaultName: _duck.name,
                  onSubmitted: (name) {
                    context.read<HydrationCubit>().renameDuck(
                          widget.duckIndex,
                          name.trim().isEmpty ? '' : name.trim(),
                        );
                    _nameFocus.unfocus();
                  },
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // ── Bond level + feed ───────────────────────────────
                _BondSection(
                  bond: bond,
                  passive: passive,
                  drops: h.drops,
                  themeColor: themeColors.primary,
                  feedAnimating: _feedAnimating,
                  onFeed: () => _handleFeed(bond),
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),

                const SizedBox(height: 20),

                // ── Passive bonus card ──────────────────────────────
                if (passive != null)
                  _PassiveBonusCard(
                    passive: passive,
                    bond: bond,
                    isHomeDuck: isHomeDuck,
                    themeColor: themeColors.primary,
                  )
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 400.ms)
                      .slideY(begin: 0.15, end: 0),

                const SizedBox(height: 20),

                // ── Accessory slots ─────────────────────────────────
                _AccessorySlotsSection(
                  duckIndex: widget.duckIndex,
                  bond: bond,
                  ownedAccessoryIds: h.ownedAccessoryIds,
                  themeColor: themeColors.primary,
                )
                    .animate()
                    .fadeIn(delay: 450.ms, duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),

                const SizedBox(height: 24),

                // ── Action buttons ──────────────────────────────────
                _ActionButtons(
                  duckIndex: widget.duckIndex,
                  isActiveBadge: isActiveBadge,
                  isHomeDuck: isHomeDuck,
                  homeCount: homeCount,
                  homeDuckIndices: h.homeDuckIndices,
                  duckBonds: h.duckBonds,
                  themeColor: themeColors.primary,
                )
                    .animate()
                    .fadeIn(delay: 550.ms, duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleFeed(DuckBondData bond) async {
    if (_feedAnimating) return;
    if (bond.bondLevel >= DuckBondLevels.maxLevel) return;

    final cost = DuckBondLevels.costToLevel(bond.bondLevel + 1);
    final state = context.read<HydrationCubit>().state;
    if (state is! HydrationLoaded) return;
    if (state.hydration.drops < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough drops! Need $cost 💧'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _feedAnimating = true;
      _justLeveledUp = false;
    });

    HapticFeedback.mediumImpact();

    final success =
        await context.read<HydrationCubit>().feedDuck(widget.duckIndex);

    if (success && mounted) {
      setState(() => _justLeveledUp = true);
      HapticFeedback.heavyImpact();
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _feedAnimating = false;
        _justLeveledUp = false;
      });
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DUCK AVATAR SECTION — large duck with bond ring & accessories
// ═══════════════════════════════════════════════════════════════════════

class _DuckAvatarSection extends StatelessWidget {
  final DuckCompanion duck;
  final int duckIndex;
  final DuckBondData bond;
  final List<String> ownedAccessoryIds;
  final bool feedAnimating;
  final bool justLeveledUp;

  const _DuckAvatarSection({
    required this.duck,
    required this.duckIndex,
    required this.bond,
    required this.ownedAccessoryIds,
    required this.feedAnimating,
    required this.justLeveledUp,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (bond.bondLevel - 1) / (DuckBondLevels.maxLevel - 1);

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bond level ring
          SizedBox(
            width: 170,
            height: 170,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 4,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                bond.bondLevel >= DuckBondLevels.maxLevel
                    ? AppColors.streakGold
                    : AppColors.primary,
              ),
            ),
          ),

          // Glow on level-up
          if (justLeveledUp)
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.streakGold.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.forward())
                .fadeIn(duration: 300.ms)
                .then()
                .fadeOut(delay: 600.ms, duration: 400.ms),

          // Duck circle background
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: duck.rarity.color.withValues(alpha: 0.1),
              border: bond.bondLevel >= DuckBondLevels.maxLevel
                  ? Border.all(color: AppColors.streakGold, width: 2)
                  : null,
            ),
          ),

          // Duck avatar with gentle floating
          _AnimatedDuckAvatar(
            duck: duck,
            feedAnimating: feedAnimating,
          ),

          // Accessory overlays
          ..._buildAccessoryOverlays(),

          // Bond level badge
          Positioned(
            bottom: 0,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: bond.bondLevel >= DuckBondLevels.maxLevel
                    ? AppColors.streakGold
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Lv.${bond.bondLevel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 300.ms)
                .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAccessoryOverlays() {
    final overlays = <Widget>[];

    // Map slots to positions (offsets relative to center)
    const positions = {
      AccessorySlot.hat: Offset(0, -60),
      AccessorySlot.eyewear: Offset(0, -20),
      AccessorySlot.neckwear: Offset(0, 20),
      AccessorySlot.held: Offset(50, 10),
    };

    for (final slot in AccessorySlot.values) {
      final accId = bond.accessoryForSlot(slot);
      if (accId == null) continue;

      final accessory = DuckAccessories.byId(accId);
      if (accessory == null) continue;

      final offset = positions[slot]!;

      overlays.add(
        Positioned(
          left: 90 + offset.dx - 12,
          top: 90 + offset.dy - 12,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accessory.color.withValues(alpha: 0.85),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accessory.color.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(accessory.icon, size: 14, color: Colors.white),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 2000.ms,
              ),
        ),
      );
    }

    return overlays;
  }
}

/// Duck avatar with gentle floating animation + feed bounce.
class _AnimatedDuckAvatar extends StatelessWidget {
  final DuckCompanion duck;
  final bool feedAnimating;

  const _AnimatedDuckAvatar({
    required this.duck,
    required this.feedAnimating,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = DuckAvatar(duck: duck, size: 110);

    // Gentle idle floating
    avatar = avatar
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -4, end: 4, duration: 2500.ms, curve: Curves.easeInOut);

    // Feed bounce
    if (feedAnimating) {
      avatar = avatar
          .animate(onPlay: (c) => c.forward())
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.15, 1.15),
            duration: 200.ms,
            curve: Curves.easeOut,
          )
          .then()
          .scale(
            begin: const Offset(1.15, 1.15),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.elasticOut,
          )
          .then()
          .shimmer(
              duration: 800.ms,
              color: AppColors.streakGold.withValues(alpha: 0.3));
    }

    return avatar;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RENAME FIELD
// ═══════════════════════════════════════════════════════════════════════

class _RenameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String defaultName;
  final ValueChanged<String> onSubmitted;

  const _RenameField({
    required this.controller,
    required this.focusNode,
    required this.defaultName,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_rounded, size: 18, color: AppColors.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: defaultName,
                hintStyle:
                    AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              maxLength: 20,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.done,
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onSubmitted('');
              },
              child: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BOND SECTION — level bar + feed button
// ═══════════════════════════════════════════════════════════════════════

class _BondSection extends StatelessWidget {
  final DuckBondData bond;
  final DuckPassive? passive;
  final int drops;
  final Color themeColor;
  final bool feedAnimating;
  final VoidCallback onFeed;

  const _BondSection({
    required this.bond,
    required this.passive,
    required this.drops,
    required this.themeColor,
    required this.feedAnimating,
    required this.onFeed,
  });

  @override
  Widget build(BuildContext context) {
    final isMaxLevel = bond.bondLevel >= DuckBondLevels.maxLevel;
    final cost =
        isMaxLevel ? 0 : DuckBondLevels.costToLevel(bond.bondLevel + 1);
    final canAfford = drops >= cost;
    final progress = (bond.bondLevel - 1) / (DuckBondLevels.maxLevel - 1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
              const SizedBox(width: 8),
              Text('Bond Level', style: AppTextStyles.labelLarge),
              const Spacer(),
              Text(
                isMaxLevel
                    ? 'MAX ✨'
                    : '${bond.bondLevel} / ${DuckBondLevels.maxLevel}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      isMaxLevel ? AppColors.streakGold : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(
                isMaxLevel ? AppColors.streakGold : themeColor,
              ),
            ),
          ),

          // Next-level preview
          if (!isMaxLevel && passive != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: themeColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 16, color: themeColor),
                  const SizedBox(width: 6),
                  Text(
                    'Next level:',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (passive!.improvesAtNextLevel(bond.bondLevel))
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          passive!.formattedValue(bond.bondLevel),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_forward_rounded,
                              size: 14, color: themeColor),
                        ),
                        Text(
                          passive!.nextLevelFormatted(bond.bondLevel)!,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: themeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${passive!.formattedValue(bond.bondLevel)}  (no change)',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Feed button
          if (!isMaxLevel)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: feedAnimating || !canAfford ? null : onFeed,
                icon: feedAnimating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.restaurant_rounded, size: 18),
                label: Text(
                  feedAnimating ? 'Feeding...' : 'Feed  •  $cost 💧',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford ? themeColor : AppColors.divider,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
            Center(
              child: Text(
                '🌟 Fully bonded! Your duck loves you.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.streakGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (!isMaxLevel) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Your drops: $drops 💧',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PASSIVE BONUS CARD
// ═══════════════════════════════════════════════════════════════════════

class _PassiveBonusCard extends StatelessWidget {
  final DuckPassive passive;
  final DuckBondData bond;
  final bool isHomeDuck;
  final Color themeColor;

  const _PassiveBonusCard({
    required this.passive,
    required this.bond,
    required this.isHomeDuck,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isHomeDuck
            ? Border.all(color: themeColor.withValues(alpha: 0.3), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: isHomeDuck
                ? themeColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isHomeDuck ? 16 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with glow when active
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (isHomeDuck ? themeColor : AppColors.textHint)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              passive.type.icon,
              color: isHomeDuck ? themeColor : AppColors.textHint,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passive.name,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isHomeDuck ? themeColor : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(passive.description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                passive.formattedValue(bond.bondLevel),
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isHomeDuck ? themeColor : AppColors.textHint,
                  fontSize: 16,
                ),
              ),
              if (!isHomeDuck)
                Text(
                  'Not on home',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontSize: 10,
                  ),
                ),
              if (isHomeDuck)
                Text(
                  'Active ✓',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSORY SLOTS — 4 slot grid with tap-to-equip
// ═══════════════════════════════════════════════════════════════════════

class _AccessorySlotsSection extends StatelessWidget {
  final int duckIndex;
  final DuckBondData bond;
  final List<String> ownedAccessoryIds;
  final Color themeColor;

  const _AccessorySlotsSection({
    required this.duckIndex,
    required this.bond,
    required this.ownedAccessoryIds,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checkroom_rounded, size: 20, color: themeColor),
            const SizedBox(width: 8),
            Text('Accessories', style: AppTextStyles.labelLarge),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: AccessorySlot.values.map((slot) {
            final accId = bond.accessoryForSlot(slot);
            final accessory =
                accId != null ? DuckAccessories.byId(accId) : null;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _AccessorySlotCard(
                  slot: slot,
                  accessory: accessory,
                  themeColor: themeColor,
                  onTap: () => _showAccessoryPicker(context, slot),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showAccessoryPicker(BuildContext context, AccessorySlot slot) {
    final slotAccessories = DuckAccessories.forSlot(slot);
    final cubit = context.read<HydrationCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: BlocBuilder<HydrationCubit, HydrationBlocState>(
          builder: (ctx, state) {
            if (state is! HydrationLoaded) return const SizedBox.shrink();

            final h = state.hydration;
            final currentBond = h.duckBonds[duckIndex] ?? const DuckBondData();
            final currentEquipped = currentBond.accessoryForSlot(slot);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.55,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(slot.icon, color: themeColor, size: 20),
                        const SizedBox(width: 8),
                        Text(slot.label, style: AppTextStyles.headlineSmall),
                        const Spacer(),
                        if (currentEquipped != null)
                          TextButton(
                            onPressed: () {
                              cubit.unequipAccessory(duckIndex, slot);
                              HapticFeedback.lightImpact();
                            },
                            child: const Text('Remove'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: slotAccessories.length,
                      itemBuilder: (ctx, i) {
                        final acc = slotAccessories[i];
                        final isOwned = h.ownedAccessoryIds.contains(acc.id);
                        final isEquipped = currentEquipped == acc.id;
                        final canBuy = !acc.subscriberOnly || h.isSubscribed;

                        return _AccessoryPickerTile(
                          accessory: acc,
                          isOwned: isOwned,
                          isEquipped: isEquipped,
                          canBuy: canBuy,
                          drops: h.drops,
                          themeColor: themeColor,
                          onEquip: () {
                            cubit.equipAccessory(duckIndex, acc.id);
                            HapticFeedback.mediumImpact();
                            Navigator.pop(ctx);
                          },
                          onBuy: () async {
                            final success =
                                await cubit.purchaseAccessory(acc.id);
                            if (success) {
                              HapticFeedback.heavyImpact();
                              cubit.equipAccessory(duckIndex, acc.id);
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                        )
                            .animate()
                            .fadeIn(
                              delay: (50 * i).ms,
                              duration: 300.ms,
                            )
                            .slideX(begin: 0.05, end: 0);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AccessorySlotCard extends StatelessWidget {
  final AccessorySlot slot;
  final DuckAccessory? accessory;
  final Color themeColor;
  final VoidCallback onTap;

  const _AccessorySlotCard({
    required this.slot,
    required this.accessory,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = accessory == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        height: 80,
        decoration: BoxDecoration(
          color: isEmpty
              ? AppColors.surfaceLight
              : accessory!.rarity.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEmpty
                ? AppColors.divider
                : accessory!.rarity.color.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEmpty ? Icons.add_circle_outline_rounded : accessory!.icon,
              size: isEmpty ? 22 : 26,
              color: isEmpty ? AppColors.textHint : accessory!.color,
            ),
            const SizedBox(height: 4),
            Text(
              isEmpty ? slot.label : accessory!.name,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
                fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessoryPickerTile extends StatelessWidget {
  final DuckAccessory accessory;
  final bool isOwned;
  final bool isEquipped;
  final bool canBuy;
  final int drops;
  final Color themeColor;
  final VoidCallback onEquip;
  final VoidCallback onBuy;

  const _AccessoryPickerTile({
    required this.accessory,
    required this.isOwned,
    required this.isEquipped,
    required this.canBuy,
    required this.drops,
    required this.themeColor,
    required this.onEquip,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEquipped
              ? themeColor.withValues(alpha: 0.08)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: isEquipped
              ? Border.all(color: themeColor.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accessory.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(accessory.icon, color: accessory.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Details
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
                        Icon(Icons.star_rounded,
                            size: 14, color: AppColors.streakGold),
                      ],
                    ],
                  ),
                  Text(accessory.description,
                      style: AppTextStyles.bodySmall, maxLines: 1),
                ],
              ),
            ),
            // Action
            if (isEquipped)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Equipped',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            else if (isOwned)
              GestureDetector(
                onTap: onEquip,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Equip',
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else if (!canBuy)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Icon(Icons.lock_rounded,
                    size: 18, color: AppColors.textHint),
              )
            else
              GestureDetector(
                onTap: drops >= accessory.price ? onBuy : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: drops >= accessory.price
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.divider,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${accessory.price} 💧',
                    style: TextStyle(
                      color: drops >= accessory.price
                          ? AppColors.success
                          : AppColors.textHint,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACTION BUTTONS — badge + home
// ═══════════════════════════════════════════════════════════════════════

class _ActionButtons extends StatelessWidget {
  final int duckIndex;
  final bool isActiveBadge;
  final bool isHomeDuck;
  final int homeCount;
  final List<int> homeDuckIndices;
  final Map<int, DuckBondData> duckBonds;
  final Color themeColor;

  const _ActionButtons({
    required this.duckIndex,
    required this.isActiveBadge,
    required this.isHomeDuck,
    required this.homeCount,
    required this.homeDuckIndices,
    required this.duckBonds,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Set as Badge
        Expanded(
          child: _DetailActionButton(
            icon:
                isActiveBadge ? Icons.star_rounded : Icons.star_border_rounded,
            label: isActiveBadge ? 'Badge ✓' : 'Set as Badge',
            isActive: isActiveBadge,
            themeColor: themeColor,
            onTap: () {
              context.read<HydrationCubit>().setActiveDuck(
                    isActiveBadge ? null : duckIndex,
                  );
              HapticFeedback.lightImpact();
            },
          ),
        ),
        const SizedBox(width: 12),
        // Add to Home
        Expanded(
          child: _DetailActionButton(
            icon: isHomeDuck ? Icons.home_rounded : Icons.home_outlined,
            label: isHomeDuck
                ? 'Home ✓'
                : homeCount >= 3
                    ? 'Replace'
                    : 'Add to Home',
            isActive: isHomeDuck,
            themeColor: themeColor,
            onTap: isHomeDuck
                ? () {
                    context.read<HydrationCubit>().toggleHomeDuck(duckIndex);
                    HapticFeedback.lightImpact();
                  }
                : homeCount >= 3
                    ? () => _showReplacePicker(context)
                    : () {
                        context
                            .read<HydrationCubit>()
                            .toggleHomeDuck(duckIndex);
                        HapticFeedback.lightImpact();
                      },
          ),
        ),
      ],
    );
  }

  void _showReplacePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Text(
              'Replace which duck?',
              style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose a duck to swap out',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ...homeDuckIndices.map((homeIdx) {
              final duck = DuckCompanions.all[homeIdx];
              final bond = duckBonds[homeIdx];
              final displayName =
                  (bond?.nickname != null && bond!.nickname!.isNotEmpty)
                      ? bond.nickname!
                      : duck.name;
              final passive = DuckPassives.all[homeIdx];
              final passiveName = passive?.name ?? '';
              final passiveDesc = passive?.description ?? '';
              final bondLevel = (bond?.bondLevel ?? 1).clamp(1, 10);
              final passiveValue = passive?.formattedValue(bondLevel) ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context
                        .read<HydrationCubit>()
                        .replaceHomeDuck(homeIdx, duckIndex);
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: duck.rarity.color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: duck.rarity.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        DuckAvatar(duck: duck, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: AppTextStyles.labelLarge,
                              ),
                              Text(
                                '$passiveName ($passiveValue)',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: duck.rarity.color,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                passiveDesc,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.swap_horiz_rounded,
                            color: themeColor, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color themeColor;
  final VoidCallback? onTap;

  const _DetailActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.themeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? themeColor.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? themeColor.withValues(alpha: 0.3)
                : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: onTap == null
                  ? AppColors.textHint
                  : isActive
                      ? themeColor
                      : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: onTap == null
                    ? AppColors.textHint
                    : isActive
                        ? themeColor
                        : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
