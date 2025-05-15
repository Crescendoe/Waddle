// ignore_for_file: avoid_types_as_parameter_names

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'dart:math';
import 'dart:async';
import 'package:waterly/screens/settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:waterly/screens/notifications_screen.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:google_fonts/google_fonts.dart';

// MainScreen is the root widget for the main navigation and logic of the app.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

// State for MainScreen, handles navigation, loading, and challenge state.
class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2; // Set default index to 2 (Home)
  final PageController _pageController =
      PageController(initialPage: 2); // Set initial page to 2

  late AnimationController _waveController;
  bool _isLoading = true; // Add loading state
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    // Animation controller for water wave animation
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: false);

    // Load Firestore variables and ensure no overwrites
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final waterTracker = context.read<WaterTracker>();

      // Fetch waterConsumed and waterGoal from Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final snapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            waterTracker.waterConsumed = data['waterConsumed'] ?? 0.0;
            waterTracker.waterGoal =
                data['waterGoal'] ?? 64.0; // Default to 64 oz
          }
        }
      }

      await waterTracker.loadWaterData();
      await waterTracker.checkAndResetDailyData();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Check challenge state on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<WaterTracker>().checkChallengeState();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });

    // Schedule daily reset at midnight
    scheduleDailyReset();
    // check if the checkAndResetDailyData function needs to be called
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);
    Timer(durationUntilMidnight, () async {
      await context.read<WaterTracker>().checkAndResetDailyData();
    });
  }

  // Schedules a timer to reset daily data at midnight
  void scheduleDailyReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    Timer(durationUntilMidnight, () async {
      await context.read<WaterTracker>().resetDailyData();
      scheduleDailyReset(); // Reschedule the next reset
    });
  }

  // Resets the entry timer for water logging
  // ignore: unused_element
  void _resetEntryTimer() {
    setState(() {
      context.read<WaterTracker>().nextEntryTime = null;
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _screenshotController.dispose();
    super.dispose();
  }

  // Shares a screenshot of the profile to social media
  // ignore: unused_element
  void _shareProfile() async {
    final image = await _screenshotController.capture();
    if (image != null && mounted) {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/screenshot.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);
      await SocialSharingPlus.shareToSocialMedia(
        SocialPlatform.facebook,
        'Check out my profile on Waddle!',
        media: imagePath,
        isOpenBrowser: false,
        onAppNotInstalled: () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('Facebook is not installed.'),
            ));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Main build method, handles loading, challenge, and main content states
    return Scaffold(
      // ignore: deprecated_member_use
      body: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : context.watch<WaterTracker>().challengeFailed
                ? _buildFailureState()
                : context.watch<WaterTracker>().challengeCompleted
                    ? _buildSuccessState()
                    : _buildMainContent(),
      ),
    );
  }

  // UI shown when the user fails a challenge
  Widget _buildFailureState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Challenge Failed',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<WaterTracker>().resetChallenge();
              setState(() {});
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // UI shown when the user completes a challenge
  Widget _buildSuccessState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Congratulations!',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<WaterTracker>().completeChallenge();
              setState(() {});
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Main content with navigation and page views
  Widget _buildMainContent() {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              StreakScreen(),
              ChallengesScreen(),
              Screenshot(
                controller: _screenshotController,
                child: HomeScreen(),
              ),
              DuckScreen(),
              ProfileScreen(
                screenshotController: _screenshotController,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            items: [
              _buildBottomNavItem(
                icon: Icons.calendar_today_rounded,
                label: 'Streaks',
                index: 0,
              ),
              _buildBottomNavItem(
                icon: Icons.emoji_events_rounded,
                label: 'Challenges',
                index: 1,
              ),
              _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 2,
              ),
              _buildBottomNavItem(
                icon: Icons.water_rounded,
                label: 'Ducks',
                index: 3,
              ),
              _buildBottomNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 4,
              ),
            ],
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: false,
          ),
        ),
      ),
    );
  }

  // Helper to build navigation bar items with animation
  BottomNavigationBarItem _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: CircleAvatar(
          key: ValueKey(isSelected),
          radius: 20,
          backgroundColor:
              isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          child: Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.black,
          ),
        ),
      ),
      label: isSelected ? label : '',
    );
  }
}

// Extension to allow ScreenshotController to be disposed (no-op)
extension on ScreenshotController {
  void dispose() {}
}

