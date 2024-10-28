import 'package:flutter/material.dart';
import 'results_screen.dart'; // Import the results screen

class QuestionsScreen extends StatefulWidget {
  final dynamic calculateWaterIntake;

  const QuestionsScreen({super.key, this.calculateWaterIntake});

  @override
  _QuestionsScreenState createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  String _selectedSex = 'Male';
  String _selectedActivityLevel = 'Sedentary';

  final List<String> _activityLevels = [
    'Sedentary',
    'Light',
    'Moderate',
    'High',
    'Extreme'
  ];

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
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height (in)'),
            ),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (lbs)'),
            ),
            const SizedBox(height: 16),
            const Text('Sex:'),
            DropdownButton<String>(
              value: _selectedSex,
              items: ['Male', 'Female'].map((String value) {
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
            DropdownButton<String>(
              value: _selectedActivityLevel,
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
            Center(
              child: ElevatedButton(
                onPressed: () {
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

  void _submitData(BuildContext context) {
    final int age = int.parse(_ageController.text);
    final double height = double.parse(_heightController.text);
    final double weight = double.parse(_weightController.text);
    final String sex = _selectedSex;
    final String activityLevel = _selectedActivityLevel;

    // Perform the water intake calculation here
    double waterIntake = calculateWaterIntake(
      age,
      height,
      sex,
      weight,
      activityLevel,
    );

    // Navigate to the ResultsScreen and pass the calculated water intake
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          waterIntake: waterIntake,
          isImperial: true,
        ),
      ),
    );
  }

  // Example water intake calculation function
  double calculateWaterIntake(
      int age, double height, String sex, double weight, String activityLevel) {
    double waterIntake = weight * 0.5; // Example calculation in ounces
    Map<String, double> activityMultiplier = {
      'Sedentary': 0.0,
      'Light': 0.1,
      'Moderate': 0.2,
      'High': 0.3,
      'Extreme': 0.4,
    };

    waterIntake += waterIntake * activityMultiplier[activityLevel]!;

    // Example adjustment based on height
    waterIntake += height * 0.1;

    if (sex == 'Male') {
      waterIntake += 16; // Additional ounces for males
    }

    if (age > 30 && age <= 55) {
      waterIntake -= waterIntake * 0.05;
    } else if (age > 55) {
      waterIntake -= waterIntake * 0.10;
    }

    // Round the water intake to the nearest whole number
    waterIntake = waterIntake.roundToDouble();

    // Convert the water intake to an integer before returning
    return waterIntake.toInt().toDouble();
  }
}
