import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/data/services/app_settings_service.dart';
import 'package:waddle/data/services/debug_mode_service.dart';
import 'package:waddle/presentation/blocs/auth/auth_cubit.dart';
import 'package:waddle/presentation/blocs/auth/auth_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final AppSettingsService _settings;
  int _versionTapCount = 0;
  DateTime? _lastVersionTap;

  @override
  void initState() {
    super.initState();
    _settings = getIt<AppSettingsService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── General ──
            _sectionLabel('General'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _settingsItem(
                    icon: Icons.notifications_rounded,
                    label: 'Notifications',
                    subtitle: 'Reminder settings',
                    onTap: () => context.pushNamed('notifications'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _settingsItem(
                    icon: Icons.favorite_rounded,
                    label: 'Health Sync',
                    subtitle: 'Apple Health / Health Connect',
                    onTap: () => context.pushNamed('healthSync'),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),

            // ── Hydration Preferences ──
            _sectionLabel('Hydration Preferences'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Units toggle
                  _buildUnitsRow(),
                  const Divider(height: 1, indent: 56),
                  // Default cup size
                  _settingsItem(
                    icon: Icons.local_cafe_rounded,
                    label: 'Default Cup Size',
                    subtitle: _settings.formatAmount(_settings.defaultCupOz),
                    onTap: () => _showCupSizePicker(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _settingsItem(
                    icon: Icons.calculate_rounded,
                    label: 'Recalculate Water Goal',
                    subtitle: 'Retake the questionnaire',
                    onTap: () => context.pushNamed('questions', extra: true),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),

            // ── Legal & Support ──
            _sectionLabel('Legal & Support'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _settingsItem(
                    icon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy',
                    subtitle: 'How we handle your data',
                    onTap: () => context.pushNamed('privacyPolicy'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _settingsItem(
                    icon: Icons.description_rounded,
                    label: 'Terms of Service',
                    subtitle: 'App usage terms',
                    onTap: () => context.pushNamed('termsOfService'),
                  ),
                  const Divider(height: 1, indent: 56),
                  _settingsItem(
                    icon: Icons.mail_rounded,
                    label: 'Contact & Feedback',
                    subtitle: AppConstants.supportEmail,
                    onTap: () => _showContactSheet(),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 20),

            // ── What's New ──
            _sectionLabel('What\'s New'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _settingsItem(
                icon: Icons.new_releases_rounded,
                label: 'Changelog',
                subtitle: 'See what\'s new in v${AppConstants.appVersion}',
                onTap: () => _showChangelog(),
              ),
            ).animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 20),

            // ── Share & Rate ──
            _sectionLabel('Spread the Word'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _settingsItem(
                    icon: Icons.share_rounded,
                    label: 'Share Waddle',
                    subtitle: 'Tell your friends about Waddle',
                    onTap: () => _shareApp(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _settingsItem(
                    icon: Icons.star_rounded,
                    label: 'Rate Waddle',
                    subtitle: 'Leave a review on the app store',
                    onTap: () => _rateApp(),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 20),

            // ── Data Management ──
            _sectionLabel('Data Management'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _settingsItem(
                    icon: Icons.refresh_rounded,
                    label: 'Clear Today\'s Data',
                    subtitle: 'Reset today\'s water intake to zero',
                    onTap: () => _confirmClearToday(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _settingsItem(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    subtitle: 'Permanently remove account & data',
                    onTap: () => _confirmDeleteAccount(),
                    danger: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),

            // ── Sign out ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmSignOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),

            Center(
              child: GestureDetector(
                onTap: _handleVersionTap,
                child: Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Secret debug mode
  // ═══════════════════════════════════════════════════════════

  void _handleVersionTap() {
    final now = DateTime.now();

    // Reset counter if more than 2 seconds since last tap
    if (_lastVersionTap != null &&
        now.difference(_lastVersionTap!).inMilliseconds > 2000) {
      _versionTapCount = 0;
    }

    _lastVersionTap = now;
    _versionTapCount++;

    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      _toggleDebugMode();
    }
  }

  void _toggleDebugMode() {
    final debugService = getIt<DebugModeService>();
    final cubit = context.read<HydrationCubit>();

    debugService.toggle();

    if (debugService.isActive) {
      cubit.activateDebugMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('\u{1F986} '),
                const SizedBox(width: 8),
                const Text('Debug mode activated — everything unlocked!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      cubit.deactivateDebugMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Debug mode deactivated'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Section label
  // ═══════════════════════════════════════════════════════════

  Widget _sectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textHint,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Settings list item
  // ═══════════════════════════════════════════════════════════

  Widget _settingsItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? AppColors.error : AppColors.primary;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: danger ? AppColors.error : null,
          )),
      subtitle: Text(subtitle,
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Units toggle row
  // ═══════════════════════════════════════════════════════════

  Widget _buildUnitsRow() {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.straighten_rounded,
            size: 20, color: AppColors.primary),
      ),
      title: Text('Unit System',
          style:
              AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(
        _settings.useMetric ? 'Milliliters (mL)' : 'Fluid Ounces (oz)',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ToggleButtons(
          isSelected: [!_settings.useMetric, _settings.useMetric],
          onPressed: (i) async {
            await _settings.setUnits(i == 0 ? 'oz' : 'ml');
            setState(() {});
          },
          borderRadius: BorderRadius.circular(8),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
          selectedColor: Colors.white,
          fillColor: AppColors.primary,
          color: AppColors.textSecondary,
          textStyle:
              AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
          children: const [Text('oz'), Text('mL')],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Cup size picker
  // ═══════════════════════════════════════════════════════════

  void _showCupSizePicker() {
    double cup = _settings.defaultCupOz;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Default Cup Size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _settings.formatAmount(cup, decimals: 0),
                style: AppTextStyles.displaySmall
                    .copyWith(color: AppColors.primary),
              ),
              Slider(
                value: cup,
                min: 4,
                max: 32,
                divisions: 28,
                label: '${cup.toInt()} oz',
                onChanged: (v) => setD(() => cup = v),
              ),
              Text(
                'Used as the default amount when logging water.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _settings.setDefaultCupOz(cup);
                setState(() {});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Clear today's data
  // ═══════════════════════════════════════════════════════════

  void _confirmClearToday() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Today\'s Data?'),
        content: const Text(
          'This will reset your water intake to zero for today. '
          'Your streak and previous days are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final cubit = context.read<HydrationCubit>();
              final state = cubit.state;
              if (state is HydrationLoaded) {
                cubit.clearTodayData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Today\'s data cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Delete account
  // ═══════════════════════════════════════════════════════════

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and all data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authCubit = context.read<AuthCubit>();
              await authCubit.deleteAccount();
              if (!context.mounted) return;
              if (authCubit.state is Unauthenticated) {
                context.goNamed('login');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Failed to delete account. Please sign out, sign back in, and try again.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Sign out
  // ═══════════════════════════════════════════════════════════

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthCubit>().signOut();
              if (context.mounted) context.goNamed('login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Contact sheet
  // ═══════════════════════════════════════════════════════════

  void _showContactSheet() {
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
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.mail_rounded, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('Contact Us', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Have feedback, questions, or need help?\nSend us an email:',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(
              AppConstants.supportEmail,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Share & Rate
  // ═══════════════════════════════════════════════════════════

  void _showChangelog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Changelog', style: AppTextStyles.headlineSmall),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _changelogVersion(
                    version: '0.9.1',
                    date: 'February 18, 2026',
                    changes: [
                      _ChangeEntry(
                        icon: Icons.water_drop_rounded,
                        title: 'Segmented Cup Display',
                        description:
                            'The cup now shows colored segments for each drink type you\'ve logged throughout the day. Tap the cup to see a breakdown of each drink.',
                      ),
                      _ChangeEntry(
                        icon: Icons.local_cafe_rounded,
                        title: '70+ Drink Options',
                        description:
                            'Massively expanded drink menu with researched hydration ratios and health tiers — including teas, coffees, juices, dairy-free milks, sports drinks, alcohol, and more.',
                      ),
                      _ChangeEntry(
                        icon: Icons.star_rounded,
                        title: 'Favorite Drinks',
                        description:
                            'Long-press any drink to add it to your favorites. Favorites appear at the top of the drink menu for quick logging.',
                      ),
                      _ChangeEntry(
                        icon: Icons.search_rounded,
                        title: 'Drink Search',
                        description:
                            'Search bar in the drink picker to quickly find any beverage by name or category.',
                      ),
                      _ChangeEntry(
                        icon: Icons.palette_rounded,
                        title: 'Improved Cup Labels',
                        description:
                            'Consistent, adaptive labels on drink segments with smooth scaling. Readable text over any drink color.',
                      ),
                      _ChangeEntry(
                        icon: Icons.sort_rounded,
                        title: 'Today\'s Log Sorting',
                        description:
                            'Today\'s drink log now shows your most recent entries first.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _changelogVersion(
                    version: '0.9.0',
                    date: 'February 2026',
                    changes: [
                      _ChangeEntry(
                        icon: Icons.egg_rounded,
                        title: 'Initial Release',
                        description:
                            'Water tracking, duck collection, streaks, challenges, friend profiles, and notification reminders.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _changelogVersion({
    required String version,
    required String date,
    required List<_ChangeEntry> changes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v$version',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              date,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...changes.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(entry.icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        const Divider(height: 24),
      ],
    );
  }

  void _shareApp() {
    Share.share(
      'Check out Waddle — a fun water tracking app with a duck mascot! '
      'Stay hydrated and collect ducks along the way. \uD83E\uDD86\uD83D\uDCA7',
    );
  }

  void _rateApp() {
    // Placeholder — replace with actual store link when published
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rating will be available once the app is published!'),
      ),
    );
  }
}

class _ChangeEntry {
  final IconData icon;
  final String title;
  final String description;

  const _ChangeEntry({
    required this.icon,
    required this.title,
    required this.description,
  });
}
