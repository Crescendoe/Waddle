import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
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
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Privacy Policy', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: June 2025',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    'Information We Collect',
                    'When you register or log in, we collect your email address, '
                        'username, and authentication credentials. You may optionally '
                        'upload a profile image.\n\n'
                        'We collect data you enter about your water and beverage '
                        'intake, goals, streaks, and achievements.\n\n'
                        'We may collect information about your device, such as '
                        'device model, operating system, and unique device '
                        'identifiers. A Firebase Cloud Messaging token is used '
                        'to send notifications if you enable them.',
                  ),
                  _section(
                    'How We Use Your Information',
                    '• Provide and maintain core features (hydration tracking, '
                        'challenges, reminders)\n'
                        '• Personalize your experience and save your progress\n'
                        '• Send you notifications and reminders (if enabled)\n'
                        '• Improve and analyze app performance\n'
                        '• Secure your account and prevent unauthorized access',
                  ),
                  _section(
                    'Data Storage and Security',
                    'Your data is securely stored using Google Firebase services. '
                        'We implement industry-standard security measures to '
                        'protect your information. Only you can access your '
                        'hydration data and profile information.',
                  ),
                  _section(
                    'Sharing of Information',
                    'We do not sell or share your personal information with '
                        'third parties except as required by law or to provide '
                        'core app functionality (e.g., authentication, cloud '
                        'backup). Aggregated, anonymized data may be used for '
                        'analytics and app improvement.',
                  ),
                  _section(
                    'Permissions',
                    '• Camera & Photos — To upload a profile image (optional)\n'
                        '• Notifications — To send reminders (optional)\n'
                        '• Internet Access — To sync data and enable authentication\n\n'
                        'You can control these permissions in your device settings.',
                  ),
                  _section(
                    'Health Data (HealthKit / Health Connect)',
                    'If you enable health sync, Waddle may read and write water '
                        'intake data to Apple HealthKit (iOS) or Google Health '
                        'Connect (Android). This data is:\n\n'
                        '• Used solely to keep your hydration records in sync '
                        'across health-related apps on your device.\n'
                        '• Never transmitted to our servers, shared with third '
                        'parties, or used for advertising.\n'
                        '• Stored only on your device by the platform\'s health '
                        'framework.\n\n'
                        'You can enable or disable health sync at any time in '
                        'Settings > Health Sync.',
                  ),
                  _section(
                    'Children\'s Privacy',
                    'Waddle is not intended for children under the age of 13. '
                        'We do not knowingly collect personal information from '
                        'children under 13.',
                  ),
                  _section(
                    'Your Rights',
                    '• You can access, update, or delete your account and '
                        'hydration data at any time from within the app.\n'
                        '• You may request deletion of your account and all '
                        'associated data by contacting us at the email below.',
                  ),
                  _section(
                    'Contact',
                    'If you have any questions about this Privacy Policy, '
                        'please contact us at:\ncrescendoedd@gmail.com',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          Text(body,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
