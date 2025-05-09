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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FutureBuilder<int>(
            future: _getCurrentStreak(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Error fetching streak',
                  style: TextStyle(color: Colors.white),
                );
              } else if (snapshot.hasData) {
                int currentStreak = snapshot.data!;
                int oldStreak = currentStreak > 0 ? currentStreak - 1 : 0;

                _streakAnimation =
                    IntTween(begin: oldStreak, end: currentStreak)
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
                          '🎉 Congratulations! 🎉',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black26,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 120,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'You have met your goal for the day!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                blurRadius: 5.0,
                                color: Colors.black26,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        AnimatedBuilder(
                          animation: _streakAnimation,
                          builder: (context, child) {
                            return ScaleTransition(
                              scale: _scaleAnimation,
                              child: Text(
                                '${_streakAnimation.value}',
                                style: const TextStyle(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black26,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                          ),
                          child: const Text(
                            'Go to Home',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 350,
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        numberOfParticles: 30,
                        gravity: 0.2,
                        emissionFrequency: 0.1,
                        maxBlastForce: 20,
                        minBlastForce: 10,
                        colors: [
                          Colors.red,
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.purple,
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
