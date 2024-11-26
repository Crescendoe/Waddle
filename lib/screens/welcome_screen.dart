import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  WelcomeScreenState createState() => WelcomeScreenState();
}

class WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late PageController _pageController;

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Set Water Intake Goals',
      'icon': Icons.water_drop,
      'description': 'Set water intake goals based on your profile.',
    },
    {
      'title': 'Reminders',
      'icon': Icons.alarm,
      'description': 'Set reminders to drink water throughout the day.',
    },
    {
      'title': 'Track Other Drinks',
      'icon': Icons.local_cafe,
      'description':
          'Track water intake through various drinks like coffee, juice, etc.',
    },
    {
      'title': 'Water Streaks',
      'icon': Icons.trending_up,
      'description': 'Maintain water streaks to stay hydrated.',
    },
    {
      'title': 'Hydration Challenges',
      'icon': Icons.emoji_events,
      'description': 'Participate in hydration challenges.',
    },
    {
      'title': 'Creature Collecting',
      'icon': Icons.pets,
      'description': 'Earn creatures by completing various tasks.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pageController = PageController(viewportFraction: 0.8);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top text section
          const Positioned(
            top: 75,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Icon for the app logo
                Icon(
                  Icons.local_drink,
                  size: 100,
                  color: Colors.blue,
                ),
                SizedBox(height: 10),
                Text(
                  'Welcome to Waterly!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'This app will help you track your daily water intake.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Feature cards section
          Positioned(
            top: 275,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 400,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: _buildFeatureCard(
                      feature['title'] as String,
                      feature['icon'] as IconData,
                      feature['description'] as String,
                    ),
                  );
                },
              ),
            ),
          ),

          // Dots indicator
          Positioned(
            bottom: 180,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _features.length,
                effect: const WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Colors.blue,
                ),
              ),
            ),
          ),

          // Bottom buttons section
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/registration');
                  },
                  child: const Text('Sign Up'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/questions');
                  },
                  child: const Text('Skip Registration'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper method to build feature cards
Widget _buildFeatureCard(String title, IconData icon, String description) {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    elevation: 8, // Increased elevation
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.blue),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            description,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );
}
