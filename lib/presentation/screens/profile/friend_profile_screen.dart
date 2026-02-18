import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/friend_service.dart';
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
    final createdAt = s['createdAt'] as DateTime?;
    final memberSince =
        createdAt != null ? DateFormat('MMM yyyy').format(createdAt) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header card
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: _resolveImage(profileImage),
                  child: _resolveImage(profileImage) == null
                      ? Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  username,
                  style: AppTextStyles.headlineMedium,
                ),
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ],
                if (memberSince.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        'Joined $memberSince',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),
          const SizedBox(height: 16),

          // Stats grid
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '$username\'s Stats',
                      style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                  children: [
                    _statCard(
                      Icons.local_fire_department_rounded,
                      '${currentStreak}d',
                      'Current Streak',
                      AppColors.warning,
                    ),
                    _statCard(
                      Icons.emoji_events_rounded,
                      '${recordStreak}d',
                      'Best Streak',
                      AppColors.streakGold,
                    ),
                    _statCard(
                      Icons.water_drop_rounded,
                      _formatWater(totalWater),
                      'Total Water',
                      AppColors.water,
                    ),
                    _statCard(
                      Icons.flag_rounded,
                      '$totalGoalsMet',
                      'Goals Met',
                      AppColors.success,
                    ),
                    _statCard(
                      Icons.military_tech_rounded,
                      '$completedChallenges',
                      'Challenges',
                      AppColors.accentDark,
                    ),
                    _statCard(
                      Icons.checklist_rounded,
                      '$totalDaysLogged',
                      'Days Logged',
                      AppColors.primaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),

          // Remove friend button
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

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
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
