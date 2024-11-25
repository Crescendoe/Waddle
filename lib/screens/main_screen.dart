import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
                children: const [
                  StreakScreen(),
                  ChallengesScreen(),
                  HomeScreen(),
                  CompanionScreen(),
                  ProfileScreen(),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.6),
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
                    label: 'Companion',
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
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLoggedDays();
  }

  Future<void> _loadLoggedDays() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedDays = prefs.getStringList('loggedDays') ?? [];
    final currentStreak = prefs.getInt('currentStreak') ?? 0;

    setState(() {
      _loggedDays = {
        for (var day in loggedDays) DateTime.parse(day): true,
      };
      _currentStreak = currentStreak;
    });
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

    return Column(
      children: [
        // Display the current month (in text, such as "November") and year, with arrows to navigate between months when tapped. The arrows should scroll the user through each month one at a time.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (now.year > 2024 || (now.year == 2024 && now.month > 1))
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    final previousMonth = DateTime(now.year, now.month - 1, 1);
                    _loggedDays.clear();
                    _currentDate = previousMonth;
                    now = previousMonth;
                  });
                },
              ),
            Text(
              '${_getMonthName(now.month)} ${now.year}',
              style: const TextStyle(fontSize: 20),
            ),
            if (now.year < 2099 || (now.year == 2099 && now.month < 12))
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    final nextMonth = DateTime(now.year, now.month + 1, 1);
                    _loggedDays.clear();
                    _currentDate = nextMonth;
                    now = nextMonth;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('M', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('W', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('T', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('F', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('S', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          itemCount: daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (context, index) {
            final day = firstDayOfMonth.add(Duration(days: index));
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
                  // method to display the water log for the selected day
                  _showWaterLog(context, day);
                });
              },
              child: Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                  color: isGoalMet
                      ? Colors.blue
                      : isLogged
                          ? Colors.blue.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
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
    // Implement your logic to check if the water goal was met for the day
    return true;
  }

  // method to display the water log for the selected day just below the calendar which the user can scroll through
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
                spreadRadius: 5,
              ),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                              // leading for icon of the drink. color changes depending on what the drink is. brown for soda, red for energy drink, green for tea, etc.

                              leading: CircleAvatar(
                                backgroundColor: log.drinkName == 'Soda'
                                    ? Colors.brown
                                    : log.drinkName == 'Energy Drink'
                                        ? Colors.red
                                        : log.drinkName == 'Tea'
                                            ? Colors.green
                                            : log == 'Coffee'
                                                ? Colors.brown
                                                : log == 'Smoothie'
                                                    ? Colors.purple
                                                    : log == 'Sports Drink'
                                                        ? Colors.blue
                                                        : log == 'Milk'
                                                            ? Colors.white
                                                            : log.drinkName ==
                                                                    'Orange Juice'
                                                                ? Colors.orange
                                                                : log.drinkName ==
                                                                        'Lemonade'
                                                                    ? Colors
                                                                        .yellow
                                                                    : Colors
                                                                        .blue,
                                child: const Icon(Icons.local_drink,
                                    color: Colors.white),
                              ),
                              title: Text(
                                log.drinkName,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              // subtitle for log ampount to the neareaest tenth of an ounce
                              subtitle: Text(
                                '${log.amount.toStringAsFixed(1)} oz',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              trailing: Text(
                                '${log.entryTime.hour % 12 == 0 ? 12 : log.entryTime.hour % 12}:${log.entryTime.minute.toString().padLeft(2, '0')} ${log.entryTime.hour < 12 ? 'AM' : 'PM'}',
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaks'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildCalendar(),
            const SizedBox(height: 20),
            Text(
              'Current Streak: $_currentStreak days',
              style: const TextStyle(fontSize: 20),
            ),
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
      body: const Center(
        child: Text('Challenges Page'),
      ),
    );
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
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Consumer<WaterTracker>(
                builder: (context, tracker, child) {
                  return AnimatedWave(
                    controller: _controller,
                    height: (tracker.waterConsumed / tracker.waterGoal) * 100,
                    totalWidth: MediaQuery.of(context).size.width,
                  );
                },
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

void logDrink(BuildContext context, String drinkName, double amount,
    double waterContent) {
  final log = WaterLog(
    drinkName: drinkName,
    amount: amount,
    waterContent: waterContent,
    entryTime: DateTime.now(),
  );

  context.read<WaterTracker>().addLog(log);
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
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What did you drink?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3, // Number of columns
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _buildDrinkItems(context),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDrinkItems(BuildContext context) {
    final drinks = [
      // Water
      {
        'name': 'Water',
        'icon': Icons.local_drink,
        'ratio': 1.0,
        'color': Colors.blue
      },
      // Juices
      {
        'name': 'Orange Juice',
        'icon': Icons.local_drink,
        'ratio': 0.8,
        'color': Colors.orange
      },
      {
        'name': 'Lemonade',
        'icon': Icons.local_drink,
        'ratio': 0.6,
        'color': Colors.yellow
      },
      // Dairy
      {
        'name': 'Milk',
        'icon': Icons.local_drink,
        'ratio': 0.9,
        'color': Colors.white
      },
      // Energy Drinks
      {
        'name': 'Energy Drink',
        'icon': Icons.local_drink,
        'ratio': 0.6,
        'color': Colors.red
      },
      // Coffee and Tea
      {
        'name': 'Coffee',
        'icon': Icons.local_drink,
        'ratio': 0.5,
        'color': Colors.brown
      },
      {
        'name': 'Tea',
        'icon': Icons.local_drink,
        'ratio': 0.7,
        'color': Colors.green
      },
      // Sodas
      {
        'name': 'Soda',
        'icon': Icons.local_drink,
        'ratio': 0.4,
        'color': Colors.brown
      },
      // Smoothies
      {
        'name': 'Smoothie',
        'icon': Icons.local_drink,
        'ratio': 0.7,
        'color': Colors.purple
      },
      {
        'name': 'Sports Drink',
        'icon': Icons.local_drink,
        'ratio': 0.5,
        'color': Colors.blue
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
                size: 40, color: drink['color'] as Color),
            const SizedBox(height: 5),
            Text(drink['name'] as String),
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

class CompanionScreen extends StatelessWidget {
  const CompanionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companion'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Companion Page'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: const Center(
        child: Text('Profile Page'),
      ),
    );
  }
}
