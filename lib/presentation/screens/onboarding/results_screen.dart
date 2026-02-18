import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/presentation/widgets/water_cup.dart';

class ResultsScreen extends StatelessWidget {
  final double goalOz;
  final bool recalculate;

  const ResultsScreen(
      {super.key, required this.goalOz, this.recalculate = false});

  @override
  Widget build(BuildContext context) {
    final cups = (goalOz / AppConstants.ozPerCup).ceil();
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Duck mascot
                MascotImage(
                  assetPath: AppConstants.mascotWave,
                  size: 140,
                ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 24),

                Text(
                  'Your Daily Goal',
                  style: AppTextStyles.displaySmall,
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 24),

                // Animated water cup preview
                AnimatedWaterCup(
                  currentOz: goalOz,
                  goalOz: goalOz,
                  size: 140,
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Goal number
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${goalOz.toInt()}',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 56,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('oz',
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: AppColors.primary)),
                        Text('$cups cups', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 16),
                Text(
                  'Based on your body metrics and lifestyle',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 900.ms),

                const Spacer(),

                // Tip card
                GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded,
                          color: AppColors.accent, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tip: Drink a glass of water first thing in the morning to kickstart hydration!',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (recalculate) {
                        // Pop back through results → questions → settings
                        Navigator.of(context)
                          ..pop()
                          ..pop();
                      } else {
                        context.goNamed('home');
                      }
                    },
                    child:
                        Text(recalculate ? 'Done' : 'Let\'s Start Hydrating!'),
                  ),
                ).animate().fadeIn(delay: 1300.ms),

                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Recalculate'),
                ).animate().fadeIn(delay: 1400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
