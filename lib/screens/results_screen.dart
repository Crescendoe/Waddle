import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pull the water tracker data from the provider
    final waterTracker = Provider.of<WaterTracker>(context);

    debugPrint('Water Goal: ${waterTracker.waterGoal}');
    debugPrint('Water Consumed: ${waterTracker.waterConsumed}');
    debugPrint(
        'Username: ${waterTracker.username}'); // Add this line for debugging

    final waterIntake = (waterTracker.waterGoal).toInt();

    // Calculate the number of cups (1 cup = 8 oz) and convert to an integer
    final cups = (waterTracker.waterGoal / 8).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                'Recommended Daily Water Intake:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '$waterIntake oz',
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Text(
              '$cups cups',
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  waterTracker.username =
                      user.displayName ?? waterTracker.username;
                  // Run the resetWater method from the water tracker provider
                  waterTracker.resetWater();
                  Navigator.pushNamed(context, '/home');
                }
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
