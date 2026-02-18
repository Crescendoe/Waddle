import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flying duck animation
                MascotImage(
                  assetPath: AppConstants.mascotFlying,
                  size: 180,
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -1.5, curve: Curves.easeOutBack),

                const SizedBox(height: 32),

                // Success icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 48,
                  ),
                ).animate(delay: 800.ms).fadeIn().scale(
                      begin: const Offset(0, 0),
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    ),

                const SizedBox(height: 24),

                Text(
                  'Account Created!',
                  style: AppTextStyles.displaySmall,
                ).animate(delay: 1000.ms).fadeIn(),

                const SizedBox(height: 8),

                Text(
                  "Let's set up your hydration goals",
                  style: AppTextStyles.bodyMedium,
                ).animate(delay: 1200.ms).fadeIn(),

                const SizedBox(height: 48),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.goNamed('questions'),
                      child: const Text('Get Started'),
                    ),
                  ),
                ).animate(delay: 1400.ms).fadeIn().slideY(begin: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
