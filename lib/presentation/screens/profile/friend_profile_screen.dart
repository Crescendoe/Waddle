import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/friend_service.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/domain/entities/hydration_state.dart';
import 'package:waddle/domain/entities/xp_level.dart';
import 'package:waddle/presentation/widgets/common.dart';

class FriendProfileScreen extends StatefulWidget {
  final String friendUid;
  const FriendProfileScreen({super.key, required this.friendUid});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late final FriendService _friendService;
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _friendService = GetIt.instance<FriendService>();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final stats = await _friendService.getFriendPublicStats(widget.friendUid);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loading = false;
          if (stats == null) _error = 'Profile is private or not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load profile';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            _stats?['username'] as String? ?? 'Profile',
            style: AppTextStyles.headlineSmall,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: WaddleLoader())
              : _error != null
                  ? _buildError()
                  : _buildProfile(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(_error!, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final s = _stats!;
    final username = s['username'] as String? ?? 'User';
    final bio = s['bio'] as String?;
    final profileImage = s['profileImage'] as String?;
    final currentStreak = s['currentStreak'] as int? ?? 0;
    final recordStreak = s['recordStreak'] as int? ?? 0;
    final totalWater = (s['totalWaterConsumed'] as num?)?.toDouble() ?? 0.0;
    final totalGoalsMet = s['totalGoalsMet'] as int? ?? 0;
    final totalDaysLogged = s['totalDaysLogged'] as int? ?? 0;
    final completedChallenges = s['completedChallenges'] as int? ?? 0;
    final totalDrinksLogged = s['totalDrinksLogged'] as int? ?? 0;
    final uniqueDrinks = s['uniqueDrinksLogged'] as List? ?? [];
    final waterGoal = (s['waterGoal'] as num?)?.toDouble() ?? 80.0;
    final friendCount = s['friendCount'] as int? ?? 0;
    final createdAt = s['createdAt'] as DateTime?;
    final totalXp = s['totalXp'] as int? ?? 0;
    final level = XpLevel.levelForXp(totalXp);
    final streakTier = _streakTierFor(currentStreak);
    final memberSince =
        createdAt != null ? DateFormat('MMM yyyy').format(createdAt) : '';

    // Computed stats
    final daysSinceJoined =
        createdAt != null ? DateTime.now().difference(createdAt).inDays : 0;
    final avgOzPerDay =
        totalDaysLogged > 0 ? (totalWater / totalDaysLogged) : 0.0;
    final avgCups = avgOzPerDay / 8;
    final challengeActive = List<bool>.generate(
      6,
      (i) => s['challenge${i + 1}Active'] as bool? ?? false,
    );
    final ducks = DuckCompanions.countUnlocked(
      currentStreak: currentStreak,
      recordStreak: recordStreak,
      completedChallenges: completedChallenges,
      totalWaterConsumed: totalWater,
      totalDaysLogged: totalDaysLogged,
      totalHealthyPicks: s['totalHealthyPicks'] as int? ?? 0,
      totalGoalsMet: totalGoalsMet,
      totalDrinksLogged: totalDrinksLogged,
      uniqueDrinks: (s['uniqueDrinksLogged'] as List<dynamic>?)?.length ?? 0,
      challengeActive: challengeActive,
    );
    final goalHitRate = totalDaysLogged > 0
        ? ((totalGoalsMet / totalDaysLogged) * 100).toStringAsFixed(0)
        : '0';
    final avgDrinksPerDay = totalDaysLogged > 0
        ? (totalDrinksLogged / totalDaysLogged).toStringAsFixed(1)
        : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Header card (matches own profile layout) ──
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Avatar + Name / Bio / Meta
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: streakTier.color.withValues(alpha: 0.6),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: streakTier.color.withValues(alpha: 0.25),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: ActiveThemeColors.of(context)
                            .primary
                            .withValues(alpha: 0.1),
                        backgroundImage: _resolveImage(profileImage),
                        child: _resolveImage(profileImage) == null
                            ? Text(
                                username.isNotEmpty
                                    ? username[0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.displaySmall.copyWith(
                                  color: ActiveThemeColors.of(context).primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + bio + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: AppTextStyles.headlineSmall
                                .copyWith(fontSize: 20),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (bio != null && bio.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              bio,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (memberSince.isNotEmpty) ...[
                                Icon(Icons.calendar_today_rounded,
                                    size: 12, color: AppColors.textHint),
                                const SizedBox(width: 3),
                                Text(
                                  memberSince,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textHint,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Icon(Icons.people_rounded,
                                  size: 12, color: AppColors.textHint),
                              const SizedBox(width: 3),
                              Text(
                                '$friendCount friends',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 2: Badges
                Row(
                  children: [
                    // Level badge
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ActiveThemeColors.of(context).primary,
                      ),
                      child: Center(
                        child: Text(
                          '$level',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Streak tier badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: streakTier.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: streakTier.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(streakTier.icon,
                              size: 12, color: streakTier.color),
                          const SizedBox(width: 3),
                          Text(
                            streakTier.label,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: streakTier.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: 12),

          // ── Stats grid (matches user's own profile) ──
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
            children: [
              _statTile(Icons.local_fire_department_rounded, '$currentStreak',
                  'Current Streak', AppColors.warning),
              _statTile(Icons.emoji_events_rounded, '$recordStreak',
                  'Best Streak', AppColors.streakGold),
              _statTile(Icons.water_drop_rounded, _formatWater(totalWater),
                  'Total Water', AppColors.water),
              _statTile(Icons.flag_rounded, '$totalGoalsMet', 'Goals Met',
                  AppColors.success),
              _statTile(Icons.military_tech_rounded, '$completedChallenges',
                  'Challenges Won', AppColors.accentDark),
              _statTile(
                  Icons.egg_rounded,
                  '$ducks/${DuckCompanions.all.length}',
                  'Ducks',
                  AppColors.duckLegendary),
              _statTile(Icons.local_drink_rounded, '${uniqueDrinks.length}',
                  'Drinks Tried', AppColors.primaryLight),
              _statTile(Icons.bolt_rounded, '$totalXp', 'Total XP',
                  ActiveThemeColors.of(context).primary),
            ],
          ),
          const SizedBox(height: 12),

          // ── Journey strip (matches user's own profile) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _journeyItem(
                    Icons.calendar_today_rounded, '$daysSinceJoined', 'Days'),
                _journeyDivider(),
                _journeyItem(Icons.show_chart_rounded,
                    avgCups.toStringAsFixed(1), 'Cups/day'),
                _journeyDivider(),
                _journeyItem(
                    Icons.checklist_rounded, '$totalDaysLogged', 'Days logged'),
                _journeyDivider(),
                _journeyItem(
                    Icons.local_drink_rounded, '$totalDrinksLogged', 'Drinks'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Fun facts card ──
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      'Fun Facts',
                      style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _funFactRow(
                  Icons.opacity_rounded,
                  'Fills ${(totalWater / 128).toStringAsFixed(1)} gallons total',
                  AppColors.water,
                ),
                _funFactRow(
                  Icons.pool_rounded,
                  totalWater >= 640000
                      ? 'Could fill an Olympic pool!'
                      : 'That\'s ${(totalWater / 640000 * 100).toStringAsFixed(4)}% of an Olympic pool',
                  AppColors.primaryLight,
                ),
                _funFactRow(
                  Icons.percent_rounded,
                  '$goalHitRate% goal hit rate',
                  AppColors.success,
                ),
                _funFactRow(
                  Icons.speed_rounded,
                  '$avgDrinksPerDay drinks per day on average',
                  AppColors.accent,
                ),
                _funFactRow(
                  Icons.gps_fixed_rounded,
                  'Daily goal: ${waterGoal.toStringAsFixed(0)} oz (${(waterGoal / 8).toStringAsFixed(1)} cups)',
                  AppColors.primary,
                ),
                if (uniqueDrinks.isNotEmpty)
                  _funFactRow(
                    Icons.explore_rounded,
                    'Tried ${uniqueDrinks.length} different drink${uniqueDrinks.length == 1 ? '' : 's'}',
                    AppColors.accentDark,
                  ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),

          // ── Remove friend button ──
          GlassCard(
            padding: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.person_remove_rounded,
                  color: AppColors.error),
              title: Text(
                'Remove Friend',
                style:
                    AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              ),
              onTap: () => _confirmRemove(username),
            ),
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _statTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 9,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _journeyItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 9,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _journeyDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.primary.withValues(alpha: 0.15),
    );
  }

  Widget _funFactRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove $username as a friend?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _friendService.removeFriend(widget.friendUid);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$username removed'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatWater(double oz) {
    if (oz >= 1000) return '${(oz / 128).toStringAsFixed(1)}gal';
    return '${oz.toInt()}oz';
  }

  StreakTier _streakTierFor(int streak) {
    if (streak >= 30) return StreakTier.platinum;
    if (streak >= 20) return StreakTier.gold;
    if (streak >= 15) return StreakTier.silver;
    if (streak >= 10) return StreakTier.bronze;
    return StreakTier.normal;
  }

  ImageProvider? _resolveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return MemoryImage(base64Decode(base64Str));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }
}
