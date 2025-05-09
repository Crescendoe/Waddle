import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/water_tracker.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionsScreen extends StatefulWidget {
  final dynamic calculateWaterIntake;

  const QuestionsScreen({super.key, this.calculateWaterIntake});

  @override
  QuestionsScreenState createState() => QuestionsScreenState();
}

class QuestionsScreenState extends State<QuestionsScreen> {
  // Controllers for text fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Variables to store selected values
  String _selectedSex = 'Male';
  String _selectedActivityLevel = 'Sedentary';
  String _selectedWeather = 'Cold';

  // List of activity levels
  final List<String> _activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'High',
    'Extreme'
  ];

  // List of weather options
  final List<String> _weatherOptions = ['Cold', 'Cool', 'Mild', 'Warm', 'Hot'];

  // Validation flags
  bool _isAgeValid = true;
  bool _isFeetValid = true;
  bool _isInchesValid = true;
  bool _isWeightValid = true;

  // Function to validate input
  bool _validateInput(String input, int min, int max,
      {bool isDouble = false,
      bool allowLetters = false,
      bool allowSpaces = false}) {
    if (input.isEmpty) {
      return false;
    }

    if (!allowLetters && input.contains(RegExp(r'[^0-9.]'))) {
      return false;
    }

    if (!allowSpaces && input.contains(' ')) {
      return false;
    }

    if (isDouble) {
      double value = double.parse(input);
      return value >= min && value <= max;
    } else {
      int value = int.parse(input);
      return value >= min && value <= max;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Disable back button
          title: Text(
            'Enter Your Details',
            style: GoogleFonts.cherryBombOne(
              textStyle: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                Text(
                  'Enter your details to calculate your daily water intake. Don\'t worry, this information is not shared with anyone.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                // Age input field
                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    errorText: _isAgeValid ? null : 'Invalid age',
                    errorStyle: const TextStyle(color: Colors.red),
                    labelStyle: TextStyle(
                        color: _isAgeValid ? Colors.grey[700] : Colors.red),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Height input fields
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _feetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (ft)',
                          errorText:
                              _isFeetValid ? null : 'Invalid height in feet',
                          errorStyle: const TextStyle(color: Colors.red),
                          labelStyle: TextStyle(
                              color:
                                  _isFeetValid ? Colors.grey[700] : Colors.red),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _inchesController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Height (in)',
                          errorText: _isInchesValid
                              ? null
                              : 'Invalid height in inches',
                          errorStyle: const TextStyle(color: Colors.red),
                          labelStyle: TextStyle(
                              color: _isInchesValid
                                  ? Colors.grey[700]
                                  : Colors.red),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Weight input field
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Weight (lbs)',
                    errorText: _isWeightValid ? null : 'Invalid weight',
                    errorStyle: const TextStyle(color: Colors.red),
                    labelStyle: TextStyle(
                        color: _isWeightValid ? Colors.grey[700] : Colors.red),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Sex:'),
                // Dropdown for selecting sex
                DropdownButtonFormField<String>(
                  value: _selectedSex,
                  hint: const Text('Select...'),
                  items: [
                    'Prefer not to say',
                    'Male',
                    'Female',
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSex = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Activity Level:'),
                // Dropdown for selecting activity level
                DropdownButtonFormField<String>(
                  value: _selectedActivityLevel,
                  hint: const Text('Select...'),
                  items: _activityLevels.map((String level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedActivityLevel = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Weather:'),
                // Dropdown for selecting weather
                DropdownButtonFormField<String>(
                  value: _selectedWeather,
                  hint: const Text('Select...'),
                  items: _weatherOptions.map((String weather) {
                    return DropdownMenuItem<String>(
                      value: weather,
                      child: Text(weather),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedWeather = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            _isAgeValid =
                                _validateInput(_ageController.text, 3, 100);
                            _isFeetValid =
                                _validateInput(_feetController.text, 2, 10);
                            _isInchesValid =
                                _validateInput(_inchesController.text, 0, 11);
                            _isWeightValid = _validateInput(
                                _weightController.text, 30, 1000,
                                isDouble: true);
                          });

                          if (!_isAgeValid ||
                              !_isFeetValid ||
                              !_isInchesValid ||
                              !_isWeightValid) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please correct the errors in red.')),
                            );
                            return;
                          }

                          // Show loading screen
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Calculating recommended daily water intake...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        decoration: TextDecoration.none,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );

                          // Simulate a delay for loading
                          await Future.delayed(const Duration(seconds: 2));

                          if (!mounted) return;
                          Navigator.of(context).pop();
                          _submitData(context);
                        },
                        child: const Text('Calculate Water Intake'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Use Default Value'),
                                content: const Text(
                                    'Would you like to use the default amount of 80 oz? This is a median value for the average of what both men and women should consume on a daily basis.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Go Back'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Provider.of<WaterTracker>(context,
                                              listen: false)
                                          .setWaterGoal(80.0);
                                      Navigator.of(context).pop();
                                      Navigator.pushNamed(context, '/results');
                                    },
                                    child: const Text('Use Default Value'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('Use Default Value'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: -100,
              right: -50,
              child: Image.asset(
                'lib/assets/images/wade_default.png',
                width: 200, // Adjust the size as needed
                height: 200, // Adjust the size as needed
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitData(BuildContext context) {
    final int age = int.parse(_ageController.text);
    final int feet = int.parse(_feetController.text);
    final int inches = int.parse(_inchesController.text);
    final double weight = double.parse(_weightController.text);

    // Calculate water intake based on user input
    final waterGoal = _calculateWaterIntake(
        age,
        (feet * 12 + inches).toDouble(),
        _selectedSex,
        weight,
        _selectedActivityLevel,
        _selectedWeather);

    // Update the water goal in WaterTracker to be the returned waterIntake variable from the calculateWaterIntake function
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    // Save the water goal to Firestore
    waterTracker.resetWater();
    waterTracker.setWaterGoal(waterGoal);

    // Navigate to the results screen
    Navigator.pushNamed(context, '/results');
  }

  // Function to calculate water intake based on user input
  double _calculateWaterIntake(int age, double height, String sex,
      double weight, String activityLevel, String weather) {
    double waterIntake = weight * 0.45;

    final activityMultiplier = {
      'Sedentary': 0.0,
      'Light': 0.05,
      'Moderate': 0.1,
      'High': 0.15,
      'Extreme': 0.25,
    };

    final weatherMultiplier = {
      'Cold': 0.0,
      'Cool': 0.05,
      'Mild': 0.1,
      'Warm': 0.15,
      'Hot': 0.25,
    };

    waterIntake += waterIntake * activityMultiplier[activityLevel]!;
    waterIntake += waterIntake * weatherMultiplier[weather]!;

    if (sex == 'Male') {
      waterIntake += 16;
    } else if (sex == 'Prefer not to say') {
      waterIntake += 8;
    }
    if (age > 30 && age <= 55) {
      waterIntake += waterIntake * 0.05;
    } else if (age > 55) {
      waterIntake += waterIntake * 0.1;
    }

    if (height > 60) {
      waterIntake += waterIntake * 0.05;
    }

    return waterIntake;
  }
}
