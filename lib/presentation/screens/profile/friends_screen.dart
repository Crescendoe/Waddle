import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/friend_service.dart';
import 'package:waddle/domain/entities/friend_entity.dart';
import 'package:waddle/presentation/widgets/common.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final FriendService _friendService;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<FriendEntity> _friends = [];
  List<FriendRequest> _requests = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  bool _loadingResults = false;
  StreamSubscription? _friendsSub;
  StreamSubscription? _requestsSub;

  // Track which users already have pending requests from us
  final Set<String> _sentRequests = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _friendService = GetIt.instance<FriendService>();
    _loadData();
  }

  void _loadData() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    _friendsSub = _friendService.getFriends().listen(
      (friends) {
        if (mounted) setState(() => _friends = friends);
      },
      onError: (_) {},
    );
    _requestsSub = _friendService.getIncomingRequests().listen(
      (requests) {
        if (mounted) setState(() => _requests = requests);
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _requestsSub?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _loadingResults = true);
    try {
      final results = await _friendService.searchUsers(query);
      // Filter out existing friends
      final friendUids = _friends.map((f) => f.uid).toSet();
      final filtered =
          results.where((r) => !friendUids.contains(r['uid'])).toList();
      if (mounted) {
        setState(() {
          _searchResults = filtered;
          _loadingResults = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingResults = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Friends', style: AppTextStyles.headlineSmall),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.primary,
            labelStyle:
                AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text('Friends (${_friends.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_rounded, size: 16),
                    const SizedBox(width: 4),
                    Text('Requests'),
                    if (_requests.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_requests.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_rounded, size: 16),
                    SizedBox(width: 4),
                    Text('Find'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.leaderboard_rounded, size: 16),
                    SizedBox(width: 4),
                    Text('Board'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildFriendsTab(),
            _buildRequestsTab(),
            _buildSearchTab(),
            _buildLeaderboardTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FRIENDS TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFriendsTab() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotImage(assetPath: AppConstants.mascotSitting, size: 80),
            const SizedBox(height: 16),
            Text('No friends yet', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Search for friends in the Find tab!',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(2),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Find Friends'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _buildFriendTile(friend)
            .animate()
            .fadeIn(delay: (50 * index).ms);
      },
    );
  }

  Widget _buildFriendTile(FriendEntity friend) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.pushNamed('friendProfile', extra: friend.uid),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: _resolveImage(friend.profileImageUrl),
              child: _resolveImage(friend.profileImageUrl) == null
                  ? Text(
                      friend.username.isNotEmpty
                          ? friend.username[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.username,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 13, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text(
                        '${friend.currentStreak} streak',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.water_drop_rounded,
                          size: 13, color: AppColors.water),
                      const SizedBox(width: 2),
                      Text(
                        '${friend.totalGoalsMet} goals',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.water,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove friend button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textHint, size: 20),
              onSelected: (value) {
                if (value == 'remove') _confirmRemoveFriend(friend);
                if (value == 'view') {
                  context.pushNamed('friendProfile', extra: friend.uid);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.person_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('View Profile'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove_rounded,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Remove Friend',
                          style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveFriend(FriendEntity friend) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Friend'),
        content: Text(
          'Are you sure you want to remove ${friend.username} as a friend?',
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
                await _friendService.removeFriend(friend.uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${friend.username} removed'),
                      backgroundColor: AppColors.textSecondary,
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

  // ═══════════════════════════════════════════════════════════════════
  // REQUESTS TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRequestsTab() {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No pending requests',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Text(
              'Friend requests will appear here',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestCard(request)
            .animate()
            .fadeIn(delay: (50 * index).ms);
      },
    );
  }

  Widget _buildRequestCard(FriendRequest request) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _resolveImage(request.fromProfileImageUrl),
            child: _resolveImage(request.fromProfileImageUrl) == null
                ? Text(
                    request.fromUsername.isNotEmpty
                        ? request.fromUsername[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
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
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () => _acceptRequest(request),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle:
                    AppTextStyles.labelMedium.copyWith(color: Colors.white),
              ),
              child: const Text('Accept'),
            ),
          ),
          const SizedBox(width: 6),
          // Decline
          SizedBox(
            height: 34,
            child: OutlinedButton(
              onPressed: () => _declineRequest(request),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: BorderSide(
                    color: AppColors.textHint.withValues(alpha: 0.4)),
              ),
              child: const Text('Decline'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(FriendRequest request) async {
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
  }

  Future<void> _declineRequest(FriendRequest request) async {
    await _friendService.declineFriendRequest(request.id);
  }

  // ═══════════════════════════════════════════════════════════════════
  // SEARCH TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            margin: EdgeInsets.zero,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                icon:
                    const Icon(Icons.search_rounded, color: AppColors.primary),
                hintText: 'Search by username...',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textHint),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _searching = false;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildSearchContent(),
        ),
      ],
    );
  }

  Widget _buildSearchContent() {
    if (!_searching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              'Find people on Waddle',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search by username to add friends',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    if (_loadingResults) {
      return const Center(child: WaddleLoader(size: 36));
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No users found',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 4),
            Text('Try a different search', style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) =>
          _buildSearchResultTile(_searchResults[index])
              .animate()
              .fadeIn(delay: (50 * index).ms),
    );
  }

  Widget _buildSearchResultTile(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    final username = user['username'] as String;
    final profileImage = user['profileImageUrl'] as String?;
    final bio = user['bio'] as String?;
    final streak = user['currentStreak'] as int? ?? 0;
    final alreadySent = _sentRequests.contains(uid);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: _resolveImage(profileImage),
            child: _resolveImage(profileImage) == null
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.primary,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                if (bio != null && bio.isNotEmpty)
                  Text(
                    bio,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    Icon(Icons.local_fire_department_rounded,
                        size: 12, color: AppColors.warning),
                    const SizedBox(width: 2),
                    Text(
                      '${streak}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 34,
            child: alreadySent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Sent'),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _sendRequest(uid, username),
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: AppTextStyles.labelMedium
                          .copyWith(color: Colors.white),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRequest(String uid, String username) async {
    try {
      await _friendService.sendFriendRequest(uid);
      setState(() => _sentRequests.add(uid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $username!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // LEADERBOARD TAB
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLeaderboardTab() {
    if (_friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotImage(assetPath: AppConstants.mascotSitting, size: 100),
            const SizedBox(height: 16),
            Text('Add friends to see the leaderboard!',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // Sort by streak descending, use totalGoalsMet as tiebreaker
    final sorted = List<FriendEntity>.from(_friends)
      ..sort((a, b) {
        final cmp = b.currentStreak.compareTo(a.currentStreak);
        return cmp != 0 ? cmp : b.totalGoalsMet.compareTo(a.totalGoalsMet);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final friend = sorted[index];
        final rank = index + 1;

        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          margin: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rank == 1
                      ? const Color(0xFFFFD700)
                      : rank == 2
                          ? const Color(0xFFC0C0C0)
                          : rank == 3
                              ? const Color(0xFFCD7F32)
                              : AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? Colors.white : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: _resolveImage(friend.profileImageUrl),
                child: _resolveImage(friend.profileImageUrl) == null
                    ? Text(
                        friend.username.isNotEmpty
                            ? friend.username[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.bodyLarge
                            .copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Name & goals
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.username,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${friend.totalGoalsMet} goals met',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              // Streak
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${friend.currentStreak}',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.05);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // IMAGE HELPER
  // ═══════════════════════════════════════════════════════════════════
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
