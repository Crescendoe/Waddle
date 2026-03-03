import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/friend_service.dart';
import 'package:waddle/domain/entities/duck_companion.dart';
import 'package:waddle/domain/entities/friend_entity.dart';
import 'package:waddle/domain/entities/hydration_state.dart' as hs;
import 'package:waddle/domain/entities/user_entity.dart';
import 'package:waddle/presentation/blocs/auth/auth_cubit.dart';
import 'package:waddle/presentation/blocs/auth/auth_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';
import 'package:waddle/presentation/widgets/duck_avatar.dart';
import 'package:waddle/core/utils/session_animation_tracker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey _shareCardKey = GlobalKey();
  late final FriendService _friendService;
  List<FriendEntity> _friends = [];
  List<FriendRequest> _pendingRequests = [];
  bool _loadingFriends = true;
  StreamSubscription? _friendsSub;
  StreamSubscription? _requestsSub;
  late final bool _animate =
      SessionAnimationTracker.shouldAnimate(SessionAnimationTracker.profile);

  @override
  void initState() {
    super.initState();
    _friendService = GetIt.instance<FriendService>();
    _loadSocialData();
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadSocialData() async {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    try {
      _friendsSub = _friendService.getFriends().listen(
        (friends) {
          if (mounted) setState(() => _friends = friends);
        },
        onError: (_) {},
      );
      _requestsSub = _friendService.getIncomingRequests().listen(
        (requests) {
          if (mounted) setState(() => _pendingRequests = requests);
        },
        onError: (_) {},
      );
    } catch (_) {}
    if (mounted) setState(() => _loadingFriends = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HydrationCubit, HydrationBlocState>(
      builder: (context, hydrationState) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is Authenticated ? authState.user : null;
            final hydration = hydrationState is HydrationLoaded
                ? hydrationState.hydration
                : null;

            return GradientBackground(
              child: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: Column(
                          children: [
                            RepaintBoundary(
                              key: _shareCardKey,
                              child: Column(
                                children: [
                                  _buildProfileHeader(user, hydration),
                                  const SizedBox(height: 14),
                                  if (hydration != null)
                                    _buildStatsGrid(hydration),
                                  const SizedBox(height: 14),
                                  if (hydration != null)
                                    _buildJourneyStrip(user, hydration),
                                ],
                              ),
                            ),
                            if (hydration != null) const SizedBox(height: 14),
                            _buildFriendsSection(),
                            if (_pendingRequests.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _buildPendingRequests(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PROFILE HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildProfileHeader(UserEntity? user, hs.HydrationState? hydration) {
    final streakTier = hydration?.streakTier ?? hs.StreakTier.normal;
    final memberSince = user?.createdAt != null
        ? DateFormat('MMM yyyy').format(user!.createdAt)
        : '';

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Avatar + Name / Bio / Meta ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _showImagePickerSheet(context),
                child: Stack(
                  children: [
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
                        backgroundImage: _resolveProfileImage(user),
                        child: _resolveProfileImage(user) == null
                            ? MascotImage(
                                assetPath: AppConstants.mascotWave,
                                size: 44,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: ActiveThemeColors.of(context).primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 10, color: Colors.white),
                      ),
                    ),
                    if (hydration?.activeDuckIndex != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: DuckAvatar.fromIndex(
                            index: hydration!.activeDuckIndex!,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Name + bio + meta — gets full remaining width
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username — full width, no badges competing
                    Text(
                      user?.username ?? 'Hydration Hero',
                      style: AppTextStyles.headlineSmall.copyWith(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        user.bio!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 5),
                    // Meta row
                    Row(
                      children: [
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
                        Icon(Icons.people_rounded,
                            size: 12, color: AppColors.textHint),
                        const SizedBox(width: 3),
                        Text(
                          '${_friends.length} friends',
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
          // ── Row 2: Badges + Actions strip ──
          Row(
            children: [
              // Level badge
              if (hydration != null)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ActiveThemeColors.of(context).primary,
                  ),
                  child: Center(
                    child: Text(
                      '${hydration.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              if (hydration != null) const SizedBox(width: 6),
              // Streak tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    Icon(streakTier.icon, size: 12, color: streakTier.color),
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
              // Supporter badge
              if (hydration?.isSubscribed == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite_rounded,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 3),
                      Text(
                        'Supporter',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Actions
              _compactActionChip(
                icon: Icons.edit_rounded,
                label: 'Edit',
                onTap: () => context.pushNamed('editProfile'),
              ),
              const SizedBox(width: 6),
              _compactActionChip(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () => _shareStats(context),
                filled: true,
              ),
              const SizedBox(width: 6),
              _compactIconButton(
                icon: Icons.settings_rounded,
                onTap: () => context.pushNamed('settings'),
              ),
            ],
          ),
        ],
      ),
    )
        .animateOnce(_animate)
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0);
  }

  // ═══════════════════════════════════════════════════════════════════
  // STATS GRID
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid(hs.HydrationState hydration) {
    final ducks = DuckCompanions.countUnlocked(
      currentStreak: hydration.currentStreak,
      recordStreak: hydration.recordStreak,
      completedChallenges: hydration.completedChallenges,
      totalWaterConsumed: hydration.totalWaterConsumedOz,
      totalDaysLogged: hydration.totalDaysLogged,
      totalHealthyPicks: hydration.totalHealthyPicks,
      totalGoalsMet: hydration.totalGoalsMet,
      totalDrinksLogged: hydration.totalDrinksLogged,
      uniqueDrinks: hydration.uniqueDrinksLogged.length,
      challengeActive: hydration.challengeActive,
    );

    final stats = [
      _StatData(
        icon: Icons.local_fire_department_rounded,
        value: '${hydration.currentStreak}',
        label: 'Current Streak',
        color: AppColors.warning,
      ),
      _StatData(
        icon: Icons.emoji_events_rounded,
        value: '${hydration.recordStreak}',
        label: 'Best Streak',
        color: AppColors.streakGold,
      ),
      _StatData(
        icon: Icons.water_drop_rounded,
        value: _formatWaterAmount(hydration.totalWaterConsumedOz),
        label: 'Total Water',
        color: AppColors.water,
      ),
      _StatData(
        icon: Icons.flag_rounded,
        value: '${hydration.totalGoalsMet}',
        label: 'Goals Met',
        color: AppColors.success,
      ),
      _StatData(
        icon: Icons.military_tech_rounded,
        value: '${hydration.completedChallenges}',
        label: 'Challenges Won',
        color: AppColors.accentDark,
      ),
      _StatData(
        icon: Icons.egg_rounded,
        value: '$ducks/${DuckCompanions.all.length}',
        label: 'Ducks',
        color: AppColors.duckLegendary,
      ),
      _StatData(
        icon: Icons.local_drink_rounded,
        value: '${hydration.uniqueDrinksLogged.length}',
        label: 'Drinks Tried',
        color: AppColors.primaryLight,
      ),
      _StatData(
        icon: Icons.bolt_rounded,
        value: '${hydration.totalXp}',
        label: 'Total XP',
        color: ActiveThemeColors.of(context).primary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatTile(stat)
            .animateOnce(_animate)
            .fadeIn(delay: (80 * index).ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1, 1),
              delay: (80 * index).ms,
            );
      },
    );
  }

  Widget _buildStatTile(_StatData stat) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stat.color.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: stat.color.withValues(alpha: 0.08),
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
              color: stat.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, size: 16, color: stat.color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.value,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: stat.color,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              stat.label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // JOURNEY STRIP
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildJourneyStrip(UserEntity? user, hs.HydrationState hydration) {
    final daysSinceJoined = user?.createdAt != null
        ? DateTime.now().difference(user!.createdAt).inDays
        : 0;
    final avgOzPerDay = hydration.totalDaysLogged > 0
        ? (hydration.totalWaterConsumedOz / hydration.totalDaysLogged)
        : 0.0;
    final avgCups = avgOzPerDay / 8;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ActiveThemeColors.of(context).primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _journeyItem(
            Icons.calendar_today_rounded,
            '$daysSinceJoined',
            'Days',
          ),
          _journeyDivider(),
          _journeyItem(
            Icons.show_chart_rounded,
            '${avgCups.toStringAsFixed(1)}',
            'Cups/day',
          ),
          _journeyDivider(),
          _journeyItem(
            Icons.checklist_rounded,
            '${hydration.totalDaysLogged}',
            'Days logged',
          ),
          _journeyDivider(),
          _journeyItem(
            Icons.local_drink_rounded,
            '${hydration.totalDrinksLogged}',
            'Drinks',
          ),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 300.ms);
  }

  Widget _journeyItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: ActiveThemeColors.of(context).primary),
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
      color: AppColors.divider.withValues(alpha: 0.5),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FRIENDS SECTION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFriendsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () => context.pushNamed('friends'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Icon(Icons.people_rounded,
                    size: 18, color: ActiveThemeColors.of(context).primary),
                const SizedBox(width: 8),
                Text(
                  'Friends',
                  style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
                ),
                if (_pendingRequests.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_pendingRequests.length}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'See All',
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 13),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: ActiveThemeColors.of(context).primary),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingFriends)
            const Padding(
              padding: EdgeInsets.all(20),
              child: WaddleLoader(size: 30),
            )
          else if (_friends.isEmpty)
            _buildEmptyFriends()
          else
            _buildFriendsRow(),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 200.ms);
  }

  Widget _buildEmptyFriends() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          MascotImage(assetPath: AppConstants.mascotSitting, size: 60),
          const SizedBox(height: 8),
          Text(
            'No friends yet',
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Find friends to see their progress!',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => context.pushNamed('friends'),
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Find Friends'),
              style: ElevatedButton.styleFrom(
                textStyle:
                    AppTextStyles.labelMedium.copyWith(color: Colors.white),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsRow() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _friends.length > 8 ? 9 : _friends.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          // "More" circle at the end
          if (index == 8 && _friends.length > 8) {
            return GestureDetector(
              onTap: () => context.pushNamed('friends'),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: ActiveThemeColors.of(context)
                        .primary
                        .withValues(alpha: 0.1),
                    child: Text(
                      '+${_friends.length - 8}',
                      style: AppTextStyles.labelLarge.copyWith(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text('More',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 9)),
                ],
              ),
            );
          }

          final friend = _friends[index];
          return GestureDetector(
            onTap: () => context.pushNamed('friendProfile', extra: friend.uid),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: ActiveThemeColors.of(context)
                      .primary
                      .withValues(alpha: 0.1),
                  backgroundImage: _resolveImage(friend.profileImageUrl),
                  child: _resolveImage(friend.profileImageUrl) == null
                      ? Text(
                          friend.username.isNotEmpty
                              ? friend.username[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: ActiveThemeColors.of(context).primary,
                            fontSize: 15,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: 48,
                  child: Text(
                    friend.username,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Mini streak indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 9, color: AppColors.warning),
                    Text(
                      '${friend.currentStreak}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 8,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PENDING FRIEND REQUESTS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPendingRequests() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add_rounded,
                  size: 18, color: ActiveThemeColors.of(context).primary),
              const SizedBox(width: 8),
              Text(
                'Friend Requests',
                style: AppTextStyles.headlineSmall.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._pendingRequests.take(3).map(
                (req) => _buildRequestTile(req),
              ),
          if (_pendingRequests.length > 3)
            TextButton(
              onPressed: () => context.pushNamed('friends'),
              child: Text('See all ${_pendingRequests.length} requests'),
            ),
        ],
      ),
    ).animateOnce(_animate).fadeIn(delay: 300.ms);
  }

  Widget _buildRequestTile(FriendRequest request) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                ActiveThemeColors.of(context).primary.withValues(alpha: 0.1),
            backgroundImage: _resolveImage(request.fromProfileImageUrl),
            child: _resolveImage(request.fromProfileImageUrl) == null
                ? Text(
                    request.fromUsername.isNotEmpty
                        ? request.fromUsername[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelLarge,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUsername,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Wants to be your friend',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          // Accept
          IconButton(
            onPressed: () async {
              try {
                await _friendService.acceptFriendRequest(request.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${request.fromUsername} added as friend!'),
                      backgroundColor: AppColors.success,
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
            icon: const Icon(Icons.check_circle_rounded),
            color: AppColors.success,
            iconSize: 28,
          ),
          // Decline
          IconButton(
            onPressed: () async {
              await _friendService.declineFriendRequest(request.id);
            },
            icon: const Icon(Icons.cancel_rounded),
            color: AppColors.textHint,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // COMPACT BUTTON WIDGETS
  // ═══════════════════════════════════════════════════════════════════
  Widget _compactActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    final tc = ActiveThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? tc.primary : tc.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: filled
              ? null
              : Border.all(color: tc.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: filled ? Colors.white : tc.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : tc.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final tc = ActiveThemeColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: tc.primary.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: tc.primary.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, size: 16, color: tc.primary),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SHARE STATS
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _shareStats(BuildContext context) async {
    try {
      final boundary = _shareCardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _shareTextStats(context);
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _shareTextStats(context);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/waddle_stats.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Check out my hydration stats on ${AppConstants.appName}! \u{1F4A7}\u{1F986}',
      );
    } catch (_) {
      _shareTextStats(context);
    }
  }

  void _shareTextStats(BuildContext context) {
    final hydState = context.read<HydrationCubit>().state;
    if (hydState is! HydrationLoaded) return;

    final h = hydState.hydration;
    final text = '\u{1F4A7} My ${AppConstants.appName} Stats \u{1F986}\n\n'
        '\u{1F525} Current Streak: ${h.currentStreak} days\n'
        '\u{1F3C6} Best Streak: ${h.recordStreak} days\n'
        '\u{1F4A7} Total Water: ${_formatWaterAmount(h.totalWaterConsumedOz)}\n'
        '\u{1F3AF} Goals Met: ${h.totalGoalsMet}\n'
        '\u{2694}\u{FE0F} Challenges Won: ${h.completedChallenges}\n'
        '\u{2764}\u{FE0F} Healthy Picks: ${h.totalHealthyPicks}\n\n'
        'Track your hydration with Waddle!';

    Share.share(text);
  }

  // ═══════════════════════════════════════════════════════════════════
  // IMAGE HELPERS
  // ═══════════════════════════════════════════════════════════════════
  ImageProvider? _resolveProfileImage(UserEntity? user) {
    return _resolveImage(user?.profileImageUrl);
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

  void _showImagePickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('Change Profile Photo', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded,
                  color: ActiveThemeColors.of(context).primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded,
                  color: ActiveThemeColors.of(context).primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(context, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppColors.error),
              title: const Text('Remove Photo'),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthCubit>().updateProfile(profileImageUrl: '');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );
      if (picked == null) return;

      final bytes = await File(picked.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Str';

      if (context.mounted) {
        context.read<AuthCubit>().updateProfile(profileImageUrl: dataUri);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // FORMAT HELPERS
  // ═══════════════════════════════════════════════════════════════════
  String _formatWaterAmount(double oz) {
    if (oz >= 1000) {
      return '${(oz / 128).toStringAsFixed(1)}gal';
    }
    return '${oz.toInt()}oz';
  }
}

// ─── Helper data class ──────────────────────────────────────────────
class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}
