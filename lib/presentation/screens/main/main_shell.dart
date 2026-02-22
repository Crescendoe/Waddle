import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';
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
    return BlocBuilder<HydrationCubit, HydrationBlocState>(
      buildWhen: (prev, curr) {
        // Only rebuild when the active theme changes
        final oldId =
            prev is HydrationLoaded ? prev.hydration.activeThemeId : null;
        final newId =
            curr is HydrationLoaded ? curr.hydration.activeThemeId : null;
        return oldId != newId;
      },
      builder: (context, _) {
        final tc = ActiveThemeColors.of(context);
        final topRadius = const Radius.circular(24);
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: topRadius,
            topRight: topRadius,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.55),
                    width: 0.5,
                  ),
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: tc.primary.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _NavItem(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Streaks',
                          isSelected: _currentIndex == 0,
                          onTap: () => _onTabTapped(0),
                          themeColors: tc,
                        ),
                        _NavItem(
                          icon: Icons.emoji_events_rounded,
                          label: 'Challenges',
                          isSelected: _currentIndex == 1,
                          onTap: () => _onTabTapped(1),
                          themeColors: tc,
                        ),
                        _NavItem(
                          icon: Icons.water_drop_rounded,
                          label: '',
                          isSelected: _currentIndex == 2,
                          onTap: () => _onTabTapped(2),
                          isCenter: true,
                          themeColors: tc,
                        ),
                        _NavItem(
                          icon: Icons.egg_rounded,
                          label: 'Collection',
                          isSelected: _currentIndex == 3,
                          onTap: () => _onTabTapped(3),
                          themeColors: tc,
                        ),
                        _NavItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          isSelected: _currentIndex == 4,
                          onTap: () => _onTabTapped(4),
                          themeColors: tc,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCenter;
  final VoidCallback onTap;
  final ActiveThemeColors themeColors;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.themeColors,
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
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [themeColors.primary, themeColors.accent],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: isSelected ? grad : null,
            color: isSelected ? null : AppColors.surfaceLight,
            shape: BoxShape.circle,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: themeColors.primary.withValues(alpha: 0.3),
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
          color: isSelected ? themeColors.primary : AppColors.textHint,
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? themeColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
