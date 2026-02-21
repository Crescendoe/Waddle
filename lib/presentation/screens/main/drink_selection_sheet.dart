import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/drink_type.dart';

class DrinkSelectionSheet extends StatefulWidget {
  final int? activeChallengeIndex;
  final void Function(String drinkName, double amountOz, double waterRatio)
      onDrinkSelected;

  const DrinkSelectionSheet({
    super.key,
    required this.onDrinkSelected,
    this.activeChallengeIndex,
  });

  @override
  State<DrinkSelectionSheet> createState() => _DrinkSelectionSheetState();
}

class _DrinkSelectionSheetState extends State<DrinkSelectionSheet> {
  DrinkType? _selectedDrink;
  double _amountOz = 8.0;
  Set<String> _favoriteDrinkNames = {};
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favs =
        prefs.getStringList(AppConstants.prefFavoriteDrinks) ?? <String>[];
    if (mounted) setState(() => _favoriteDrinkNames = favs.toSet());
  }

  Future<void> _toggleFavorite(String drinkName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteDrinkNames.contains(drinkName)) {
        _favoriteDrinkNames.remove(drinkName);
      } else {
        _favoriteDrinkNames.add(drinkName);
      }
    });
    await prefs.setStringList(
        AppConstants.prefFavoriteDrinks, _favoriteDrinkNames.toList());
  }

  List<DrinkType> get _availableDrinks {
    if (widget.activeChallengeIndex != null) {
      return DrinkTypes.forChallenge(widget.activeChallengeIndex!);
    }
    return DrinkTypes.all;
  }

  List<DrinkType> get _filteredDrinks {
    if (_searchQuery.isEmpty) return _availableDrinks;
    final q = _searchQuery.toLowerCase();
    return _availableDrinks
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.category.name.toLowerCase().contains(q))
        .toList();
  }

  /// Suggest a healthier swap for limit-tier drinks
  DrinkType? _healthierSwap(DrinkType drink) {
    const swaps = {
      'Soda': 'Sparkling Water',
      'Diet Soda': 'Sparkling Water',
      'Energy Drink': 'Green Tea',
      'Milkshake': 'Protein Shake',
      'Root Beer': 'Sparkling Water',
      'Frappuccino': 'Cold Brew',
      'Bubble Tea': 'Iced Tea',
      'Eggnog': 'Whole Milk',
      'Cocktail': 'Sparkling Water',
      'Spirits': 'Water',
      'Wine': 'Kombucha',
      'Beer': 'Sparkling Water',
      'Hard Seltzer': 'Club Soda',
    };
    final swapName = swaps[drink.name];
    if (swapName == null) return DrinkTypes.byName('Water');
    return DrinkTypes.byName(swapName) ?? DrinkTypes.byName('Water');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _selectedDrink == null ? 'Choose a Drink' : 'Set Amount',
              style: AppTextStyles.headlineSmall,
            ),
          ),
          if (_selectedDrink == null)
            _buildDrinkGrid()
          else
            _buildAmountSlider(),
        ],
      ),
    );
  }

  Widget _buildDrinkGrid() {
    final drinks = _filteredDrinks;

    // Favorites (only from available drinks, matching search)
    final favDrinks =
        drinks.where((d) => _favoriteDrinkNames.contains(d.name)).toList();

    // Group remaining drinks by category
    final categories = <DrinkCategory, List<DrinkType>>{};
    for (final drink in drinks) {
      categories.putIfAbsent(drink.category, () => []).add(drink);
    }

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search drinks...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(Icons.close_rounded,
                            color: AppColors.textSecondary, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              style: AppTextStyles.bodySmall,
            ),
          ),

          // Health tier legend
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: HealthTier.values.map((tier) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tier.icon, size: 11, color: tier.color),
                      const SizedBox(width: 3),
                      Text(
                        tier.label,
                        style: TextStyle(
                          fontSize: 10,
                          color: tier.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Hint text
          if (_searchQuery.isEmpty && _favoriteDrinkNames.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Long-press a drink to add it to favorites',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // ── Favorites section ──
          if (favDrinks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Favorites',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favDrinks.map((drink) {
                return _buildDrinkChip(drink, isFavorite: true);
              }).toList(),
            ),
            const Divider(height: 20),
          ],

          // ── Category sections ──
          ...categories.entries.toList().asMap().entries.map((entry) {
            final categoryEntry = entry.value;
            final index = entry.key;
            final categoryName = _categoryDisplayName(categoryEntry.key);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    categoryName,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryEntry.value.map((drink) {
                    final isFav = _favoriteDrinkNames.contains(drink.name);
                    return _buildDrinkChip(drink, isFavorite: isFav);
                  }).toList(),
                ),
                if (index < categories.length - 1) const Divider(height: 20),
              ],
            ).animate().fadeIn(delay: (index * 60).ms);
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _categoryDisplayName(DrinkCategory cat) {
    final name = cat.name.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return name[0].toUpperCase() + name.substring(1);
  }

  Widget _buildDrinkChip(DrinkType drink, {required bool isFavorite}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedDrink = drink),
      onLongPress: () => _toggleFavorite(drink.name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: drink.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFavorite
                ? Colors.amber.shade600.withValues(alpha: 0.6)
                : drink.color.withValues(alpha: 0.3),
            width: isFavorite ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(drink.icon, size: 18, color: drink.color),
            const SizedBox(width: 6),
            Text(
              drink.name,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              drink.healthTier.icon,
              size: 13,
              color: drink.healthTier.color,
            ),
            if (isFavorite) ...[
              const SizedBox(width: 3),
              Icon(Icons.star_rounded, size: 12, color: Colors.amber.shade600),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSlider() {
    final drink = _selectedDrink!;
    final waterOz = _amountOz * drink.waterRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Selected drink display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: drink.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(drink.icon, size: 32, color: drink.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(drink.name, style: AppTextStyles.labelLarge),
                      Row(
                        children: [
                          Text(
                            '${(drink.waterRatio * 100).toInt()}% hydration',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: drink.healthTier.color
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(drink.healthTier.icon,
                                    size: 11, color: drink.healthTier.color),
                                const SizedBox(width: 3),
                                Text(
                                  drink.healthTier.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: drink.healthTier.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDrink = null),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Amount display
          Text(
            '${_amountOz.toStringAsFixed(0)} oz',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.primary,
              fontSize: 48,
            ),
          ),
          Text(
            '→ ${waterOz.toStringAsFixed(1)} oz water equivalent',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Quick amount buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [4, 8, 12, 16, 20].map((oz) {
              final selected = _amountOz == oz.toDouble();
              return GestureDetector(
                onTap: () => setState(() => _amountOz = oz.toDouble()),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.primary : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${oz}oz',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 6,
            ),
            child: Slider(
              value: _amountOz,
              min: 1,
              max: AppConstants.maxDrinkOz,
              divisions: AppConstants.sliderDivisions,
              onChanged: (v) => setState(() => _amountOz = v),
            ),
          ),

          // Health disclaimer & wellness tip
          if (drink.hasDisclaimer)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: drink.healthTier.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: drink.healthTier.color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(drink.healthTier.icon,
                        size: 18, color: drink.healthTier.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        drink.disclaimerText ?? '',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Optional healthier swap (gentle, not pushy)
          if (drink.healthTier == HealthTier.limit)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () {
                  final swap = _healthierSwap(drink);
                  if (swap != null) setState(() => _selectedDrink = swap);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Or try ${_healthierSwap(drink)?.name ?? "water"} next time?',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),

          // Honest logging encouragement for all drinks
          if (drink.healthTier == HealthTier.fair ||
              drink.healthTier == HealthTier.limit)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Logging every drink gives you the most accurate picture of your hydration.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Log button — always positive
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onDrinkSelected(drink.name, _amountOz, drink.waterRatio);
                Navigator.pop(context);
              },
              child: Text(
                  'Log ${_amountOz.toStringAsFixed(0)} oz of ${drink.name}'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
