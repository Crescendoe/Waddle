import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/shop_item.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart'
    as bloc;
import 'package:waddle/presentation/widgets/common.dart';

/// Opens the Drops shop as a bottom sheet.
void showShopSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<HydrationCubit>(),
      child: const _ShopSheet(),
    ),
  );
}

class _ShopSheet extends StatelessWidget {
  const _ShopSheet();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HydrationCubit, bloc.HydrationBlocState,
        HydrationState?>(
      selector: (state) =>
          state is bloc.HydrationLoaded ? state.hydration : null,
      builder: (context, hydration) {
        if (hydration == null) return const SizedBox.shrink();

        final tc = ActiveThemeColors.of(context);
        final drops = hydration.drops;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, color: tc.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Shop',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const Spacer(),
                    // Drops balance
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: tc.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: tc.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.water_drop, size: 16, color: tc.accent),
                          const SizedBox(width: 4),
                          Text(
                            '$drops',
                            style: TextStyle(
                              color: tc.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Shop items
              ...ShopItems.all.map((item) => _ShopItemTile(
                    item: item,
                    drops: drops,
                    inventory: hydration.inventory,
                    themeColors: tc,
                  )),

              // Active boosts section
              if (hydration.inventory.doubleXpActive)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: Color(0xFFFFD54F), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Double XP active!',
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Until midnight',
                          style: TextStyle(
                            color:
                                const Color(0xFFFFD54F).withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        );
      },
    );
  }
}

class _ShopItemTile extends StatelessWidget {
  final ShopItem item;
  final int drops;
  final UserInventory inventory;
  final ActiveThemeColors themeColors;

  const _ShopItemTile({
    required this.item,
    required this.drops,
    required this.inventory,
    required this.themeColors,
  });

  @override
  Widget build(BuildContext context) {
    final owned = inventory.countOf(item.id);
    final canAfford = drops >= item.price;
    final canBuy = canAfford && inventory.canPurchase(item);
    final isDoubleXp = item.id == 'double_xp';
    final canActivate =
        isDoubleXp && inventory.doubleXpTokens > 0 && !inventory.doubleXpActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            // Item icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 12),
            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (owned > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '×$owned',
                            style: TextStyle(
                              color: themeColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            Column(
              children: [
                // Buy button
                GestureDetector(
                  onTap: canBuy
                      ? () async {
                          HapticFeedback.mediumImpact();
                          await context
                              .read<HydrationCubit>()
                              .purchaseShopItem(item);
                        }
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: canBuy
                          ? themeColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 12,
                          color:
                              canBuy ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.price}',
                          style: TextStyle(
                            color:
                                canBuy ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Activate button (for consumables that have a "use" action)
                if (canActivate) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await context.read<HydrationCubit>().activateDoubleXp();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              const Color(0xFFFFD54F).withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Text(
                        'Use',
                        style: TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
