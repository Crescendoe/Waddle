import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/usecases/water_goal_calculator.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/widgets/common.dart';

class QuestionsScreen extends StatefulWidget {
  final bool recalculate;

  const QuestionsScreen({super.key, this.recalculate = false});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _pageController = PageController();

  // Wheel controllers for height & weight
  late final FixedExtentScrollController _feetWheelController;
  late final FixedExtentScrollController _inchesWheelController;
  late final FixedExtentScrollController _weightWheelController;

  // Wheel animation
  late AnimationController _scaleAnimController;
  late Animation<double> _scaleAnim;

  // Current values from wheels
  double _heightFeet = 5;
  double _heightInches = 9;
  double _weightLbs = 165;

  Sex _selectedSex = Sex.male;
  ActivityLevel _selectedActivity = ActivityLevel.sedentary;
  WeatherCondition _selectedWeather = WeatherCondition.mild;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // feet range: 3-7 (index 0-4), default 5 → index 2
    _feetWheelController = FixedExtentScrollController(initialItem: 2);
    // inches range: 0-11, default 9
    _inchesWheelController = FixedExtentScrollController(initialItem: 9);
    // weight range: 60-400 (index 0-340), default 165 → index 105
    _weightWheelController = FixedExtentScrollController(initialItem: 105);

    _scaleAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleAnimController, curve: Curves.elasticOut),
    );
    _scaleAnimController.forward();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _pageController.dispose();
    _feetWheelController.dispose();
    _inchesWheelController.dispose();
    _weightWheelController.dispose();
    _scaleAnimController.dispose();
    super.dispose();
  }

  void _calculateAndSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final age = int.parse(_ageController.text);
    final feet = _heightFeet.toInt();
    final inches = _heightInches.toInt();
    final weight = _weightLbs;
    final heightInches = (feet * 12) + inches;

    final goalOz = WaterGoalCalculator.calculate(
      weightLbs: weight,
      ageYears: age,
      heightInches: heightInches,
      sex: _selectedSex,
      activity: _selectedActivity,
      weather: _selectedWeather,
    );

    context.read<HydrationCubit>().setWaterGoal(goalOz);
    if (widget.recalculate) {
      context
          .pushNamed('results', extra: {'goalOz': goalOz, 'recalculate': true});
    } else {
      context
          .goNamed('results', extra: {'goalOz': goalOz, 'recalculate': false});
    }
  }

  void _useDefault() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Use Default Goal?', style: AppTextStyles.headlineSmall),
        content: Text(
          'We\'ll set your daily goal to ${AppConstants.defaultWaterGoalOz.toInt()} oz '
          '(${(AppConstants.defaultWaterGoalOz / 8).toStringAsFixed(0)} cups). '
          'You can always change this later.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<HydrationCubit>()
                  .setWaterGoal(AppConstants.defaultWaterGoalOz);
              if (widget.recalculate) {
                context.pushNamed('results', extra: {
                  'goalOz': AppConstants.defaultWaterGoalOz,
                  'recalculate': true
                });
              } else {
                context.goNamed('results', extra: {
                  'goalOz': AppConstants.defaultWaterGoalOz,
                  'recalculate': false
                });
              }
            },
            child: const Text('Use Default'),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _calculateAndSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () {
                              if (_currentPage > 0) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                );
                              } else {
                                context.pop();
                              }
                            },
                            color: AppColors.primary,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _useDefault,
                            child:
                                Text('Skip', style: AppTextStyles.labelLarge),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Calculate Your Goal',
                        style: AppTextStyles.displaySmall,
                      ).animate().fadeIn(),
                      const SizedBox(height: 8),

                      // Progress indicator
                      Row(
                        children: List.generate(3, (index) {
                          return Expanded(
                            child: Container(
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: index <= _currentPage
                                    ? AppColors.primary
                                    : AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (page) =>
                        setState(() => _currentPage = page),
                    children: [
                      _buildBodyPage(),
                      _buildLifestylePage(),
                      _buildEnvironmentPage(),
                    ],
                  ),
                ),

                // Next button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(_currentPage < 2 ? 'Next' : 'Calculate'),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          GlassCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('About You', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.cake_rounded),
                    suffixText: 'years',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    final age = int.tryParse(value);
                    if (age == null || age < 3 || age > 100) {
                      return 'Enter age between 3-100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Sex', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: Sex.values.map((sex) {
                    final selected = _selectedSex == sex;
                    return ChoiceChip(
                      label: Text(sex.label),
                      selected: selected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      onSelected: (_) => setState(() => _selectedSex = sex),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Height wheel picker card
          _buildHeightCard(),
          const SizedBox(height: 14),

          // Weight wheel picker card
          _buildWeightCard(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeightCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.height_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Height',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Display value
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.12),
                      AppColors.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_heightFeet.toInt()}′${_heightInches.toInt()}″',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatHeightCm(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Wheel pickers row
          SizedBox(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: _buildWheelPicker(
                    label: 'Feet',
                    controller: _feetWheelController,
                    itemCount: 5, // 3-7
                    itemBuilder: (i) => '${i + 3}',
                    onChanged: (i) {
                      setState(() => _heightFeet = (i + 3).toDouble());
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildWheelPicker(
                    label: 'Inches',
                    controller: _inchesWheelController,
                    itemCount: 12, // 0-11
                    itemBuilder: (i) => '$i',
                    onChanged: (i) {
                      setState(() => _heightInches = i.toDouble());
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildWeightCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.monitor_weight_rounded,
                    color: AppColors.accentDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Weight',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Display value
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.12),
                      AppColors.primary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_weightLbs.toInt()}',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: AppColors.accentDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'lbs',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatWeightKg(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Wheel picker
          SizedBox(
            height: 120,
            child: _buildWheelPicker(
              label: 'Pounds',
              controller: _weightWheelController,
              itemCount: 341, // 60-400
              itemBuilder: (i) => '${i + 60}',
              onChanged: (i) {
                setState(() => _weightLbs = (i + 60).toDouble());
                HapticFeedback.selectionClick();
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildWheelPicker({
    required String label,
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) itemBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Stack(
            children: [
              // Selection highlight bar
              Positioned.fill(
                child: Center(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ),
              // Wheel
              ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.white,
                      Colors.white,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.2, 0.8, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ListWheelScrollView.useDelegate(
                  controller: controller,
                  itemExtent: 42,
                  perspective: 0.003,
                  diameterRatio: 1.4,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: onChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: itemCount,
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          itemBuilder(index),
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatHeightCm() {
    final totalInches = (_heightFeet * 12) + _heightInches;
    return '${(totalInches * 2.54).toStringAsFixed(0)} cm';
  }

  String _formatWeightKg() {
    return '${(_weightLbs * 0.453592).toStringAsFixed(1)} kg';
  }

  Widget _buildLifestylePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Level', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            ...ActivityLevel.values.map((level) {
              final selected = _selectedActivity == level;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedActivity = level),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color:
                              selected ? AppColors.primary : AppColors.textHint,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(level.label,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  )),
                              Text(level.description,
                                  style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Climate', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Warmer climates require more hydration',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 20),
            ...WeatherCondition.values.map((weather) {
              final selected = _selectedWeather == weather;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedWeather = weather),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(weather.emoji,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Text(
                          weather.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
