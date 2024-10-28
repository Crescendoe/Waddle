import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final double waterIntake;
  final bool isImperial;

  const ResultScreen({
    super.key,
    required this.waterIntake,
    required this.isImperial,
  });

  @override
  Widget build(BuildContext context) {
    // Round the water intake to two decimal places
    final intake = isImperial
        ? waterIntake.toStringAsFixed(2)
        : (waterIntake * 0.0295735)
            .toStringAsFixed(2); // Convert to liters if metric

    final unit = isImperial ? 'oz' : 'L';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Recommended Daily Water Intake:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              '$intake $unit',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Go to Home',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
