import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/screens/main/home_screen.dart';
import 'package:waddle/presentation/screens/main/streaks_screen.dart';
import 'package:waddle/presentation/screens/main/challenges_screen.dart';
import 'package:waddle/presentation/screens/main/duck_collection_screen.dart';
import 'package:waddle/presentation/screens/main/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 2; // Start on Home (center)
  late final PageController _pageController;

  final List<Widget> _pages = const [
    StreaksScreen(),
    ChallengesScreen(),
    HomeScreen(),
    DuckCollectionScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _NavItem(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Streaks',
                    isSelected: _currentIndex == 0,
                    onTap: () => _onTabTapped(0),
                  ),
                  _NavItem(
                    icon: Icons.emoji_events_rounded,
                    label: 'Challenges',
                    isSelected: _currentIndex == 1,
                    onTap: () => _onTabTapped(1),
                  ),
                  _NavItem(
                    icon: Icons.water_drop_rounded,
                    label: '',
                    isSelected: _currentIndex == 2,
                    onTap: () => _onTabTapped(2),
                    isCenter: true,
                  ),
                  _NavItem(
                    icon: Icons.egg_rounded,
                    label: 'Ducks',
                    isSelected: _currentIndex == 3,
                    onTap: () => _onTabTapped(3),
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    isSelected: _currentIndex == 4,
                    onTap: () => _onTabTapped(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCenter;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = isCenter ? _buildCenterItem() : _buildRegularItem();
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      ),
    );
  }

  Widget _buildCenterItem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : AppColors.surfaceLight,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 26,
            color: isSelected ? Colors.white : AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildRegularItem() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: isSelected ? AppColors.primary : AppColors.textHint,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