// Helper to rebuild UI, e.g., after profile image change
void rebuildUI(BuildContext context) {
  try {
    Navigator.pushReplacementNamed(context, '/home');
  } catch (e) {
    // Handle error if needed
  }
}

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StreakScreenState createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  Map<DateTime, bool> _loggedDays = {};
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLoggedDays();
    _loadWaterLogsFromFirebase();
  }

  Future<void> _loadLoggedDays() async {
    // ignore: unnecessary_cast
    final user = FirebaseAuth.instance.currentUser as User?;
    if (user != null) {
      final uid = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('waterLogs')
          .get();

      final loggedDays = <DateTime, bool>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final entryTime = DateTime.parse(data['entryTime']);
        loggedDays[DateTime(entryTime.year, entryTime.month, entryTime.day)] =
            true;
      }

      setState(() {
        _loggedDays = loggedDays;
      });

      // Ensure lastResetDate is not unintentionally updated
      // ignore: use_build_context_synchronously
      final waterTracker = context.read<WaterTracker>();
      if (waterTracker.lastResetDate == null ||
          waterTracker.lastResetDate!
              .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        await waterTracker.checkAndResetDailyData();
      }
    }
  }

  Future<void> _loadWaterLogsFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('waterLogs')
          .get();

      final logs = snapshot.docs.map((doc) {
        final data = doc.data();
        return WaterLog(
          drinkName: data['drinkName'],
          amount: data['amount'],
          waterContent: data['waterContent'],
          entryTime: DateTime.parse(data['entryTime']),
        );
      }).toList();

      // Set logs without overwriting existing data
      // ignore: use_build_context_synchronously
      context.read<WaterTracker>().setLogs(logs);
    }
  }

  String _getMonthName(int month) {
    List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  Widget _buildCalendar() {
    var now = _selectedDate;
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayWeekday = firstDayOfMonth.weekday;
    final emptyDays = firstDayWeekday == 7 ? 0 : firstDayWeekday;
    final totalDays = emptyDays + daysInMonth;

    return Column(
      children: [
        // Month and Year with arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (now.year > 2024 || (now.year == 2024 && now.month > 1))
              IconButton(
                icon:
                    const Icon(Icons.arrow_back_ios, color: Color(0xFF36708B)),
                onPressed: () {
                  setState(() {
                    final previousMonth = DateTime(now.year, now.month - 1, 1);
                    _selectedDate = previousMonth;
                  });
                },
              ),
            Text(
              '${_getMonthName(now.month)} ${now.year}',
              style: GoogleFonts.cherryBombOne(
                  fontSize: 24, color: Color(0xFF36708B)),
            ),
            if (now.year < 2099 || (now.year == 2099 && now.month < 12))
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFF36708B)),
                onPressed: () {
                  setState(() {
                    final nextMonth = DateTime(now.year, now.month + 1, 1);
                    _selectedDate = nextMonth;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Days of the week
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('S',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('M',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('T',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('W',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('T',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('F',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            Text('S',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          itemCount: totalDays,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (context, index) {
            if (index < emptyDays) {
              return const SizedBox.shrink();
            }

            final day = firstDayOfMonth.add(Duration(days: index - emptyDays));
            final isLogged = _loggedDays[day] ?? false;
            final isGoalMet = isLogged && _isGoalMet(day);
            final isToday = day.year == DateTime.now().year &&
                day.month == DateTime.now().month &&
                day.day == DateTime.now().day;
            final isSelected = day.year == _selectedDate.year &&
                day.month == _selectedDate.month &&
                day.day == _selectedDate.day;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = day;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(6.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2)
                        ]
                      : [],
                  border: isSelected
                      ? Border.all(color: Colors.blueAccent, width: 3)
                      : null,
                  color: isGoalMet
                      ? Colors.blueAccent
                      : isLogged
                          ? Colors.blueAccent.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                ),
                child: Center(
                  child: isGoalMet
                      ? const Icon(Icons.local_drink, color: Colors.white)
                      : Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday ? Colors.blue : Colors.black,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: isToday ? 18 : 14,
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isGoalMet(DateTime day) {
    // Check if the goal is met for the given day
    final logs = context.read<WaterTracker>().getLogsForDay(day);
    double totalWaterIntake = logs.fold(0, (sum, log) => sum + log.amount);
    return totalWaterIntake >= context.read<WaterTracker>().waterGoal;
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  void _deleteLog(BuildContext context, WaterLog log) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Entry'),
          content: const Text('Are you sure you want to delete this entry?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
            TextButton(
              onPressed: () async {
                context.read<WaterTracker>().removeLog(log);
                if (log.entryTime.year == DateTime.now().year &&
                    log.entryTime.month == DateTime.now().month &&
                    log.entryTime.day == DateTime.now().day) {
                  context.read<WaterTracker>().subtractWater(log.amount);
                }
                Navigator.pop(context);
                setState(() {
                  _loggedDays.remove(log.entryTime);
                });

                // Delete the log from Firestore
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final uid = user.uid;
                  final snapshot = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('waterLogs')
                      .where('entryTime',
                          isEqualTo: log.entryTime.toIso8601String())
                      .get();

                  for (var doc in snapshot.docs) {
                    await doc.reference.delete();
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<WaterTracker>().getLogsForDay(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Streaks',
          style: GoogleFonts.cherryBombOne(),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Scrollbar(
        thumbVisibility: true, // Makes the scrollbar always visible
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Added BouncingScrollPhysics
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.opacity,
                            size: 120 +
                                (context.watch<WaterTracker>().currentStreak *
                                        2)
                                    .toDouble(),
                            color: context
                                        .watch<WaterTracker>()
                                        .currentStreak >=
                                    30
                                ? Colors.blue // Platinum
                                : context.watch<WaterTracker>().currentStreak >=
                                        20
                                    ? Colors.amber // Gold
                                    : context
                                                .watch<WaterTracker>()
                                                .currentStreak >=
                                            15
                                        ? Colors.grey // Silver
                                        : context
                                                    .watch<WaterTracker>()
                                                    .currentStreak >=
                                                10
                                            ? Colors.brown // Bronze
                                            : Colors.blueAccent
                                                .withOpacity(0.3), // Grey
                          ),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  '${context.watch<WaterTracker>().currentStreak}',
                                  style: GoogleFonts.cherryBombOne(
                                    fontSize: 60,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildCalendar(),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                logs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'No entries recorded!',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 16),
                            Image(
                              image: AssetImage(
                                  'lib/assets/images/wade_running.png'),
                              height: 100,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final drink = [
                            {
                              'name': 'Water',
                              'icon': Icons.water_drop,
                              'color': Colors.blue[700] ?? Colors.blue
                            },
                            {
                              'name': 'Sparkling Water',
                              'icon': Icons.bubble_chart_outlined,
                              'color': Colors.cyan[700] ?? Colors.cyan
                            },
                            {
                              'name': 'Coconut Water',
                              'icon': Icons.beach_access,
                              'color': Colors.teal[600] ?? Colors.teal
                            },
                            {
                              'name': 'Black Tea',
                              'icon': Icons.local_cafe,
                              'color': Colors.brown[800] ?? Colors.brown
                            },
                            {
                              'name': 'Green Tea',
                              'icon': Icons.eco,
                              'color': Colors.green[700] ?? Colors.green
                            },
                            {
                              'name': 'Herbal Tea',
                              'icon': Icons.spa,
                              'color':
                                  Colors.lightGreen[700] ?? Colors.lightGreen
                            },
                            {
                              'name': 'Matcha',
                              'icon': Icons.grass,
                              'color':
                                  Colors.greenAccent[700] ?? Colors.greenAccent
                            },
                            {
                              'name': 'Juice',
                              'icon': Icons.local_bar,
                              'color': Colors.orange[700] ?? Colors.orange
                            },
                            {
                              'name': 'Lemonade',
                              'icon': Icons.wb_sunny,
                              'color': Colors.yellow[800] ?? Colors.yellow
                            },
                            {
                              'name': 'Milk',
                              'icon': Icons.local_drink,
                              'color': Colors.blueGrey[300] ?? Colors.blueGrey
                            },
                            {
                              'name': 'Skim Milk',
                              'icon': Icons.local_drink_outlined,
                              'color': Colors.indigo[300] ?? Colors.indigo
                            },
                            {
                              'name': 'Almond Milk',
                              'icon': Icons.nature,
                              'color': Colors.pink[400] ?? Colors.pink
                            },
                            {
                              'name': 'Oat Milk',
                              'icon': Icons.grain,
                              'color': Colors.brown[400] ?? Colors.brown
                            },
                            {
                              'name': 'Soy Milk',
                              'icon': Icons.emoji_nature,
                              'color': Colors.amber[400] ?? Colors.amber
                            },
                            {
                              'name': 'Yogurt',
                              'icon': Icons.icecream_outlined,
                              'color':
                                  Colors.deepOrange[400] ?? Colors.deepOrange
                            },
                            {
                              'name': 'Milkshake',
                              'icon': Icons.blender_outlined,
                              'color': Colors.purple[600] ?? Colors.purple
                            },
                            {
                              'name': 'Energy Drink',
                              'icon': Icons.bolt,
                              'color': Colors.red[700] ?? Colors.red
                            },
                            {
                              'name': 'Coffee',
                              'icon': Icons.coffee_maker,
                              'color': Colors.brown[700] ?? Colors.brown
                            },
                            {
                              'name': 'Decaf Coffee',
                              'icon': Icons.coffee_outlined,
                              'color': Colors.brown[600] ?? Colors.brown
                            },
                            {
                              'name': 'Latte',
                              'icon': Icons.local_cafe_outlined,
                              'color': Colors.brown[500] ?? Colors.brown
                            },
                            {
                              'name': 'Hot Chocolate',
                              'icon': Icons.coffee_rounded,
                              'color':
                                  Colors.deepOrange[700] ?? Colors.deepOrange
                            },
                            {
                              'name': 'Soda',
                              'icon': Icons.sports_bar,
                              'color': Colors.redAccent[700] ?? Colors.redAccent
                            },
                            {
                              'name': 'Diet Soda',
                              'icon': Icons.no_drinks,
                              'color': Colors.pink[700] ?? Colors.pink
                            },
                            {
                              'name': 'Smoothie',
                              'icon': Icons.blender,
                              'color': Colors.purple[700] ?? Colors.purple
                            },
                            {
                              'name': 'Sports Drink',
                              'icon': Icons.sports_handball,
                              'color': Colors.blue[800] ?? Colors.blue
                            },
                            {
                              'name': 'Protein Shake',
                              'icon': Icons.fitness_center,
                              'color': Colors.orangeAccent[700] ??
                                  Colors.orangeAccent
                            },
                            {
                              'name': 'Soup',
                              'icon': Icons.ramen_dining,
                              'color': Colors.redAccent[800] ?? Colors.redAccent
                            },
                          ].firstWhere(
                            (drink) => drink['name'] == log.drinkName,
                            orElse: () => {
                              'icon': Icons.local_drink,
                              'color': Colors.grey,
                            },
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                backgroundColor: drink['color'] as Color,
                                child: Icon(
                                  drink['icon'] as IconData,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(log.drinkName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Amount: ${log.amount} oz\nWater Content: ${log.waterContent}%'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatTime(log.entryTime),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.red),
                                    onPressed: () {
                                      _deleteLog(context, log);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final waterTracker = context.watch<WaterTracker>();
    final activeChallengeIndex = waterTracker.activeChallengeIndex;

    if (activeChallengeIndex != null && activeChallengeIndex >= 0) {
      return _buildActiveChallengeScreen(context, activeChallengeIndex);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Challenges',
          style: GoogleFonts.cherryBombOne(),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Scrollbar(
        thumbVisibility: true, // Makes the scrollbar always visible
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: GridView.builder(
            physics:
                const BouncingScrollPhysics(), // Added BouncingScrollPhysics
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 0,
              childAspectRatio: 2.25,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChallengeDetailScreen(index: index),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                  decoration: BoxDecoration(
                    color: _getChallengeColor(index),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26, // Match shadow color
                        blurRadius: 6, // Match blur radius
                        spreadRadius: 1, // Match spread radius
                        offset: const Offset(0, 3), // Match offset
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '14 Day Challenge',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              getChallengeTitle(index),
                              style: GoogleFonts.cherryBombOne(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                            _getChallengeImage(index),
                            width: 120,
                            height: 200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChallengeScreen(BuildContext context, int index) {
    final waterTracker = context.watch<WaterTracker>();
    final challengeCompletedToday = waterTracker.goalMetToday;
    final daysLeft = 14 - waterTracker.currentStreak;

    return Scaffold(
      appBar: AppBar(
        title: Text(getChallengeTitle(index)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(), // Added BouncingScrollPhysics
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                _getChallengeImage(index),
                width: 170,
                height: 170,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                getChallengeTitle(index),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _getChallengeColor(index),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                getChallengeDescription(index),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Challenge Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                getChallengeDetails(index),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    challengeCompletedToday ? Icons.check_circle : Icons.cancel,
                    color: challengeCompletedToday ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    challengeCompletedToday
                        ? 'Completed Today!'
                        : 'Not Completed Today',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          challengeCompletedToday ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: _getChallengeColor(index),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Days Left: $daysLeft',
                    style: TextStyle(
                      fontSize: 16,
                      color: _getChallengeColor(index),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton(
                onPressed: () async {
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Give Up Challenge'),
                        content: const Text(
                            'Are you sure you want to give up this challenge?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context, true);
                            },
                            child: const Text('Give Up'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await context.read<WaterTracker>().resetChallenge();
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                },
                child: const Text('Give Up Challenge'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String getChallengeTitle(int index) {
    switch (index) {
      case 0:
        return 'Nothing But Water';
      case 1:
        return 'Tea Time';
      case 2:
        return 'Caffine Cut';
      case 3:
        return 'Sugar-Free Sips';
      case 4:
        return 'Dairy-Free Refresh';
      case 5:
        return 'Vitamin Vitality';
      default:
        return 'Challenge';
    }
  }

  Color _getChallengeColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue[400]!;
      case 1:
        return Colors.green[400]!;
      case 2:
        return Colors.brown[400]!;
      case 3:
        return Colors.red[400]!;
      case 4:
        return Colors.orange[400]!;
      case 5:
        return Colors.purple[400]!;
      default:
        return Colors.blueAccent[400]!;
    }
  }

  String _getChallengeImage(int index) {
    switch (index) {
      case 0:
        return 'lib/assets/images/wade_nothing_but_water.png';
      case 1:
        return 'lib/assets/images/wade_tea_time.png';
      case 2:
        return 'lib/assets/images/wade_caffeine_cut.png';
      case 3:
        return 'lib/assets/images/wade_sugar_free_sips.png';
      case 4:
        return 'lib/assets/images/wade_dairy_free_refresh.png';
      case 5:
        return 'lib/assets/images/wade_vitamin_vitality.png';
      default:
        return 'lib/assets/images/wade_default.png';
    }
  }

  String getChallengeDescription(int index) {
    switch (index) {
      case 0:
        return 'For 14 days, drink only water. No sugary drinks, teas, or coffee. Just pure, refreshing H2O!';
      case 1:
        return 'Enjoy at least 12 oz of tea daily for 14 days. Embrace tea\'s calming and health-boosting properties!';
      case 2:
        return 'Limit your caffeine intake to no more than 55mg a day for 14 days. Say goodbye to the jitters!';
      case 3:
        return 'Eliminate sugary drinks for 14 days. Embrace cleaner, healthier hydration options!';
      case 4:
        return 'Replace all dairy-based drinks with dairy-free alternatives for 14 days. Explore delicious, plant-based options!';
      case 5:
        return 'Drink at least 12 oz of a vitamin- or mineral-rich beverage daily for 14 days. Nourish your body!';
      default:
        return 'Challenge details';
    }
  }

  String getChallengeDetails(int index) {
    switch (index) {
      case 0:
        return 'Challenge yourself to drink only water for 14 days straight. No sugary drinks, no teas, no coffee—just pure, refreshing H2O!';
      case 1:
        return 'Enjoy at least 12 oz of tea every day for 14 days. Whether it’s herbal, green, or black tea, the choice is yours!';
      case 2:
        return 'Limit your caffeine intake to no more than 55mg a day for 14 days. Say goodbye to the jitters and hello to better energy balance!';
      case 3:
        return 'Eliminate sugary drinks for 14 days and embrace cleaner, healthier hydration options. Reach for water, unsweetened tea, or naturally flavored sparkling water!';
      case 4:
        return 'Replace all dairy-based drinks with a dairy-free alternative for 14 days. Think oat milk lattes, almond milk smoothies, and coconut milk in your favorite recipes!';
      case 5:
        return 'Drink at least 12 oz of a vitamin- or mineral-rich beverage daily for 14 days. Whether it’s a smoothie, fortified drink, or juice, this challenge is all about getting your daily dose of vitamins and minerals in a delicious way!';
      default:
        return 'Challenge details';
    }
  }
}

class ChallengeDetailScreen extends StatelessWidget {
  final int index;

  const ChallengeDetailScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Scrollbar(
        thumbVisibility: true, // Makes the scrollbar always visible
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Added BouncingScrollPhysics
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 200,
                      ),
                      Image.asset(
                        ChallengesScreen()._getChallengeImage(index),
                        width: 200,
                        height: 200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    ChallengesScreen.getChallengeTitle(index),
                    style: GoogleFonts.cherryBombOne(
                      fontSize: 28,
                      color: _getChallengeColor(index),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    getChallengeDescription(index),
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: 'Challenge Details',
                  content: getChallengeDetails(index),
                  color: _getChallengeColor(index),
                ),
                const SizedBox(height: 20),
                _buildSection(
                  title: 'Health Factoids',
                  content: getHealthFactoids(index),
                  color: _getChallengeColor(index),
                ),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 2.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Begin Challenge'),
                  content: Text(
                      'Are you ready to begin the "${ChallengesScreen.getChallengeTitle(index)}" challenge?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await context
                            .read<WaterTracker>()
                            .startChallenge(index);
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text('Begin'),
                    ),
                  ],
                );
              },
            );
          },
          label: const Text('Begin Challenge!'),
          icon: const Icon(Icons.flag),
          backgroundColor: _getChallengeColor(index),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

String getChallengeDescription(int index) {
  switch (index) {
    case 0:
      return 'Ready to dive into the ultimate refreshment? For 14 days, it\'s all about going back to basics: pure, crisp, hydrating water. Whether you prefer still water, sparkling, or coconut water, this challenge will keep you feeling revitalized as you fuel your body with the essential element it craves. Think you’re up for it? Let\'s see if you can drink only water for two weeks straight—no sugary drinks, no teas, no coffee. Just clean, delicious H2O!';
    case 1:
      return 'Tea lovers, unite! It\'s time to steep your way to hydration and wellness. For the next 14 days, your mission is simple: enjoy at least 12 oz of tea every day. Whether it’s a cozy mug of herbal tea to wind down at night or an invigorating green tea to kickstart your morning, this challenge will help you embrace tea\'s calming and health-boosting properties. Let’s brew up some healthy habits—one cup at a time!';
    case 2:
      return 'Think you can cut the buzz? For the next 14 days, challenge yourself to reduce your caffeine intake and feel the difference! Whether you\'re a coffee connoisseur or a soda sipper, this challenge will have you sipping smart by limiting your caffeine to no more than 55mg a day. Say goodbye to the jitters and hello to better energy balance. Ready to kick the habit and take control of your caffeine intake?';
    case 3:
      return 'Ready to sweeten your health by cutting out the sugar? The Sugar-Free Sips Challenge will put your willpower to the test by eliminating sugary drinks for 14 days. From sodas and milkshakes to sports drinks and energy drinks, it\'s time to ditch the sugar and embrace cleaner, healthier hydration options. Whether you’re reaching for water, unsweetened tea, or naturally flavored sparkling water, this challenge will have you sipping smart and sugar-free!';
    case 4:
      return 'Ready to switch things up? For the next 14 days, we’re shaking things up with the Dairy-Free Refresh Challenge! Whether it’s your morning coffee, smoothie, or a simple glass of milk, the goal is to replace all dairy-based drinks with a dairy-free alternative. Think creamy oat milk lattes, refreshing almond milk smoothies, or coconut milk in your favorite recipes. This challenge is all about exploring delicious, plant-based options while reaping the benefits of a dairy-free diet. Ready to refresh your routine?';
    case 5:
      return 'Time to boost your beverage game with a burst of essential nutrients! For the next 14 days, the Vitamin Vitality Challenge invites you to nourish your body by drinking at least 12 oz of a vitamin- or mineral-rich beverage daily. Whether it\'s a refreshing smoothie packed with fruits and veggies, a vitamin-enhanced drink, or a freshly made juice, this challenge is all about getting your daily dose of vitamins and minerals in a delicious way. Get ready to drink to your health and vitality!';
    default:
      return 'Challenge details';
  }
}

String getChallengeDetails(int index) {
  switch (index) {
    case 0:
      return 'Your mission, should you choose to accept it, is to drink nothing but water (including regular, sparkling, and coconut water) for 14 days. Say goodbye to sodas, teas, coffee, and anything else that’s not pure water. Stay hydrated and keep your goals in sight! Track your daily progress as you sip your way to healthier habits. At the end of each day, log your water intake and celebrate staying on track. Complete this challenge, and you\'ll not only feel a sense of accomplishment but also see some noticeable benefits to your body and mind.';
    case 1:
      return 'For 14 days, drink at least 12 oz of tea each day. You can mix and match different types of tea, like green tea, black tea, or herbal teas—just keep it simple and healthy! Experiment with loose leaf or bagged teas, hot or iced, as long as you hit your 12 oz goal. Track your progress daily and explore the unique flavors and benefits each tea has to offer. Avoid sugary additives to keep this challenge focused on wellness. Whether you sip in the morning or throughout the day, make it a mindful moment to boost your hydration.';
    case 2:
      return 'For the next 14 days, the goal is to keep your caffeine consumption under 55mg per day. That’s about half a cup of coffee or one small cup of tea! You’ll need to skip the energy drinks, cut down on coffee, and be mindful of sneaky sources of caffeine like chocolate or certain sodas. Track your progress every day as you wean off the caffeine and discover the benefits of low-caffeine living. Stay hydrated with caffeine-free alternatives like herbal teas or water, and see how your energy levels naturally adjust.';
    case 3:
      return 'For 14 days, avoid all sugary beverages. That means no milkshakes, sodas, energy drinks, or sports drinks! Your mission is to keep your drinks healthy and sugar-free, opting for water, tea, or other unsweetened alternatives. You’ll be surprised at how much sugar can sneak into your favorite beverages, so keep an eye on labels and log your progress every day. The goal is to cut down on empty calories and reduce sugar intake, all while staying refreshed and hydrated with cleaner choices.';
    case 4:
      return 'For 14 days, drink at least 12 oz of a dairy-free milk alternative every day. Whether you\'re using oat milk in your coffee, almond milk in your smoothie, or coconut milk for a post-workout shake, the idea is to explore and enjoy non-dairy beverages. Your daily drink can be a replacement for any milk-based drink, from lattes to milkshakes. Track your daily intake and discover how easy and delicious it is to go dairy-free with your favorite drinks!';
    case 5:
      return 'For 14 days, make it a goal to drink at least 12 oz of a vitamin- or mineral-rich beverage every day. Whether it\'s a refreshing smoothie packed with spinach and kale, a vitamin-enhanced drink, or a freshly made juice rich in Vitamin C, the choice is yours! Track your progress daily and experiment with nutrient-packed drink options that help you stay hydrated while boosting your health. Focus on beverages that are naturally rich in vitamins and minerals, and be mindful of added sugars to keep things clean and wholesome.';
    default:
      return 'Challenge details';
  }
}

String getHealthFactoids(int index) {
  switch (index) {
    case 0:
      return '• Drinking only water helps flush out toxins, keeping your kidneys happy and functioning efficiently (Harvard T.H. Chan School of Public Health, 2020).\n• Studies show that water plays a key role in boosting metabolism, aiding digestion, and even promoting healthy skin (Mayo Clinic, 2021).\n• Hydration with just water can help improve focus and reduce fatigue, especially when you\'re avoiding caffeinated beverages (Cleveland Clinic, 2022).';
    case 1:
      return '• Green tea contains catechins, a type of antioxidant that may help with fat burning and improving brain function (Healthline, 2023).\n• Regular tea consumption, especially of black and green tea, is associated with a reduced risk of heart disease and stroke (American Heart Association, 2022).\n• Herbal teas like chamomile can promote relaxation and help reduce anxiety and stress levels (National Institutes of Health, 2021).';
    case 2:
      return '• Cutting back on caffeine can help improve your sleep quality, making it easier to fall asleep and stay asleep throughout the night (Mayo Clinic, 2023).\n• Reducing caffeine may lower your risk of anxiety, as high caffeine intake can contribute to nervousness, restlessness, and increased heart rate (Cleveland Clinic, 2021).\n• Lowering caffeine intake can also help stabilize energy levels throughout the day, avoiding the highs and crashes often associated with caffeine consumption (National Institutes of Health, 2022).';
    case 3:
      return '• Drinking sugary beverages regularly has been linked to an increased risk of weight gain and obesity, as well as type 2 diabetes (Harvard T.H. Chan School of Public Health, 2021).\n• Cutting sugary drinks from your diet can help improve heart health by lowering your risk of high blood pressure and reducing bad cholesterol levels (American Heart Association, 2022).\n• Replacing sugary drinks with water or unsweetened options can help stabilize your blood sugar levels and improve overall energy throughout the day (Centers for Disease Control and Prevention, 2022).';
    case 4:
      return '• Dairy-free milk alternatives like almond, oat, and coconut milk are often lower in calories and fat than traditional dairy, making them a lighter, healthier option (Harvard Medical School, 2020).\n• Many plant-based milks are fortified with calcium, vitamin D, and vitamin B12, offering similar nutritional benefits to dairy milk without lactose or cholesterol (National Institutes of Health, 2021).\n• For those who are lactose intolerant, dairy-free alternatives can help prevent digestive issues like bloating, gas, or discomfort, while still providing hydration and nutrients (Mayo Clinic, 2022).';
    case 5:
      return '• Vitamin C, found in juices like orange or grapefruit, supports immune function and helps the body absorb iron from plant-based foods (National Institutes of Health, 2022).\n• Smoothies that incorporate leafy greens like spinach or kale are a great source of essential vitamins like Vitamin A, which supports eye health, and Vitamin K, which helps with blood clotting (Harvard T.H. Chan School of Public Health, 2021).\n• Drinking vitamin- and mineral-rich beverages can help bridge nutrient gaps in your diet, especially for nutrients like potassium and magnesium, which are essential for heart health and muscle function (Cleveland Clinic, 2022).';
    default:
      return 'Health factoids';
  }
}

Color _getChallengeColor(int index) {
  switch (index) {
    case 0:
      return Colors.blue[400]!;
    case 1:
      return Colors.green[400]!;
    case 2:
      return Colors.brown[400]!;
    case 3:
      return Colors.red[400]!;
    case 4:
      return Colors.orange[400]!;
    case 5:
      return Colors.purple[400]!;
    default:
      return Colors.blueAccent[400]!;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool showCups = false; // Toggle between oz and cups
  late AnimationController _controller;
  Timer? _entryTimer;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: false);

    // Load water data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchWaterDataFromFirestore(); // Fetch water data from Firestore
      _initializeEntryTimer();
      setState(() {});
    });
  }

  Future<void> _fetchWaterDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final waterTracker = context.read<WaterTracker>();
          waterTracker.waterConsumed = data['waterConsumed'];
          waterTracker.waterGoal = data['waterGoal'];
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _entryTimer?.cancel();
    super.dispose();
  }

  // Convert ounces to cups (1 cup = 8 oz)
  double get waterConsumedInCups =>
      context.watch<WaterTracker>().waterConsumed / 8;

  double get waterGoalInCups => context.watch<WaterTracker>().waterGoal / 8;

  @override
  Widget build(BuildContext context) {
    // Pull the water tracker data from the provider
    final waterTracker = Provider.of<WaterTracker>(context);

    final waterGoal = (waterTracker.waterGoal).toInt();
    final waterGoalCups = (waterTracker.waterGoal / 8).toInt();

    final waterConsumed = (waterTracker.waterConsumed).toInt();
    return Scaffold(
      body: Stack(
        children: [
          // Background cup shape containing the water animation
          Positioned.fill(
            child: Center(
              child: ClipPath(
                clipper: CupClipper(), // Custom cup shape
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.83,
                  height: MediaQuery.of(context).size.height * 0.7,
                  color: Colors.transparent,
                  child: AnimatedWave(
                    controller: _controller,
                    height:
                        (waterTracker.waterConsumed / waterTracker.waterGoal) *
                            100,
                    totalWidth: MediaQuery.of(context).size.width *
                        0.8, // Match width of cup
                  ),
                ),
              ),
            ),
          ),
          // Overlay cup image
          Positioned.fill(
            child: Center(
              child: Image.asset(
                'lib/assets/images/cup.png', // Path to your cup image
                fit: BoxFit
                    .contain, // Ensure the image fits within the container
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                opacity: AlwaysStoppedAnimation(0.95), // Slightly transparent
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      showCups = !showCups; // Toggle view on tap
                    });
                  },
                  child: Consumer<WaterTracker>(
                    builder: (context, tracker, child) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 100),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return ScaleTransition(
                              scale: animation, child: child);
                        },
                        child: Text(
                          // Display the water consumed in cups or ounces
                          showCups
                              ? '${waterConsumedInCups.toStringAsFixed(0)} cups'
                              : '${tracker.waterConsumed.toStringAsFixed(0)} oz',
                          key: ValueKey(showCups),
                          style: GoogleFonts.cherryBombOne(
                            fontSize: 48,
                            color: showCups
                                ? Colors.green
                                : const Color(0xFF36708B),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<WaterTracker>(
                  builder: (context, tracker, child) {
                    return waterTracker.goalMetToday
                        ? const SizedBox.shrink()
                        : Text(
                            // display the amount of ounces to go or cups to go when compared to the waterGoal value form WaterTracker provider
                            showCups
                                ? '${(waterGoalCups - waterConsumedInCups).toStringAsFixed(0)} cups to go!'
                                : '${(waterGoal - waterConsumed).toStringAsFixed(0)} oz to go!',
                            style: GoogleFonts.cherryBombOne(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          );
                  },
                ),
                AnimatedOpacity(
                  opacity: _remainingTime > 0 ? 1 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Next entry available in:',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      Text(
                        '${_remainingTime ~/ 60}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _remainingTime == 0
          ? FloatingActionButton(
              onPressed: () {
                _showDrinkSelectionSheet(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(
                    bottom: 4.0), // Raise the text slightly
                child: Text(
                  '+',
                  style: GoogleFonts.cherryBombOne(
                    fontSize: 26,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showDrinkSelectionSheet(BuildContext context) {
    final waterTracker = context.read<WaterTracker>();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DrinkSelectionBottomSheet(
          onDrinkSelected: (String drinkName, double drinkWaterRatio) {
            Navigator.pop(context); // Close the bottom sheet after selection
            if (waterTracker.activeChallengeIndex == 2 &&
                drinkName.contains('Caffeine')) {
              _showCaffeineConfirmation(context, drinkName, drinkWaterRatio);
            } else {
              _showDrinkAmountSlider(context, drinkName, drinkWaterRatio);
            }
          },
          activeChallengeIndex: waterTracker.activeChallengeIndex,
        );
      },
    );
  }

  void _showCaffeineConfirmation(
      BuildContext context, String drinkName, double drinkWaterRatio) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Caffeine Intake'),
          content: Text(
              'Will this beverage keep you under 55mg of caffeine for the day?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDrinkAmountSlider(context, drinkName, drinkWaterRatio);
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDrinkSelectionSheet(context);
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _showDrinkAmountSlider(
      BuildContext context, String drinkName, double drinkWaterRatio) {
    final drinkIcon = _getDrinkIcon(drinkName); // Get the icon for the drink
    final drinkColor = _getDrinkColor(drinkName); // Get the color for the drink

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DrinkAmountSlider(
          drinkName: drinkName,
          drinkWaterRatio: drinkWaterRatio,
          drinkIcon: drinkIcon, // Pass the icon to the slider
          drinkColor: drinkColor, // Pass the color to the slider
          onConfirm: (double waterIntake) {
            _incrementWaterConsumed(waterIntake);
            logDrink(context, drinkName, waterIntake, drinkWaterRatio * 100);
            Navigator.pop(context);
            _startEntryTimer();
            if (!context.read<WaterTracker>().goalMetToday) {
              context.read<WaterTracker>().checkGoalMet(context);
            }
          },
        );
      },
    );
  }

  IconData _getDrinkIcon(String drinkName) {
    // Map drink names to their respective icons
    const drinkIcons = {
      'Water': Icons.water_drop_rounded,
      'Sparkling Water': Icons.bubble_chart_rounded,
      'Coconut Water': Icons.beach_access_rounded,
      'Black Tea': Icons.local_cafe_rounded,
      'Green Tea': Icons.eco_rounded,
      'Herbal Tea': Icons.spa_rounded,
      'Matcha': Icons.grass_rounded,
      'Juice': Icons.local_bar_rounded,
      'Lemonade': Icons.wb_sunny_rounded,
      'Milk': Icons.local_drink_rounded,
      'Skim Milk': Icons.local_drink_outlined,
      'Almond Milk': Icons.nature_rounded,
      'Oat Milk': Icons.grain_rounded,
      'Soy Milk': Icons.emoji_nature_rounded,
      'Yogurt': Icons.icecream_rounded,
      'Milkshake': Icons.blender_rounded,
      'Energy Drink': Icons.bolt_rounded,
      'Coffee': Icons.coffee_maker_rounded,
      'Decaf Coffee': Icons.coffee_rounded,
      'Latte': Icons.local_cafe_rounded,
      'Hot Chocolate': Icons.coffee_rounded,
      'Soda': Icons.sports_bar_rounded,
      'Diet Soda': Icons.no_drinks_rounded,
      'Smoothie': Icons.blender_rounded,
      'Sports Drink': Icons.sports_handball_rounded,
      'Protein Shake': Icons.fitness_center_rounded,
      'Soup': Icons.ramen_dining_rounded,
    };
    return drinkIcons[drinkName] ?? Icons.local_drink;
  }

  Color _getDrinkColor(String drinkName) {
    // Map drink names to their respective colors
    var drinkColors = {
      'Water': Colors.blue[700] ?? Colors.blue,
      'Sparkling Water': Colors.cyan[700] ?? Colors.cyan,
      'Coconut Water': Colors.teal[600] ?? Colors.teal,
      'Black Tea': Colors.brown[800] ?? Colors.brown,
      'Green Tea': Colors.green[700] ?? Colors.green,
      'Herbal Tea': Colors.lightGreen[700] ?? Colors.lightGreen,
      'Matcha': Colors.greenAccent[700] ?? Colors.greenAccent,
      'Juice': Colors.orange[700] ?? Colors.orange,
      'Lemonade': Colors.yellow[800] ?? Colors.yellow,
      'Milk': Colors.blueGrey[300] ?? Colors.blueGrey,
      'Skim Milk': Colors.indigo[300] ?? Colors.indigo,
      'Almond Milk': Colors.pink[400] ?? Colors.pink,
      'Oat Milk': Colors.brown[400] ?? Colors.brown,
      'Soy Milk': Colors.amber[400] ?? Colors.amber,
      'Yogurt': Colors.deepOrange[400] ?? Colors.deepOrange,
      'Milkshake': Colors.purple[600] ?? Colors.purple,
      'Energy Drink': Colors.red[700] ?? Colors.red,
      'Coffee': Colors.brown[700] ?? Colors.brown,
      'Decaf Coffee': Colors.brown[600] ?? Colors.brown,
      'Latte': Colors.brown[500] ?? Colors.brown,
      'Hot Chocolate': Colors.deepOrange[700] ?? Colors.deepOrange,
      'Soda': Colors.redAccent[700] ?? Colors.redAccent,
      'Diet Soda': Colors.pink[700] ?? Colors.pink,
      'Smoothie': Colors.purple[700] ?? Colors.purple,
      'Sports Drink': Colors.blue[800] ?? Colors.blue,
      'Protein Shake': Colors.orangeAccent[700] ?? Colors.orangeAccent,
      'Soup': Colors.redAccent[800] ?? Colors.redAccent,
    };
    return drinkColors[drinkName] ?? Colors.grey;
  }

  void _startEntryTimer() async {
    final nextEntryTime = DateTime.now().add(const Duration(minutes: 15));
    context.read<WaterTracker>().nextEntryTime = nextEntryTime;
    await context.read<WaterTracker>().saveWaterData();

    setState(() {
      _remainingTime = 15 * 60; // 15 minutes in seconds
    });

    _entryTimer?.cancel();
    _entryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  void _initializeEntryTimer() async {
    final nextEntryTime = context.read<WaterTracker>().nextEntryTime;
    if (nextEntryTime != null) {
      final remainingDuration =
          nextEntryTime.difference(DateTime.now()).inSeconds;
      if (remainingDuration > 0) {
        setState(() {
          _remainingTime = remainingDuration;
        });

        _entryTimer?.cancel();
        _entryTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (mounted) {
            setState(() {
              if (_remainingTime > 0) {
                _remainingTime--;
              } else {
                timer.cancel();
              }
            });
          }
        });
      }
    }
  }

  void _incrementWaterConsumed(double amount) async {
    // Debug log
    print('Calling incrementWaterConsumed with amount: $amount');
    context.read<WaterTracker>().incrementWaterConsumed(amount);
    context.read<WaterTracker>().checkGoalMet(context); // Check if goal is met
  }

  void _resetEntryTimer() {
    setState(() {
      _remainingTime = 0;
      context.read<WaterTracker>().nextEntryTime = null;
    });
  }

  void logDrink(BuildContext context, String drinkName, double amount,
      double waterContent) async {
    final log = WaterLog(
      drinkName: drinkName,
      amount: amount,
      waterContent: waterContent,
      entryTime: DateTime.now(),
    );

    context.read<WaterTracker>().addLog(log);

    // Increment record streak after user makes an entry
    final waterTracker = context.read<WaterTracker>();
    if (waterTracker.currentStreak > waterTracker.recordStreak) {
      waterTracker.recordStreak = waterTracker.currentStreak;
    }

    // Send log to Firebase
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;
      final logData = {
        'drinkName': drinkName,
        'amount': amount,
        'waterContent': waterContent,
        'entryTime': log.entryTime.toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('waterLogs')
          .add(logData);

      // Update Firestore with the new water consumption
      await waterTracker.updateFirestore();
    }
  }
}

class CupClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    double cupWidth = size.width;
    double cupHeight = size.height;

    // Start from the left side at the bottom of the glass (a bit rounded)
    path.moveTo(cupWidth * 0.1, cupHeight * 0.95);

    // Create a curved rim at the bottom (like the rim of a drinking glass)
    path.quadraticBezierTo(
      cupWidth * 0.5, cupHeight * 1.05, // Peak of the curve (center of the rim)
      cupWidth * 0.9, cupHeight * 0.95, // Right end of the rim
    );

    // Draw the right side of the glass (slightly outward at the top)
    path.lineTo(cupWidth * 1, cupHeight * 0.05);

    // Flatten the top of the cup
    path.lineTo(cupWidth * 0, cupHeight * 0.05);

    // Draw the left side of the glass (tapering down to the rim)
    path.lineTo(cupWidth * 0.1, cupHeight * 0.9);

    path.close(); // Complete the path

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false; // No need to reclip unless the shape changes dynamically
  }
}

class AnimatedWave extends StatefulWidget {
  final AnimationController controller;
  final double height;
  final double totalWidth;

  const AnimatedWave(
      {super.key,
      required this.controller,
      required this.height,
      required this.totalWidth});

  @override
  _AnimatedWaveState createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<AnimatedWave> {
  late double _currentHeight;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.height;
  }

  @override
  void didUpdateWidget(covariant AnimatedWave oldWidget) {
    if (oldWidget.height != widget.height) {
      setState(() {
        _currentHeight = widget.height;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(
            widget.controller.value,
            _currentHeight,
            widget.totalWidth,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final double height;
  final double totalWidth;

  WavePainter(this.animationValue, this.height, this.totalWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [
          Colors.blue.withOpacity(0.15),
          Colors.blue.withOpacity(0.6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, totalWidth, size.height));

    final path = Path();
    const waveHeight = 15.0;
    final baseHeight = size.height * (1 - height / 100) +
        50; // Lower the base height by 40 pixels

    path.moveTo(0, baseHeight);
    for (double i = 0; i <= totalWidth; i++) {
      path.lineTo(
        i,
        baseHeight -
            waveHeight *
                sin((i / totalWidth * 2 * pi) + (animationValue * 2 * pi)),
      );
    }
    path.lineTo(totalWidth, size.height); // Extend to totalWidth
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return true;
  }
}

class DrinkSelectionBottomSheet extends StatelessWidget {
  final Function(String, double) onDrinkSelected;

  const DrinkSelectionBottomSheet(
      {super.key, required this.onDrinkSelected, int? activeChallengeIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      //scrollbar
      padding: const EdgeInsets.all(16.0),
      height: 475,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'What did you drink?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true, // Makes the scrollbar always visible
              child: GridView.count(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 10),
                shrinkWrap: true,
                primary: false,
                childAspectRatio: 1.2,
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 2,
                children: _buildDrinkItems(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrinkItems(BuildContext context) {
    final drinks = [
      // Waters
      {
        'name': 'Water',
        'icon': Icons.water_drop_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.blue[700] ?? Colors.blue
      },
      {
        'name': 'Sparkling Water',
        'icon': Icons.bubble_chart_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.cyan[700] ?? Colors.cyan
      },
      {
        'name': 'Coconut Water',
        'icon': Icons.beach_access_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.teal[600] ?? Colors.teal
      },
      // Teas
      {
        'name': 'Black Tea',
        'icon': Icons.local_cafe_rounded, // Updated to rounded version
        'ratio': 0.9,
        'color': Colors.brown[800] ?? Colors.brown
      },
      {
        'name': 'Green Tea',
        'icon': Icons.eco_rounded, // Updated to rounded version
        'ratio': 0.9,
        'color': Colors.green[700] ?? Colors.green
      },
      {
        'name': 'Herbal Tea',
        'icon': Icons.spa_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.lightGreen[700] ?? Colors.lightGreen
      },
      {
        'name': 'Matcha',
        'icon': Icons.grass_rounded, // Updated to rounded version
        'ratio': 0.9,
        'color': Colors.greenAccent[700] ?? Colors.greenAccent
      },
      // Juices
      {
        'name': 'Juice',
        'icon': Icons.local_bar_rounded, // Updated to rounded version
        'ratio': 0.9,
        'color': Colors.orange[700] ?? Colors.orange
      },
      {
        'name': 'Lemonade',
        'icon': Icons.wb_sunny_rounded, // Updated to rounded version
        'ratio': 0.8,
        'color': Colors.yellow[800] ?? Colors.yellow
      },
      // Milks
      {
        'name': 'Milk',
        'icon': Icons.local_drink_rounded, // Updated to rounded version
        'ratio': 1.5,
        'color': Colors.blueGrey[300] ?? Colors.blueGrey
      },
      {
        'name': 'Skim Milk',
        'icon': Icons.local_drink_outlined, // No rounded version available
        'ratio': 1.5,
        'color': Colors.indigo[300] ?? Colors.indigo
      },
      {
        'name': 'Almond Milk',
        'icon': Icons.nature_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.pink[400] ?? Colors.pink
      },
      {
        'name': 'Oat Milk',
        'icon': Icons.grain_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.brown[400] ?? Colors.brown
      },
      {
        'name': 'Soy Milk',
        'icon': Icons.emoji_nature_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.amber[400] ?? Colors.amber
      },
      // Yogurt
      {
        'name': 'Yogurt',
        'icon': Icons.icecream_rounded, // Updated to rounded version
        'ratio': 1.2,
        'color': Colors.deepOrange[400] ?? Colors.deepOrange
      },
      // Milkshake
      {
        'name': 'Milkshake',
        'icon': Icons.blender_rounded, // Updated to rounded version
        'ratio': 0.8,
        'color': Colors.purple[600] ?? Colors.purple
      },
      // Energy Drinks
      {
        'name': 'Energy Drink',
        'icon': Icons.bolt_rounded, // Updated to rounded version
        'ratio': 0.8,
        'color': Colors.red[700] ?? Colors.red
      },
      // Coffee
      {
        'name': 'Coffee',
        'icon': Icons.coffee_maker_rounded, // Updated to rounded version
        'ratio': 0.9,
        'color': Colors.brown[700] ?? Colors.brown
      },
      {
        'name': 'Decaf Coffee',
        'icon': Icons.coffee_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.brown[600] ?? Colors.brown
      },
      {
        'name': 'Latte',
        'icon': Icons.local_cafe_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.brown[500] ?? Colors.brown
      },
      {
        'name': 'Hot Chocolate',
        'icon': Icons.coffee_rounded, // Updated to rounded version
        'ratio': 0.8,
        'color': Colors.deepOrange[700] ?? Colors.deepOrange
      },
      // Sodas
      {
        'name': 'Soda',
        'icon': Icons.sports_bar_rounded, // Updated to rounded version
        'ratio': 0.8,
        'color': Colors.redAccent[700] ?? Colors.redAccent
      },
      {
        'name': 'Diet Soda',
        'icon': Icons.no_drinks_rounded, // Updated to rounded version
        'ratio': 0.9,
        'color': Colors.pink[700] ?? Colors.pink
      },
      // Smoothies
      {
        'name': 'Smoothie',
        'icon': Icons.blender_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.purple[700] ?? Colors.purple
      },
      // Sports Drinks
      {
        'name': 'Sports Drink',
        'icon': Icons.sports_handball_rounded, // Updated to rounded version
        'ratio': 1.1,
        'color': Colors.blue[800] ?? Colors.blue
      },
      {
        'name': 'Protein Shake',
        'icon': Icons.fitness_center_rounded, // Updated to rounded version
        'ratio': 1.0,
        'color': Colors.orangeAccent[700] ?? Colors.orangeAccent
      },
      // Soup
      {
        'name': 'Soup',
        'icon': Icons.ramen_dining_rounded, // Updated to rounded version
        'ratio': 1.2,
        'color': Colors.redAccent[800] ?? Colors.redAccent
      },
    ];

    return drinks.map((drink) {
      return GestureDetector(
        onTap: () {
          onDrinkSelected(drink['name'] as String, drink['ratio'] as double);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(drink['icon'] as IconData,
                size: 55, color: drink['color'] as Color),
            const SizedBox(height: 5),
            Text(
              drink['name'] as String,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class DrinkAmountSlider extends StatefulWidget {
  final String drinkName;
  final double drinkWaterRatio;
  final IconData drinkIcon; // Add drink icon parameter
  final Color drinkColor; // Add drink color parameter
  final Function(double) onConfirm;

  const DrinkAmountSlider({
    super.key,
    required this.drinkName,
    required this.drinkWaterRatio,
    required this.drinkIcon, // Pass drink icon
    required this.drinkColor, // Pass drink color
    required this.onConfirm,
  });

  @override
  _DrinkAmountSliderState createState() => _DrinkAmountSliderState();
}

class _DrinkAmountSliderState extends State<DrinkAmountSlider> {
  double _sliderValue = 0.0;

  // List of drinks that require a disclaimer
  final List<String> drinksWithDisclaimer = [
    'Energy Drink',
    'Coffee',
    'Soda',
    'Sports Drink',
  ];

  @override
  Widget build(BuildContext context) {
    double waterIntake = _sliderValue * widget.drinkWaterRatio;
    double waterIntakeInCups = waterIntake / 8;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Icon(widget.drinkIcon, size: 45, color: widget.drinkColor),
            const SizedBox(height: 8),
            Text(
              'How much ${widget.drinkName} did you drink?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        Slider(
          value: _sliderValue,
          min: 0,
          max: 40,
          divisions: 40,
          activeColor: widget.drinkColor, // Use the drink color
          label: '${_sliderValue.toStringAsFixed(0)} oz',
          onChanged: (double value) {
            setState(() {
              _sliderValue = value;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black),
              children: [
                const TextSpan(text: 'Equivalent to '),
                TextSpan(
                  text: '${waterIntake.toStringAsFixed(1)} oz',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' ('),
                TextSpan(
                  text: '${waterIntakeInCups.toStringAsFixed(1)} cups',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ') of water.'),
              ],
            ),
          ),
        ),
        // Display disclaimer if the drink is in the list
        if (drinksWithDisclaimer.contains(widget.drinkName))
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Note: ${widget.drinkName} is not entirely beneficial for water drinking habits or general health.',
              style: const TextStyle(fontSize: 14, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(waterIntake);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

class DuckScreen extends StatelessWidget {
  DuckScreen({super.key});

  void _showDuckDetails(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${_duckNames[index]} Details',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _duckPrerequisites[index]!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      },
    );
  }

  final Map<int, String> _duckPrerequisites = {
    0: 'Reach a 5-day streak',
    1: 'Log entries for 7 consecutive days',
    2: 'Reach a 10-day streak',
    3: 'Complete the Nothing But Water challenge',
    4: 'Log water for 14 consecutive days',
    5: 'Reach a 20-day streak',
    6: 'Complete the Tea Time challenge',
    7: 'Log water for 21 consecutive days',
    8: 'Reach a 30-day streak',
    9: 'Complete the Caffine Cut challenge',
    10: 'Log water for 28 consecutive days',
    11: 'Reach a 60-day streak',
    12: 'Complete the Sugar-Free Sips challenge',
    13: 'Log water for 35 consecutive days',
    14: 'Reach a 120-day streak',
    15: 'Complete the Dairy-Free Refresh challenge',
    16: 'Log water for 50 consecutive days',
    17: 'Reach a 365-day streak',
    18: 'Complete the Vitamin Vitality challenge',
    19: 'Drink 100 oz of water',
    20: 'Drink 300 oz of water',
    21: 'Drink 1000 oz of water',
    22: 'Drink 3000 oz of water',
    23: 'Drink 10,000 oz of water',
  };

  final List<String> _duckNames = [
    '5-Day Streak', //
    'Logger',
    '10-Day Streak',
    'Water Purist',
    '2-Week Logger',
    '20-Day Streak',
    'Tea Enthusiast',
    '3-Week Logger',
    '30-Day Streak',
    'Caffeine Cutter',
    '4-Week Logger',
    '60-Day Streak',
    'Sugar-Free Sipper',
    '5-Week Logger',
    '120-Day Streak',
    'Dairy-Free Drinker',
    '50-Day Logger',
    'Yearly Streak',
    'Vitamin Vitality',
    '100 oz Drinker',
    '300 oz Drinker',
    '1000 oz Drinker',
    '3000 oz Drinker',
    '10,000 oz Drinker',
  ];

  bool _isDuckUnlocked(BuildContext context, int index) {
    final waterTracker = context.read<WaterTracker>();
    switch (index) {
      case 0:
        return waterTracker.waterConsumed >= 100;
      case 1:
        return waterTracker.completedChallenges >= 5;
      case 2:
        return waterTracker.recordStreak >= 7;
      case 3:
        return waterTracker.currentStreak >= 10;
      case 4:
        return waterTracker.waterConsumed >= 200;
      case 5:
        return waterTracker.completedChallenges >= 10;
      case 6:
        return waterTracker.currentStreak >= 14;
      case 7:
        return waterTracker.currentStreak >= 20;
      case 8:
        return waterTracker.waterConsumed >= 300;
      case 9:
        return waterTracker.completedChallenges >= 15;
      case 10:
        return waterTracker.currentStreak >= 21;
      case 11:
        return waterTracker.currentStreak >= 30;
      case 12:
        return waterTracker.waterConsumed >= 400;
      case 13:
        return waterTracker.completedChallenges >= 20;
      case 14:
        return waterTracker.currentStreak >= 28;
      case 15:
        return waterTracker.currentStreak >= 40;
      case 16:
        return waterTracker.waterConsumed >= 500;
      case 17:
        return waterTracker.completedChallenges >= 25;
      case 18:
        return waterTracker.currentStreak >= 35;
      case 19:
        return waterTracker.currentStreak >= 50;
      case 20:
        return waterTracker.waterConsumed >= 600;
      case 21:
        return waterTracker.completedChallenges >= 30;
      case 22:
        return waterTracker.currentStreak >= 42;
      case 23:
        return waterTracker.currentStreak >= 60;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ducks',
          style: GoogleFonts.cherryBombOne(),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Scrollbar(
        thumbVisibility: true, // Makes the scrollbar always visible
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Adds bouncing effect
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 24, // Number of ducks
              itemBuilder: (context, index) {
                final isUnlocked = _isDuckUnlocked(context, index);
                return GestureDetector(
                  onTap: () {
                    _showDuckDetails(
                        context, index); // Trigger bottom sheet on tap
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isUnlocked
                            ? [Colors.blueAccent, Colors.lightBlueAccent]
                            : [Colors.blue.shade400, Colors.blue.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          isUnlocked
                              ? Image.asset(
                                  'lib/assets/images/wade_flying.png',
                                  width: 80,
                                  height: 80,
                                )
                              : const Icon(Icons.lock,
                                  size: 45,
                                  color: Colors.black), // Display a silhouette
                          const SizedBox(height: 8),
                          Text(
                            _duckNames[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final ScreenshotController screenshotController;

  const ProfileScreen({super.key, required this.screenshotController});

  @override
  Widget build(BuildContext context) {
    final waterTracker = context.watch<WaterTracker>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.cherryBombOne(),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Screenshot(
                controller: screenshotController,
                child: Column(
                  children: [
                    // Profile image and username with gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: waterTracker.profileImage != null
                              ? [Colors.blueAccent, Colors.lightBlueAccent]
                              : [Colors.blue.shade400, Colors.blue.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Change Profile Avatar'),
                                    content: const Text(
                                        'Would you like to change your profile avatar image?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final ImagePicker picker =
                                              ImagePicker();
                                          final XFile? image =
                                              await picker.pickImage(
                                                  source: ImageSource.gallery);
                                          if (image != null) {
                                            final user = FirebaseAuth
                                                .instance.currentUser;
                                            if (user != null) {
                                              final uid = user.uid;
                                              final imagePath = image.path;
                                              await context
                                                  .read<WaterTracker>()
                                                  .updateProfileImage(
                                                      imagePath);

                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(uid)
                                                  .update({
                                                'profileImage': imagePath
                                              });

                                              rebuildUI(context);
                                            }
                                          }
                                        },
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: waterTracker.profileImage != null
                                  ? FileImage(File(waterTracker.profileImage!))
                                  : null,
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              child: waterTracker.profileImage == null
                                  ? Image.asset(
                                      'lib/assets/images/wade_sitting_looking_up.png')
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .get(),
                            builder: (context, snapshot) {
                              return AnimatedOpacity(
                                opacity: snapshot.connectionState ==
                                        ConnectionState.done
                                    ? 1.0
                                    : 0.0,
                                duration: const Duration(milliseconds: 500),
                                child: Text(
                                  snapshot.hasData && snapshot.data != null
                                      ? (snapshot.data?.data() as Map<String,
                                              dynamic>)['username'] ??
                                          'No username found'
                                      : 'No username found',
                                  style: TextStyle(
                                    fontSize: snapshot.hasData &&
                                            snapshot.data != null &&
                                            (snapshot.data?.data() as Map<
                                                    String,
                                                    dynamic>)['username'] !=
                                                null &&
                                            (snapshot.data?.data() as Map<
                                                        String,
                                                        dynamic>)['username']
                                                    .length >
                                                10
                                        ? 18.0
                                        : 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // User's current streak, record streak, challenges, companions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: _buildStatisticCard(
                              icon: Icons.opacity,
                              label: 'Current Streak',
                              value: '${waterTracker.currentStreak}',
                              color: Colors.lightBlueAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: _buildStatisticCard(
                              icon: Icons.star,
                              label: 'Record Streak',
                              value: '${waterTracker.recordStreak}',
                              color: Colors.amber[300] ?? Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: _buildStatisticCard(
                              icon: Icons.check_circle,
                              label: 'Challenges',
                              value: '${waterTracker.completedChallenges}',
                              color: Colors.greenAccent,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: _buildStatisticCard(
                              icon: Icons.emoji_nature,
                              label: 'Ducks',
                              value: '${waterTracker.companionsCollected}',
                              color: Colors.purpleAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // List of options with trailing icons
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.share,
                      label: 'Share Profile',
                      onTap: () async {
                        final image = await screenshotController.capture();
                        if (image != null) {
                          final directory = await path_provider
                              .getApplicationDocumentsDirectory();
                          final imagePath =
                              '${directory.path}/profile_screenshot.png';
                          final imageFile = File(imagePath);
                          await imageFile.writeAsBytes(image);
                          await waterTracker.shareProfileScreenshot(imagePath);
                        }
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.edit,
                      label: 'Edit Daily Water Goal',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Change Water Goal'),
                              content: const Text(
                                  'Changing your water goal will reset your progress for the day. Are you sure you want to continue?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);

                                    context
                                        .read<WaterTracker>()
                                        .resetWater(); // Reset water consumed to 0
                                    context
                                        .read<WaterTracker>()
                                        .resetEntryTimer(); // Reset entry timer
                                    Navigator.pushReplacementNamed(
                                        context, '/questions');
                                  },
                                  child: const Text('Continue'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.notifications,
                      label: 'Goal Reminders/Notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildOptionTile(
                      icon: Icons.settings,
                      label: 'Settings',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

extension on Uint8List {
  Null get path => null;
}
