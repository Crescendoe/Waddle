import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/challenge.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/widgets/common.dart';

/// Empathy-focused bottom sheet shown when a challenge fails.
class ChallengeFailureSheet extends StatelessWidget {
  final int challengeIndex;

  const ChallengeFailureSheet({super.key, required this.challengeIndex});

  Challenge get challenge => Challenges.getByIndex(challengeIndex);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Mascot looking sorry
          MascotImage(
            assetPath: AppConstants.mascotSitting,
            size: 100,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),

          Text(
            'Challenge Ended',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),

          Text(
            challenge.title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: challenge.color,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),

          // Empathy message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'It\'s okay — every journey has bumps.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'You took the challenge on and that takes courage. '
                  'What matters is that you\'re building healthier habits, '
                  'one day at a time. You can always try again!',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),

          // Try Again button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final cubit = context.read<HydrationCubit>();
                cubit.acknowledgeChallengeResult();
                Navigator.pop(context);
                // Start the same challenge again
                cubit.startChallenge(challengeIndex);
              },
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: challenge.color,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 10),

          // Dismiss
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                context.read<HydrationCubit>().acknowledgeChallengeResult();
                Navigator.pop(context);
              },
              child: Text(
                'Maybe Later',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 700.ms),
        ],
      ),
    );
  }
}
