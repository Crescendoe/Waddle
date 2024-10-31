import 'package:flutter/material.dart';
import 'results_screen.dart';

// Main class for the QuestionsScreen
class QuestionsScreen extends StatefulWidget {
  final dynamic calculateWaterIntake;

  const QuestionsScreen({super.key, this.calculateWaterIntake});

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

// State class for QuestionsScreen
class _QuestionsScreenState extends State<QuestionsScreen> {
  // Controllers for text fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _feetController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Variables to store selected values
  String _selectedSex = 'Male';
  String _selectedActivityLevel = 'Sedentary';

  // List of activity levels
  final List<String> _activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'High',
    'Extreme'
  ];

  // Validation flags
  bool _isAgeValid = true;
  bool _isFeetValid = true;
  bool _isInchesValid = true;
  bool _isWeightValid = true;

  // Function to validate input
  _validateInput(String input, int min, int max, {bool isDouble = false}) {
    if (input.isEmpty) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your details:', style: TextStyle(fontSize: 18)),
            // Age input field
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                errorText: _isAgeValid ? null : 'Invalid age',
                errorStyle: const TextStyle(color: Colors.red),
                labelStyle:
                    TextStyle(color: _isAgeValid ? Colors.black : Colors.red),
              ),
            ),
            // Height input fields
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Height (ft)',
                      errorText: _isFeetValid ? null : 'Invalid height in feet',
                      errorStyle: const TextStyle(color: Colors.red),
                      labelStyle: TextStyle(
                          color: _isFeetValid ? Colors.black : Colors.red),
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
                      errorText:
                          _isInchesValid ? null : 'Invalid height in inches',
                      errorStyle: const TextStyle(color: Colors.red),
                      labelStyle: TextStyle(
                          color: _isInchesValid ? Colors.black : Colors.red),
                    ),
                  ),
                ),
              ],
            ),
            // Weight input field
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight (lbs)',
                errorText: _isWeightValid ? null : 'Invalid weight',
                errorStyle: const TextStyle(color: Colors.red),
                labelStyle: TextStyle(
                    color: _isWeightValid ? Colors.black : Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Sex:'),
            // Dropdown for selecting sex
            DropdownButton<String>(
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
            ),
            const SizedBox(height: 16),
            const Text('Activity Level:'),
            // Dropdown for selecting activity level
            DropdownButton<String>(
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
            ),
            const SizedBox(height: 32),
            // Button to calculate water intake
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isAgeValid = _validateInput(_ageController.text, 3, 100);
                    _isFeetValid = _validateInput(_feetController.text, 2, 10);
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
                          content: Text('Please correct the errors in red.')),
                    );
                    return;
                  }

                  _submitData(context);
                },
                child: const Text('Calculate Water Intake'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to submit data and navigate to result screen
  void _submitData(BuildContext context) {
    final int age = int.parse(_ageController.text);
    final int feet = int.parse(_feetController.text);
    final int inches = int.parse(_inchesController.text);
    final double height = (feet * 12).toDouble() + inches.toDouble();
    final double weight = double.parse(_weightController.text);
    final String sex = _selectedSex;
    final String activityLevel = _selectedActivityLevel;

    double waterIntake = calculateWaterIntake(
      age,
      height,
      sex,
      weight,
      activityLevel,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          waterIntake: waterIntake,
        ),
      ),
    );
  }

  // Function to calculate water intake based on user input
  double calculateWaterIntake(
      int age, double height, String sex, double weight, String activityLevel) {
    double waterIntake = weight * 0.5;

    Map<String, double> activityMultiplier = {
      'Sedentary': 0.0,
      'Light': 0.05,
      'Moderate': 0.1,
      'High': 0.15,
      'Extreme': 0.2,
    };

    waterIntake += waterIntake * activityMultiplier[activityLevel]!;

    if (sex == 'Male') {
      waterIntake += 16;
    } else if (sex == 'Prefer not to say') {
      waterIntake += 8;
    }

    if (age > 30 && age <= 55) {
      waterIntake -= waterIntake * 0.05;
    } else if (age > 55) {
      waterIntake -= waterIntake * 0.10;
    }

    waterIntake = waterIntake.roundToDouble();

    return waterIntake;
  }
}
