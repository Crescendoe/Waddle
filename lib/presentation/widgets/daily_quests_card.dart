import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/daily_quest.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart'
    as bloc;
import 'package:waddle/presentation/widgets/common.dart';

/// Collapsible daily quests widget — slim summary by default, expands to show
/// full quest list on tap.
class DailyQuestsCard extends StatefulWidget {
  const DailyQuestsCard({super.key});

  @override
  State<DailyQuestsCard> createState() => _DailyQuestsCardState();
}

class _DailyQuestsCardState extends State<DailyQuestsCard> {
  bool _expanded = false;

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
        final done = quests.where((q) => q.completed).length;
        final total = quests.length;
        final allDone = done == total;

        return GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Tappable summary row ──
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        allDone
                            ? Icons.check_circle_rounded
                            : Icons.task_alt_rounded,
                        color: allDone ? const Color(0xFF66BB6A) : tc.primary,
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
                        final isDone = i < done;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? const Color(0xFF66BB6A)
                                  : tc.primary.withValues(alpha: 0.20),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      Text(
                        '$done/$total',
                        style: TextStyle(
                          color: allDone
                              ? const Color(0xFF66BB6A)
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Expanded quest list ──
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Column(
                    children: quests
                        .map((qp) =>
                            _QuestRow(questProgress: qp, themeColor: tc))
                        .toList(),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestRow extends StatelessWidget {
  final DailyQuestProgress questProgress;
  final ActiveThemeColors themeColor;

  const _QuestRow({
    required this.questProgress,
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

    return GestureDetector(
      onTap: () => _showQuestDetail(context, tmpl, questProgress, themeColor),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isComplete
                    ? const Color(0xFF66BB6A).withValues(alpha: 0.15)
                    : themeColor.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isComplete ? Icons.check_rounded : tmpl.icon,
                size: 18,
                color:
                    isComplete ? const Color(0xFF66BB6A) : themeColor.primary,
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
                      color: isComplete
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      decoration:
                          isComplete ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor:
                          themeColor.primary.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isComplete
                            ? const Color(0xFF66BB6A)
                            : themeColor.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Progress text
            SizedBox(
              width: 48,
              child: Text(
                isComplete
                    ? '+${tmpl.xpReward} XP'
                    : '${questProgress.current}/${tmpl.target}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: isComplete
                      ? const Color(0xFF66BB6A)
                      : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showQuestDetail(
    BuildContext context,
    DailyQuestTemplate tmpl,
    DailyQuestProgress progress,
    ActiveThemeColors tc,
  ) {
    final isComplete = progress.completed;
    final progressFraction = tmpl.target > 0
        ? (progress.current / tmpl.target).clamp(0.0, 1.0)
        : 0.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isComplete
                    ? const Color(0xFF66BB6A).withValues(alpha: 0.15)
                    : tc.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isComplete ? Icons.check_rounded : tmpl.icon,
                size: 28,
                color: isComplete ? const Color(0xFF66BB6A) : tc.primary,
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              tmpl.title,
              style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            // Description
            Text(
              tmpl.description,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 8,
                backgroundColor: tc.primary.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? const Color(0xFF66BB6A) : tc.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isComplete
                  ? 'Completed!'
                  : '${progress.current} / ${tmpl.target}',
              style: TextStyle(
                color: isComplete
                    ? const Color(0xFF66BB6A)
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            // Rewards row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: tc.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: tc.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${tmpl.xpReward} XP',
                    style: TextStyle(
                      color: tc.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  Icon(Icons.water_drop, size: 16, color: tc.accent),
                  const SizedBox(width: 4),
                  Text(
                    '${tmpl.dropsReward} drops',
                    style: TextStyle(
                      color: tc.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
