import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/challenge.dart';
import 'package:waddle/domain/entities/drink_type.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationBlocState>(
      builder: (context, state) {
        if (state is! HydrationLoaded) {
          return const Center(child: WaddleLoader());
        }

        final hydration = state.hydration;

        return GradientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Challenges', style: AppTextStyles.displaySmall)
                      .animate()
                      .fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    '${hydration.completedChallenges} of ${Challenges.all.length} completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),

                  // Active challenge card
                  if (hydration.hasActiveChallenge)
                    _buildActiveChallenge(context, hydration),

                  // Challenge grid
                  ...Challenges.all.asMap().entries.map((entry) {
                    final index = entry.key;
                    final challenge = entry.value;
                    final isActive =
                        hydration.activeChallengeIndex == challenge.index;
                    final isCompleted =
                        hydration.challengeActive[challenge.index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ChallengeCard(
                        challenge: challenge,
                        isActive: isActive,
                        isCompleted: isCompleted,
                        hasActiveChallenge: hydration.hasActiveChallenge,
                        onTap: () => _showChallengeDetail(
                          context,
                          challenge,
                          isActive,
                          isCompleted,
                          hydration.hasActiveChallenge,
                        ),
                      ),
                    ).animate().fadeIn(delay: (200 + index * 100).ms).slideX(
                          begin: 0.05,
                          end: 0,
                        );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveChallenge(BuildContext context, dynamic hydration) {
    final challenge = Challenges.getByIndex(hydration.activeChallengeIndex!);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: challenge.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  challenge.imagePath,
                  width: 40,
                  height: 40,
                  errorBuilder: (_, __, ___) => Icon(Icons.emoji_events_rounded,
                      size: 40, color: challenge.color),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Challenge',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                        )),
                    Text(challenge.title, style: AppTextStyles.labelLarge),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Days remaining bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${hydration.challengeDaysLeft} days left',
                  style: AppTextStyles.bodySmall),
              Text(
                  '${AppConstants.challengeDurationDays - hydration.challengeDaysLeft}/${AppConstants.challengeDurationDays}',
                  style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (AppConstants.challengeDurationDays -
                      hydration.challengeDaysLeft) /
                  AppConstants.challengeDurationDays,
              minHeight: 8,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(challenge.color),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _confirmGiveUp(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              child: const Text('Give Up Challenge'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.05);
  }

  void _confirmGiveUp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Give Up Challenge?'),
        content: const Text(
            'Your progress will be lost and you\'ll need to start over.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Going'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HydrationCubit>().giveUpChallenge();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Give Up'),
          ),
        ],
      ),
    );
  }

  void _showChallengeDetail(
    BuildContext context,
    Challenge challenge,
    bool isActive,
    bool isCompleted,
    bool hasActive,
  ) {
    final allowedDrinks = DrinkTypes.forChallenge(challenge.index);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Challenge header
              Row(
                children: [
                  Image.asset(
                    challenge.imagePath,
                    width: 64,
                    height: 64,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.emoji_events_rounded,
                        size: 64,
                        color: challenge.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(challenge.title,
                            style: AppTextStyles.headlineSmall),
                        Text(
                          '${challenge.durationDays} day challenge',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 18),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              Text(challenge.fullDescription, style: AppTextStyles.bodyMedium),
              const SizedBox(height: 16),

              Text('Rules', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Text(challenge.details, style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),

              // Health factoids
              Text('Did You Know?', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              ...challenge.healthFactoids.map((fact) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(
                            child: Text(fact, style: AppTextStyles.bodySmall)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // Allowed drinks
              Text('Allowed Drinks', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: allowedDrinks.map((d) {
                  return Chip(
                    avatar: Icon(d.icon, size: 16, color: d.color),
                    label: Text(d.name, style: const TextStyle(fontSize: 12)),
                    backgroundColor: d.color.withValues(alpha: 0.1),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action button
              if (!isCompleted && !isActive && !hasActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context
                          .read<HydrationCubit>()
                          .startChallenge(challenge.index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: challenge.color,
                    ),
                    child: const Text('Start Challenge'),
                  ),
                ),
              if (isCompleted)
                Center(
                  child: Text(
                    '✅ Challenge Completed!',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ),
              if (hasActive && !isActive)
                Center(
                  child: Text(
                    'Complete your current challenge first',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final bool isActive;
  final bool isCompleted;
  final bool hasActiveChallenge;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.isActive,
    required this.isCompleted,
    required this.hasActiveChallenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: challenge.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Image.asset(
                  challenge.imagePath,
                  width: 36,
                  height: 36,
                  errorBuilder: (_, __, ___) => Icon(Icons.emoji_events_rounded,
                      color: challenge.color, size: 28),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    challenge.shortDescription,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isCompleted)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24)
            else if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: challenge.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Active',
                  style: TextStyle(
                    color: challenge.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
