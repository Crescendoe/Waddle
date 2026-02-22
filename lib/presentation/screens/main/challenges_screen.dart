import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/core/utils/session_animation_tracker.dart';
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
        final _animate = SessionAnimationTracker.shouldAnimate(
            SessionAnimationTracker.challenges);

        return GradientBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Challenges', style: AppTextStyles.displaySmall)
                      .animateOnce(_animate)
                      .fadeIn(),
                  const SizedBox(height: 8),
                  Text(
                    '${hydration.completedChallenges} of ${Challenges.all.length} completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ).animateOnce(_animate).fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),

                  // Active challenge card
                  if (hydration.hasActiveChallenge)
                    _buildActiveChallenge(context, hydration, _animate),

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
                    )
                        .animateOnce(_animate)
                        .fadeIn(delay: (200 + index * 100).ms)
                        .slideX(
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

  Widget _buildActiveChallenge(
      BuildContext context, dynamic hydration, bool _animate) {
    final challenge = Challenges.getByIndex(hydration.activeChallengeIndex!);
    final progress =
        (AppConstants.challengeDurationDays - hydration.challengeDaysLeft) /
            AppConstants.challengeDurationDays;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Challenge mascot art
              Image.asset(
                challenge.imagePath,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.emoji_events_rounded,
                    size: 40, color: challenge.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: challenge.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: challenge.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              Text(
                  '${AppConstants.challengeDurationDays - hydration.challengeDaysLeft}/${AppConstants.challengeDurationDays}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  ActiveThemeColors.of(context).primary.withValues(alpha: 0.1),
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
    ).animateOnce(_animate).fadeIn(delay: 100.ms).slideY(begin: -0.05);
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
    final restrictedDrinks = DrinkTypes.restrictedForChallenge(challenge.index);

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

              // ── Challenge hero header with large art ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      challenge.color.withValues(alpha: 0.12),
                      challenge.color.withValues(alpha: 0.04),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: challenge.color.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    // Large challenge mascot art
                    Image.asset(
                      challenge.imagePath,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.emoji_events_rounded,
                        size: 64,
                        color: challenge.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      challenge.title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: challenge.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${challenge.durationDays} day challenge',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
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
              const SizedBox(height: 20),

              // ── Restricted drinks (prominent — what you CAN'T drink) ──
              if (restrictedDrinks.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFCDD2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.block_rounded,
                              color: Color(0xFFE53935), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Off Limits',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: const Color(0xFFE53935),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: restrictedDrinks.map((d) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFEF9A9A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(d.icon,
                                    size: 14, color: const Color(0xFFE53935)),
                                const SizedBox(width: 4),
                                Text(
                                  d.name,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFFE53935),
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: const Color(0xFFE53935),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Allowed drinks ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFC8E6C9),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: Color(0xFF43A047), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Allowed Drinks',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: const Color(0xFF43A047),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allowedDrinks.map((d) {
                        return Chip(
                          avatar: Icon(d.icon, size: 16, color: d.color),
                          label: Text(d.name,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: d.color.withValues(alpha: 0.1),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
    final locked = hasActiveChallenge && !isActive && !isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: challenge.color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.none,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                challenge.color.withValues(alpha: 0.14),
                challenge.color.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: Row(
            children: [
              // Large Wade image
              Image.asset(
                challenge.imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.emoji_events_rounded,
                    color: challenge.color, size: 40),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status pill
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: challenge.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      )
                    else if (isCompleted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded,
                                size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              'COMPLETED',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      challenge.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Description + action on same row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.shortDescription,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: locked
                                ? AppColors.textHint.withValues(alpha: 0.1)
                                : challenge.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isCompleted
                                ? '✅'
                                : isActive
                                    ? 'View'
                                    : locked
                                        ? '🔒'
                                        : 'Start',
                            style: TextStyle(
                              color:
                                  locked ? AppColors.textHint : challenge.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
