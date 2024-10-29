import 'package:flutter/material.dart';
import 'results_screen.dart';

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
                  if (_ageController.text.isEmpty ||
                      int.tryParse(_ageController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid age.')),
                    );
                    return;
                  }
                  if (_heightController.text.isEmpty ||
                      double.tryParse(_heightController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid height.')),
                    );
                    return;
                  }
                  if (_weightController.text.isEmpty ||
                      double.tryParse(_weightController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid weight.')),
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

  void _submitData(BuildContext context) {
    final int age = int.parse(_ageController.text);
    final double height = double.parse(_heightController.text);
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

  double calculateWaterIntake(
      int age, double height, String sex, double weight, String activityLevel) {
    // Use baseline of 0.5 oz per pound of body weight for water intake
    double waterIntake = weight * 0.5;

    // Activity multiplier adjustments
    Map<String, double> activityMultiplier = {
      'Sedentary': 0.0,
      'Light': 0.05,
      'Moderate': 0.1,
      'High': 0.15,
      'Extreme': 0.2,
    };

    // Adjust water intake based on activity level
    waterIntake += waterIntake * activityMultiplier[activityLevel]!;

    // If male, recommend slightly more water intake
    if (sex == 'Male') {
      waterIntake += 16; // Additional ounces for males
    }

    // Adjust water intake for age (older individuals may need less)
    if (age > 30 && age <= 55) {
      waterIntake -= waterIntake * 0.05;
    } else if (age > 55) {
      waterIntake -= waterIntake * 0.10;
    }

    // Round to a more user-friendly number
    waterIntake = waterIntake.roundToDouble();

    return waterIntake;
  }
}
