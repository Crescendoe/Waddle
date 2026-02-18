import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/di/injection.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/repositories/health_repository.dart';
import 'package:waddle/presentation/widgets/common.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  bool _isAvailable = false;
  bool _isSyncEnabled = false;
  bool _isLoading = true;
  double? _todayIntakeOz;

  @override
  void initState() {
    super.initState();
    _loadHealthStatus();
  }

  Future<void> _loadHealthStatus() async {
    final repo = getIt<HealthRepository>();
    final availableResult = await repo.isAvailable();
    final available = availableResult.fold((_) => false, (v) => v);
    final enabledResult = await repo.isSyncEnabled();
    final enabled = enabledResult.fold((_) => false, (v) => v);

    double? todayOz;
    if (enabled) {
      final result = await repo.readTodayWaterIntake();
      result.fold(
        (_) => todayOz = null,
        (oz) => todayOz = oz, // Already in oz from repository
      );
    }

    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isSyncEnabled = enabled;
        _todayIntakeOz = todayOz;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSync(bool enable) async {
    final repo = getIt<HealthRepository>();

    if (enable) {
      final result = await repo.requestPermissions();
      final granted = result.fold((_) => false, (v) => v);
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health permissions not granted'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    await repo.setSyncEnabled(enable);
    if (mounted) setState(() => _isSyncEnabled = enable);

    if (enable) {
      _loadHealthStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Sync'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: WaddleLoader())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Status card
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          _isAvailable
                              ? Icons.favorite_rounded
                              : Icons.heart_broken_rounded,
                          size: 48,
                          color: _isAvailable
                              ? AppColors.accent
                              : AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isAvailable
                              ? 'Health Platform Available'
                              : 'Health Platform Not Available',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isAvailable
                              ? 'Sync your water intake with Apple Health or Health Connect'
                              : 'Your device doesn\'t support health data integration',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 16),

                  if (_isAvailable) ...[
                    // Toggle
                    GlassCard(
                      padding: const EdgeInsets.all(8),
                      child: SwitchListTile(
                        title: Text('Enable Health Sync',
                            style: AppTextStyles.bodyLarge
                                .copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          'Automatically write water intake to your health app',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: _isSyncEnabled,
                        onChanged: _toggleSync,
                        activeTrackColor: AppColors.primary,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 16),

                    if (_isSyncEnabled && _todayIntakeOz != null)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Today\'s Synced Data',
                                style: AppTextStyles.labelLarge),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.water_drop_rounded,
                                    color: AppColors.accent),
                                const SizedBox(width: 12),
                                Text(
                                  '${_todayIntakeOz!.toStringAsFixed(1)} oz',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(' synced to health platform',
                                    style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                  ],

                  const SizedBox(height: 16),

                  // Info
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('How It Works', style: AppTextStyles.labelLarge),
                        const SizedBox(height: 12),
                        _infoItem(Icons.add_rounded,
                            'When you log a drink in Waddle, it\'s also written to your health app'),
                        _infoItem(Icons.sync_rounded,
                            'Data syncs automatically in the background'),
                        _infoItem(Icons.lock_rounded,
                            'Your health data stays on your device'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
