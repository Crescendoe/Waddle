import 'package:flutter/material.dart';

class AccountCreatedScreen extends StatefulWidget {
  const AccountCreatedScreen({super.key});

  @override
  _AccountCreatedScreenState createState() => _AccountCreatedScreenState();
}

class _AccountCreatedScreenState extends State<AccountCreatedScreen>
    with TickerProviderStateMixin {
  bool _isFlying = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _startFlyingAnimation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startFlyingAnimation() {
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isFlying = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Color(0xFF36708B),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Your account has been created, Welcome to Waddle!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/questions');
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 3),
            curve: Curves.easeInOut,
            left: _isFlying ? MediaQuery.of(context).size.width : -100,
            top: _isFlying
                ? MediaQuery.of(context).size.height * 0.1
                : MediaQuery.of(context).size.height * 0.5,
            child: Image.asset(
              'lib/assets/images/wade_flying.png',
              width: 100,
              height: 100,
            ),
          ),
        ],
      ),
    );
  }
}
