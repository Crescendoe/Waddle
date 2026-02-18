import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/widgets/common.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
                  Text('Terms of Service', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Last updated: June 2025',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textHint),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    '1. Acceptance of Terms',
                    'By downloading, installing, or using Waddle ("the App"), '
                        'you agree to be bound by these Terms of Service. If you '
                        'do not agree, please do not use the App.',
                  ),
                  _section(
                    '2. Description of Service',
                    'Waddle is a hydration tracking application that allows '
                        'you to log beverages, set daily water goals, complete '
                        'challenges, collect duck companions, and optionally '
                        'sync data with Apple Health or Google Health Connect.',
                  ),
                  _section(
                    '3. User Accounts',
                    'You must create an account to use the App. You are '
                        'responsible for maintaining the confidentiality of your '
                        'account credentials and for all activities under your '
                        'account. You agree to provide accurate information '
                        'during registration.',
                  ),
                  _section(
                    '4. User Conduct',
                    'You agree not to:\n'
                        '• Use the App for any unlawful purpose\n'
                        '• Attempt to gain unauthorized access to any part of the App\n'
                        '• Interfere with or disrupt the App\'s functionality\n'
                        '• Reverse engineer or decompile the App',
                  ),
                  _section(
                    '5. Health Disclaimer',
                    'Waddle is intended for general wellness tracking only and '
                        'does NOT provide medical advice. The hydration goals, '
                        'drink health tiers, and recommendations are for '
                        'informational purposes only. Always consult a healthcare '
                        'professional for medical advice regarding hydration needs, '
                        'especially if you have kidney conditions, heart failure, '
                        'or other health concerns.',
                  ),
                  _section(
                    '6. Intellectual Property',
                    'All content, design, code, and assets in the App are owned '
                        'by Waddle and its developers. You may not reproduce, '
                        'distribute, or create derivative works without permission.',
                  ),
                  _section(
                    '7. Data and Privacy',
                    'Your use of the App is also governed by our Privacy Policy. '
                        'By using the App, you consent to the collection and use '
                        'of data as described therein.',
                  ),
                  _section(
                    '8. Limitation of Liability',
                    'The App is provided "as is" without warranties of any kind. '
                        'We are not liable for any damages arising from your use '
                        'of the App, including but not limited to lost data, '
                        'health-related decisions, or service interruptions.',
                  ),
                  _section(
                    '9. Termination',
                    'We reserve the right to suspend or terminate your account '
                        'at any time for violation of these terms. You may delete '
                        'your account at any time from within the App.',
                  ),
                  _section(
                    '10. Changes to Terms',
                    'We may update these Terms from time to time. Continued use '
                        'of the App after changes are posted constitutes acceptance '
                        'of the revised Terms.',
                  ),
                  _section(
                    'Contact',
                    'For questions about these Terms, contact us at:\n'
                        'crescendoedd@gmail.com',
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
