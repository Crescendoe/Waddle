import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/domain/entities/app_theme_reward.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/floating_objects_overlay.dart';

/// Gradient background used across the app.
///
/// If [colors] is provided it is used directly.
/// Otherwise the active theme from [HydrationCubit] is used (if available).
/// Falls back to the default gradient when neither applies.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ?? _resolveThemeColors(context);
    final effect = _resolveThemeEffect(context);

    return Stack(
      children: [
        // Base gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: effectiveColors,
            ),
          ),
        ),
        // Floating objects overlay (when theme has an effect)
        if (effect != ThemeEffect.none)
          Positioned.fill(
            child: FloatingObjectsOverlay(
              effect: effect,
              gradientColors: effectiveColors,
            ),
          ),
        // Actual content
        Positioned.fill(child: child),
      ],
    );
  }

  /// Try reading the user's active theme from the cubit.
  /// Returns default gradient when the cubit is absent (auth/splash screens).
  static List<Color> _resolveThemeColors(BuildContext context) {
    try {
      final state = context.read<HydrationCubit>().state;
      if (state is HydrationLoaded) {
        final themeId = state.hydration.activeThemeId;
        if (themeId != null) {
          final theme = ThemeRewards.byId(themeId);
          if (theme != null) return theme.gradientColors;
        }
      }
    } catch (_) {
      // HydrationCubit not in widget tree — fall through
    }
    return const [AppColors.gradientTop, AppColors.gradientBottom];
  }

  /// Resolve the active theme's floating-object effect.
  static ThemeEffect _resolveThemeEffect(BuildContext context) {
    try {
      final state = context.read<HydrationCubit>().state;
      if (state is HydrationLoaded) {
        final themeId = state.hydration.activeThemeId;
        if (themeId != null) {
          final theme = ThemeRewards.byId(themeId);
          if (theme != null) return theme.effect;
        }
      }
    } catch (_) {
      // HydrationCubit not in widget tree — fall through
    }
    return ThemeEffect.none;
  }
}

/// Mascot image widget — simple asset image wrapper
class MascotImage extends StatelessWidget {
  final String assetPath;
  final double size;

  const MascotImage({
    super.key,
    required this.assetPath,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

/// Glassmorphism card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Stat card widget for profile/stats screens
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.headlineMedium.copyWith(color: color),
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary loading indicator
class WaddleLoader extends StatelessWidget {
  final double size;

  const WaddleLoader({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
