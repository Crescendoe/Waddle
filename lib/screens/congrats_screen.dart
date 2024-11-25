import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterly/models/water_tracker.dart';
import 'package:confetti/confetti.dart';

class CongratsScreen extends StatefulWidget {
  const CongratsScreen({super.key});

  @override
  CongratsScreenState createState() => CongratsScreenState();
}

class CongratsScreenState extends State<CongratsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _streakAnimation;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  bool _confettiPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<int> _getCurrentStreak() async {
    final waterTracker = Provider.of<WaterTracker>(context, listen: false);
    return waterTracker.currentStreak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<int>(
          future: _getCurrentStreak(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Error fetching streak');
            } else if (snapshot.hasData) {
              int currentStreak = snapshot.data!;
              int oldStreak = currentStreak - 1;

              _streakAnimation = IntTween(begin: oldStreak, end: currentStreak)
                  .animate(_controller)
                ..addListener(() {
                  setState(() {});
                  if (_streakAnimation.value == currentStreak &&
                      !_confettiPlayed) {
                    _confettiController.play();
                    _confettiPlayed = true;
                  }
                });

              _scaleAnimation =
                  Tween<double>(begin: 1, end: 1.5).animate(CurvedAnimation(
                parent: _controller,
                curve: Curves.elasticInOut,
              ));

              _controller.forward();

              return Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 20),
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 100,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You have met your goal for the day!',
                        style:
                            TextStyle(fontSize: 24, color: Colors.green[700]),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Current Streak: ',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: _streakAnimation,
                        builder: (context, child) {
                          return ScaleTransition(
                            scale: _scaleAnimation,
                            child: Text(
                              '${_streakAnimation.value}',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/home');
                        },
                        child: const Text('Go to Home'),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 350,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 20,
                      gravity: 0.1,
                      emissionFrequency: 0.05,
                      maxBlastForce: 15,
                      minBlastForce: 8,
                      strokeColor: Colors.purple,
                    ),
                  ),
                ],
              );
            } else {
              return const Text('Loading...');
            }
          },
        ),
      ),
    );
  }
}
