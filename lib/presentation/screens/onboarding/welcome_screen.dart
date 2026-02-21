import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController(viewportFraction: 0.85);

  static const _features = [
    _Feature('Set Water Goals', Icons.water_drop_rounded,
        'Calculate your personalized daily water intake based on your body and lifestyle.'),
    _Feature('Smart Reminders', Icons.notifications_active_rounded,
        'Get gentle reminders to stay hydrated throughout the day.'),
    _Feature('Track Any Drink', Icons.local_cafe_rounded,
        '70+ beverages tracked with accurate water equivalence ratios.'),
    _Feature('Build Streaks', Icons.local_fire_department_rounded,
        'Stay motivated with daily streaks and tier rewards.'),
    _Feature('Take Challenges', Icons.emoji_events_rounded,
        'Complete 14-day hydration challenges to build healthy habits.'),
    _Feature('Collect Ducks', Icons.egg_rounded,
        'Unlock 24 unique duck companions as you hydrate!'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Mascot
              MascotImage(
                assetPath: AppConstants.mascotWave,
                size: 160,
              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),

              const SizedBox(height: 16),

              // Title
              Text(
                'Welcome to',
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
              ).animate().fadeIn(delay: 200.ms),
              Text(
                'Waddle',
                style: AppTextStyles.displayLarge,
              )
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .scale(begin: const Offset(0.8, 0.8)),

              const SizedBox(height: 8),
              Text(
                'Your fun hydration companion',
                style: AppTextStyles.bodyMedium,
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 32),

              // Feature carousel
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    final feature = _features[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                feature.icon,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              feature.title,
                              style: AppTextStyles.headlineSmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              feature.description,
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 16),

              // Page indicator
              SmoothPageIndicator(
                controller: _pageController,
                count: _features.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 8,
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),

              const SizedBox(height: 32),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.pushNamed('register'),
                        child: const Text('Get Started'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.pushNamed('login'),
                        child: const Text('Log In'),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final String description;
  const _Feature(this.title, this.icon, this.description);
}
