import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/challenge.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/widgets/common.dart';

class ChallengeFailedScreen extends StatelessWidget {
  final int challengeIndex;

  const ChallengeFailedScreen({super.key, required this.challengeIndex});

  Challenge get challenge => Challenges.getByIndex(challengeIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: [
          challenge.color.withValues(alpha: 0.08),
          const Color(0xFFFFF8F6),
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),

                // Mascot sitting / looking sorry
                MascotImage(
                  assetPath: AppConstants.mascotSitting,
                  size: 120,
                ).animate().scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 28),

                // "Challenge Ended" title
                Text(
                  'Challenge Ended',
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 32,
                    color: AppColors.warning,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 8),

                Text(
                  challenge.title,
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: challenge.color,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 24),

                // Empathy card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'It\'s okay — every journey has bumps.',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You took the challenge on and that takes courage. '
                        'What matters is that you\'re building healthier habits, '
                        'one day at a time. You can always try again!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                const SizedBox(height: 16),

                // Motivational stat
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: challenge.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: challenge.color.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay_rounded,
                          color: challenge.color, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        'Every attempt makes you stronger',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: challenge.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1000.ms),

                const Spacer(),

                // Try Again button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final cubit = context.read<HydrationCubit>();
                      cubit.acknowledgeChallengeResult();
                      context.pop();
                      // Start the same challenge again
                      cubit.startChallenge(challengeIndex);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: challenge.color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms),
                const SizedBox(height: 10),

                // Maybe Later
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context
                          .read<HydrationCubit>()
                          .acknowledgeChallengeResult();
                      context.pop();
                    },
                    child: Text(
                      'Maybe Later',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
