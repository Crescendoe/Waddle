import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterly/screens/questions_screen.dart';
import 'package:waterly/screens/settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2; // Set default index to 2
  final PageController _pageController =
      PageController(initialPage: 2); // Set initial page to 2

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: AnimatedWave(
                  controller: _waveController,
                  height: // Get the water consumed percentage
                      (context.watch<WaterTracker>().waterConsumed /
                              context.watch<WaterTracker>().waterGoal) *
                          100,
                  totalWidth: MediaQuery.of(context).size.width * 5,
                ),
              ),
              // PageView in the foreground
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
                  HomeScreen(),
                  DuckScreen(),
                  ProfileScreen(),
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
                    icon: Icons.calendar_today,
                    label: 'Streaks',
                    index: 0,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.emoji_events,
                    label: 'Challenges',
                    index: 1,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 2,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.pets,
                    label: 'Ducks',
                    index: 3,
                  ),
                  _buildBottomNavItem(
                    icon: Icons.person,
                    label: 'Profile',
                    index: 4,
                  ),
                ],
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

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

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  _StreakScreenState createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  Map<DateTime, bool> _loggedDays = {};
  int _currentStreak = 0;
  int _calculateCurrentStreak() {
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime currentDay = DateTime(today.year, today.month, today.day);

    while (_loggedDays[currentDay] == true) {
      streak++;
      currentDay = currentDay.subtract(const Duration(days: 1));
    }

    return streak;
  }

  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLoggedDays();
    _loadWaterLogsFromFirebase();
  }

  Future<void> _loadLoggedDays() async {
    final user = context.read<User>(); // Assuming you have a User provider
    final userId = user.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
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
      _currentStreak = _calculateCurrentStreak();
    });
  }

  Future<void> _loadWaterLogsFromFirebase() async {
    final user = context.read<User>(); // Assuming you have a User provider
    final userId = user.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
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

    context.read<WaterTracker>().setLogs(logs);
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
    var now = _currentDate;
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
                    const Icon(Icons.arrow_back_ios, color: Colors.blueAccent),
                onPressed: () {
                  setState(() {
                    final previousMonth = DateTime(now.year, now.month - 1, 1);
                    _currentDate = previousMonth;
                  });
                },
              ),
            Text(
              '${_getMonthName(now.month)} ${now.year}',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            if (now.year < 2099 || (now.year == 2099 && now.month < 12))
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.blueAccent),
                onPressed: () {
                  setState(() {
                    final nextMonth = DateTime(now.year, now.month + 1, 1);
                    _currentDate = nextMonth;
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
            final isSelected = day.year == _currentDate.year &&
                day.month == _currentDate.month &&
                day.day == _currentDate.day;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentDate = day;
                  _showWaterLog(context, day);
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
                            color: isToday ? Colors.blueAccent : Colors.black,
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
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
    // Placeholder logic
    return true;
  }

  void _showWaterLog(BuildContext context, DateTime day) {
    final logs = context.read<WaterTracker>().getLogsForDay(day);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(25.0)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 5)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '${_getMonthName(day.month)} ${day.day}, ${day.year}',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No entries for this day',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16.0),
                              leading: CircleAvatar(
                                backgroundColor: log.drinkName == 'Soda'
                                    ? Colors.brown
                                    : log.drinkName == 'Energy Drink'
                                        ? Colors.red
                                        : log.drinkName == 'Tea'
                                            ? Colors.green
                                            : log.drinkName == 'Smoothie'
                                                ? Colors.purple
                                                : log.drinkName == 'Milk'
                                                    ? Colors.white
                                                    : log.drinkName ==
                                                            'Orange Juice'
                                                        ? Colors.orange
                                                        : log.drinkName ==
                                                                'Water'
                                                            ? Colors.blueAccent
                                                            : Colors.grey,
                                child: Icon(
                                  Icons.local_drink,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(log.drinkName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Amount: ${log.amount} oz\nWater Content: ${log.waterContent}%'),
                              trailing: Text(
                                _formatTime(log.entryTime),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaks'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Current Streak: $_currentStreak days',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildCalendar()),
          ],
        ),
      ),
    );
  }
}

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 15,
            childAspectRatio: 2, // Make each box a rectangle
          ),
          itemCount: 6, // Number of challenge boxes
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
                decoration: BoxDecoration(
                  color: _getChallengeColor(index),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          const SizedBox(height: 4),
                          Text(
                            getChallengeTitle(index),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _getChallengeIcon(index),
                        size: 70,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static String getChallengeTitle(int index) {
    switch (index) {
      case 0:
        return 'Nothing But Water';
      case 1:
        return 'Tea Challenge';
      case 2:
        return 'Caffeine Challenge';
      case 3:
        return 'Sugar Challenge';
      case 4:
        return 'Lactose Challenge';
      case 5:
        return 'Vitamin Challenge';
      default:
        return 'Challenge';
    }
  }

  Color _getChallengeColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.green;
      case 2:
        return Colors.brown;
      case 3:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 5:
        return Colors.purple;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _getChallengeIcon(int index) {
    switch (index) {
      case 0:
        return Icons.water;
      case 1:
        return Icons.emoji_food_beverage;
      case 2:
        return Icons.coffee;
      case 3:
        return Icons.cake;
      case 4:
        return Icons.local_drink;
      case 5:
        return Icons.local_hospital;
      default:
        return Icons.local_drink;
    }
  }
}

class ChallengeDetailScreen extends StatelessWidget {
  final int index;

  const ChallengeDetailScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ChallengesScreen.getChallengeTitle(index)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '14 Day Challenge',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getChallengeDescription(index),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _getChallengeDescription(int index) {
    switch (index) {
      case 0:
        return 'The title says it all';
      case 1:
        return 'Drink up the unique benefits of tea you may have not known about';
      case 2:
        return 'Get better sleep, lessen anxiety, and balance your energy levels';
      case 3:
        return 'Ditch beverages that are generally not healthy';
      case 4:
        return 'Discover if dairy-based beverages are or aren\'t for you';
      case 5:
        return 'Enrich yourself with sources of vitamins and minerals';
      default:
        return 'Challenge details';
    }
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: false);

    // Load water data when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<WaterTracker>().loadWaterData();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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

    debugPrint('Water Goal: ${waterTracker.waterGoal}');
    debugPrint('Water Consumed: ${waterTracker.waterConsumed}');

    final waterGoal = (waterTracker.waterGoal).toInt();
    final waterGoalCups = (waterTracker.waterGoal / 8).toInt();

    final waterConsumed = (waterTracker.waterConsumed).toInt();
    final waterConsumedCups = (waterTracker.waterConsumed / 8).toInt();

    return Scaffold(
      body: Stack(
        children: [
          // Background cup shape containing the water animation
          Positioned.fill(
            child: Center(
              child: ClipPath(
                clipper: CupClipper(), // Custom cup shape
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
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
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: showCups ? Colors.green : Colors.blue[700],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Consumer<WaterTracker>(
                  builder: (context, tracker, child) {
                    return Text(
                      // display the amount of ounces to go or cups to go when compared to the waterGoal value form WaterTracker provider
                      showCups
                          ? '${(waterGoalCups - waterConsumedCups).toStringAsFixed(0)} cups to go!'
                          : '${(waterGoal - waterConsumed).toStringAsFixed(0)} oz to go!',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showDrinkSelectionSheet(context);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showDrinkSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DrinkSelectionBottomSheet(
          onDrinkSelected: (String drinkName, double drinkWaterRatio) {
            Navigator.pop(context); // Close the bottom sheet after selection
            _showDrinkAmountSlider(context, drinkName, drinkWaterRatio);
          },
        );
      },
    );
  }

  void _showDrinkAmountSlider(
      BuildContext context, String drinkName, double drinkWaterRatio) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return DrinkAmountSlider(
          drinkName: drinkName,
          drinkWaterRatio: drinkWaterRatio,
          onConfirm: (double waterIntake) {
            _incrementWaterConsumed(waterIntake);
            logDrink(context, drinkName, waterIntake, drinkWaterRatio);
            Navigator.pop(context); // Close the slider sheet after confirmation
          },
        );
      },
    );
  }

  void _incrementWaterConsumed(double amount) {
    double target = context.read<WaterTracker>().waterConsumed + amount;
    int duration = 50;

    void incrementWater() {
      Timer(Duration(milliseconds: duration), () {
        setState(() {
          if (context.read<WaterTracker>().waterConsumed < target &&
              context.read<WaterTracker>().waterConsumed <
                  context.read<WaterTracker>().waterGoal) {
            context.read<WaterTracker>().addWater(1);
            if (context.read<WaterTracker>().waterConsumed > target) {
              context.read<WaterTracker>().setWater(target);
            }
            duration = max((duration * 1.05).toInt(), 20);
            incrementWater();
          } else if (context.read<WaterTracker>().waterConsumed >=
              context.read<WaterTracker>().waterGoal) {
            context
                .read<WaterTracker>()
                .setWater(context.read<WaterTracker>().waterGoal);
            context.read<WaterTracker>().incrementStreak();
            Navigator.pushReplacementNamed(context, '/congrats');
          }
        });
      });
    }

    incrementWater();
  }
}

class CupClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    double cupWidth = size.width;
    double cupHeight = size.height;

    // Start from the left side at the bottom of the glass (a bit rounded)
    path.moveTo(cupWidth * 0.1, cupHeight * 0.9);

    // Create a curved rim at the bottom (like the rim of a drinking glass)
    path.quadraticBezierTo(
      cupWidth * 0.5, cupHeight, // Peak of the curve (center of the rim)
      cupWidth * 0.9, cupHeight * 0.9, // Right end of the rim
    );

    // Draw the right side of the glass (slightly outward at the top)
    path.lineTo(cupWidth * 0.95, cupHeight * 0.15);

    // Create a curved top (a soft U-shape for the base)
    path.quadraticBezierTo(
      cupWidth * 0.5, cupHeight * -0.05, // Lowest point of the base (center)
      cupWidth * 0.05, cupHeight * 0.15, // Left end of the base
    );

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

// CustomPainter to draw the glass border
class GlassBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create a paint object for the border
    Paint borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill
      ..strokeWidth = 3.0; // Thickness of the border

    // Use the CupClipper's path for the glass shape
    Path glassPath = CupClipper().getClip(size);

    // Draw the path with the border paint
    canvas.drawPath(glassPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint unless something changes
  }
}

// Use the CustomClipper and CustomPainter in your widget
class GlassWidget extends StatelessWidget {
  const GlassWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: CupClipper(), // Clip the shape using CupClipper
          child: Container(
            width: 200, // Width of the glass
            height: 400, // Height of the glass
            color: Colors.transparent, // No background color
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: GlassBorderPainter(), // Paint the border of the glass
          ),
        ),
      ],
    );
  }
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

  // Send log to Firebase
  final user = context.read<User>(); // Assuming you have a User provider
  final userID = user.uid;
  final logData = {
    'drinkName': drinkName,
    'amount': amount,
    'waterContent': waterContent,
    'entryTime': log.entryTime.toIso8601String(),
  };

  await FirebaseFirestore.instance
      .collection('users')
      .doc(userID)
      .collection('waterLogs')
      .add(logData);
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
    const waveHeight = 20.0;
    final baseHeight = size.height * (1 - height / 100);

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

  const DrinkSelectionBottomSheet({super.key, required this.onDrinkSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      height: 475,
      child: Column(
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
            child: GridView.count(
              crossAxisCount: 3, // Number of columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 2,
              children: _buildDrinkItems(context),
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
        'icon': Icons.water,
        'ratio': 1.0,
        'color': Colors.blue
      },
      {
        'name': 'Sparkling Water',
        'icon': Icons.bubble_chart,
        'ratio': 1.0,
        'color': Colors.lightBlue
      },
      {
        'name': 'Coconut Water',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.brown
      },
      // Teas
      {
        'name': 'Black Tea',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.black
      },
      {
        'name': 'Green Tea',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.green
      },
      {
        'name': 'Herbal Tea',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.lightGreen
      },
      {
        'name': 'Matcha',
        'icon': Icons.emoji_food_beverage,
        'ratio': 0.9,
        'color': Colors.greenAccent
      },
      // Juices
      {
        'name': 'Juice',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.orange
      },
      {
        'name': 'Lemonade',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.yellow
      },
      // Milks
      {
        'name': 'Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.white
      },
      {
        'name': 'Skim Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.white,
      },
      {
        'name': 'Almond Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.white
      },
      {
        'name': 'Oat Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.white
      },
      {
        'name': 'Soy Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.white
      },
      // Yogurt
      {
        'name': 'Yogurt',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.orangeAccent
      },
      // Milkshake
      {
        'name': 'Milkshake',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.purple
      },
      // Energy Drinks
      {
        'name': 'Energy Drink',
        'icon': Icons.flash_on,
        'ratio': 0.6,
        'color': Colors.red
      },
      // Coffee
      {
        'name': 'Coffee',
        'icon': Icons.coffee,
        'ratio': 0.5,
        'color': Colors.brown
      },
      {
        'name': 'Decaf Coffee',
        'icon': Icons.coffee,
        'ratio': 0.5,
        'color': Colors.brown
      },
      {
        'name': 'Latte',
        'icon': Icons.local_cafe,
        'ratio': 0.5,
        'color': Colors.brown
      },
      {
        'name': 'Hot Chocolate',
        'icon': Icons.local_cafe,
        'ratio': 0.5,
        'color': Colors.brown
      },
      // Sodas
      {
        'name': 'Soda',
        'icon': Icons.local_drink,
        'ratio': 0.4,
        'color': Colors.brown
      },
      {
        'name': 'Diet Soda',
        'icon': Icons.local_drink,
        'ratio': 0.4,
        'color': Colors.brown
      },
      // Smoothies
      {
        'name': 'Smoothie',
        'icon': Icons.blender,
        'ratio': 0.8,
        'color': Colors.purple
      },
      // Sports Drinks
      {
        'name': 'Sports Drink',
        'icon': Icons.sports,
        'ratio': 0.8,
        'color': Colors.blue
      },
      {
        'name': 'Protein Shake',
        'icon': Icons.fitness_center,
        'ratio': 0.8,
        'color': Colors.orangeAccent
      },
      // Soup
      {
        'name': 'Soup',
        'icon': Icons.soup_kitchen,
        'ratio': 0.6,
        'color': Colors.redAccent
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
  final Function(double) onConfirm;

  const DrinkAmountSlider({
    super.key,
    required this.drinkName,
    required this.drinkWaterRatio,
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
        if (widget.drinkName == 'Energy Drink' ||
            widget.drinkName == 'Smoothie' ||
            widget.drinkName == 'Sports Drink')
          Text(
            'How much of the ${widget.drinkName} did you drink?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          )
        else
          Text(
            'How much ${widget.drinkName} did you drink?',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        Slider(
          value: _sliderValue,
          min: 0,
          max: 40,
          divisions: 40,
          label: '${_sliderValue.toStringAsFixed(0)} oz',
          onChanged: (double value) {
            setState(() {
              _sliderValue = value;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '${waterIntake.toStringAsFixed(1)} oz (${waterIntakeInCups.toStringAsFixed(1)} cups of water)',
            style: const TextStyle(fontSize: 16),
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
    0: 'Reach your goal for the first time',
    1: 'Complete 5 challenges',
    2: 'Log water for 7 consecutive days',
    3: 'Reach a 10-day streak',
    4: 'Drink 200 oz of water',
    5: 'Complete 10 challenges',
    6: 'Log water for 14 consecutive days',
    7: 'Reach a 20-day streak',
    8: 'Drink 300 oz of water',
    9: 'Complete 15 challenges',
    10: 'Log water for 21 consecutive days',
    11: 'Reach a 30-day streak',
    12: 'Drink 400 oz of water',
    13: 'Complete 20 challenges',
    14: 'Log water for 28 consecutive days',
    15: 'Reach a 60-day streak',
    16: 'Drink 500 oz of water',
    17: 'Complete 25 challenges',
    18: 'Log water for 35 consecutive days',
    19: 'Reach a 120-day streak',
    20: 'Drink 600 oz of water',
    21: 'Complete 30 challenges',
    22: 'Log water for 42 consecutive days',
    23: 'Reach a 365-day streak',
  };

  final List<String> _duckNames = [
    'Quack Attack',
    'Feathered Friend',
    'Splash Master',
    'Puddle Jumper',
    'Waddle Wizard',
    'Beak Bandit',
    'Feather Fury',
    'Splashy',
    'Waddle Wonder',
    'Pond Hopper',
    'Quackster',
    'Duckling Dynamo',
    'Aqua Quacker',
    'Waddle Warrior',
    'Pond Pal',
    'Splashy Sidekick',
    'Feathered Fury',
    'Quack Commander',
    'Waddle Whiz',
    'Puddle Pal',
    'Beak Boss',
    'Feathered Flash',
    'Splash Sprinter',
    'Waddle Warden',
  ];

  bool _isDuckUnlocked(BuildContext context, int index) {
    final waterTracker = context.read<WaterTracker>();
    switch (index) {
      case 0:
        return waterTracker.waterConsumed >= 100;
      case 1:
        return waterTracker.completedChallenges >= 5;
      case 2:
        return waterTracker.currentStreak >= 7;
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
        title: const Text('Duck'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
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
                _showDuckDetails(context, index); // Trigger bottom sheet on tap
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(15),
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
                              'assets/duck_$index.png') // Display the duck's design
                          : const Icon(Icons.lock,
                              size: 40,
                              color: Colors.black), // Display a silhouette
                      const SizedBox(height: 8),
                      Text(
                        _duckNames[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final waterTracker = context.watch<WaterTracker>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile image and username with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.lightBlueAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(16.0),
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
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(
                                        source: ImageSource.gallery);
                                    if (image != null) {
                                      // Assuming you have a method to upload and save the image
                                      await context
                                          .read<WaterTracker>()
                                          .updateProfileImage(image.path);
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
                        radius: 60,
                        backgroundImage: waterTracker.profileImage != null
                            ? FileImage(File(waterTracker.profileImage!))
                            : null,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        child: waterTracker.profileImage == null
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.blue)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      waterTracker.username ?? 'Guest',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // User's current streak, record streak, challenges, companions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _buildStatisticCard(
                        icon: Icons.local_fire_department,
                        label: 'Current Streak',
                        value: '${waterTracker.currentStreak}',
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _buildStatisticCard(
                        icon: Icons.star,
                        label: 'Record Streak',
                        value: '${waterTracker.recordStreak}',
                        color: Colors.yellowAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
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
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: _buildStatisticCard(
                        icon: Icons.people,
                        label: 'Companions',
                        value: '${waterTracker.companionsCollected}',
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              // List of options with trailing icons
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                      onTap: () {
                        // Implement share profile functionality
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
                        // Implement goal reminders/notifications functionality
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
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
        style: const TextStyle(fontSize: 18),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
    );
  }
}
