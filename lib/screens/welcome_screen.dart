import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Center content for Welcome Text and Button
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to Waterly!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ScaleTransition(
                    scale:
                        Tween<double>(begin: 0.9, end: 1.0).animate(_animation),
                    child: const Icon(
                      Icons.local_drink,
                      size: 100,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/questions');
                    },
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ),
          ),

          // Animated water wave at the bottom of the screen
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ClipPath(
                  clipper: WaveClipper(waveHeight: 10 + 10 * _animation.value),
                  child: Container(
                    height: 100,
                    color: Colors.blue[300],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double waveHeight;

  WaveClipper({required this.waveHeight});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0.0, size.height - waveHeight);
    for (int i = 0; i < size.width.toInt(); i += 30) {
      path.relativeQuadraticBezierTo(15, -waveHeight, 30, 0); // wave-like curve
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
