import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/daily_quest.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart'
    as bloc;
import 'package:waddle/presentation/widgets/common.dart';

/// Daily quests section — shows all quests directly (no dropdown).
/// Completed-but-unclaimed quests show a "Claim" button.
class DailyQuestsCard extends StatefulWidget {
  const DailyQuestsCard({super.key});

  @override
  State<DailyQuestsCard> createState() => _DailyQuestsCardState();
}

class _DailyQuestsCardState extends State<DailyQuestsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HydrationCubit>().refreshDailyQuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HydrationCubit, bloc.HydrationBlocState,
        HydrationState?>(
      selector: (state) =>
          state is bloc.HydrationLoaded ? state.hydration : null,
      builder: (context, hydration) {
        if (hydration == null) return const SizedBox.shrink();

        final quests = hydration.dailyQuests;
        if (quests.isEmpty) return const SizedBox.shrink();

        final tc = ActiveThemeColors.of(context);
        final claimed = quests.where((q) => q.claimed).length;
        final total = quests.length;
        final allClaimed = claimed == total;

        return GlassCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  children: [
                    Icon(
                      allClaimed
                          ? Icons.check_circle_rounded
                          : Icons.task_alt_rounded,
                      color: allClaimed ? const Color(0xFF66BB6A) : tc.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Quests',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Completion dots
                    ...List.generate(total, (i) {
                      final isClaimed = quests[i].claimed;
                      final isDone = quests[i].completed;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isClaimed
                                ? const Color(0xFF66BB6A)
                                : isDone
                                    ? const Color(0xFFFFA726)
                                    : tc.primary.withValues(alpha: 0.20),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    Text(
                      '$claimed/$total',
                      style: TextStyle(
                        color: allClaimed
                            ? const Color(0xFF66BB6A)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Quest list (always visible) ──
                ...quests.asMap().entries.map((entry) {
                  return _QuestRow(
                    questProgress: entry.value,
                    questIndex: entry.key,
                    themeColor: tc,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuestRow extends StatelessWidget {
  final DailyQuestProgress questProgress;
  final int questIndex;
  final ActiveThemeColors themeColor;

  const _QuestRow({
    required this.questProgress,
    required this.questIndex,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final tmpl = DailyQuests.byId(questProgress.questId);
    if (tmpl == null) return const SizedBox.shrink();

    final progress = tmpl.target > 0
        ? (questProgress.current / tmpl.target).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = questProgress.completed;
    final isClaimed = questProgress.claimed;
    final isClaimable = isComplete && !isClaimed;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isClaimed
                  ? const Color(0xFF66BB6A).withValues(alpha: 0.15)
                  : isClaimable
                      ? const Color(0xFFFFA726).withValues(alpha: 0.15)
                      : themeColor.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isClaimed
                  ? Icons.check_rounded
                  : isClaimable
                      ? Icons.card_giftcard_rounded
                      : tmpl.icon,
              size: 18,
              color: isClaimed
                  ? const Color(0xFF66BB6A)
                  : isClaimable
                      ? const Color(0xFFFFA726)
                      : themeColor.primary,
            ),
          ),
          const SizedBox(width: 10),
          // Text + progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tmpl.title,
                  style: TextStyle(
                    color: isClaimed
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: themeColor.primary.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isClaimed
                          ? const Color(0xFF66BB6A)
                          : isClaimable
                              ? const Color(0xFFFFA726)
                              : themeColor.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Claim button or status
          if (isClaimable)
            _ClaimButton(
              questIndex: questIndex,
              xpReward: tmpl.xpReward,
              dropsReward: tmpl.dropsReward,
            )
          else if (isClaimed)
            SizedBox(
              width: 52,
              child: Text(
                '+${tmpl.xpReward} XP',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF66BB6A),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            SizedBox(
              width: 52,
              child: Text(
                '${questProgress.current}/${tmpl.target}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  final int questIndex;
  final int xpReward;
  final int dropsReward;

  const _ClaimButton({
    required this.questIndex,
    required this.xpReward,
    required this.dropsReward,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final cubit = context.read<HydrationCubit>();
        final success = await cubit.claimQuest(questIndex);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Claimed +$xpReward XP & +$dropsReward drops!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF66BB6A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFF9800)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA726).withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'Claim',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
