import 'package:flutter/material.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  final double waterGoal;
  const HomeScreen({super.key, required this.waterGoal});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  double waterConsumed = 0.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedWave(
              controller: _controller,
              height: (waterConsumed / widget.waterGoal) * 100,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Home Screen'),
                const SizedBox(height: 20),
                Text('Water Consumed: ${waterConsumed.toInt()} oz'),
                Slider(
                  value: waterConsumed,
                  min: 0,
                  max: widget.waterGoal,
                  onChanged: (value) {
                    setState(() {
                      waterConsumed = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedWave extends StatelessWidget {
  final AnimationController controller;
  final double height;

  const AnimatedWave(
      {super.key, required this.controller, required this.height});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WavePainter(controller.value, height),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final double height;

  WavePainter(this.animationValue, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    const waveHeight = 20.0; // Fixed height for the wave ripples
    final waveLength = size.width;
    final baseHeight = size.height * (1 - height / 100);

    path.moveTo(0, baseHeight);
    for (double i = 0; i <= waveLength; i++) {
      path.lineTo(
        i,
        baseHeight -
            waveHeight *
                sin((i / waveLength * 2 * pi) + (animationValue * 2 * pi)),
      );
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
