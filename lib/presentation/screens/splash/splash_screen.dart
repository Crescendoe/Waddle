import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:waddle/core/constants/app_constants.dart';
import 'package:waddle/core/theme/app_theme.dart';
import 'package:waddle/presentation/blocs/auth/auth_cubit.dart';
import 'package:waddle/presentation/blocs/auth/auth_state.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_cubit.dart';
import 'package:waddle/presentation/blocs/hydration/hydration_state.dart';
import 'package:waddle/presentation/widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;
  late final StreamSubscription<AuthState> _authSub;

  @override
  void initState() {
    super.initState();
    // Give the widget tree one frame to finish building, then start listening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForAuth();
    });
  }

  void _listenForAuth() {
    final authCubit = context.read<AuthCubit>();

    // If auth already resolved (unlikely but possible), handle immediately
    final currentState = authCubit.state;
    if (currentState is Authenticated) {
      _onAuthenticated(currentState);
      return;
    }
    if (currentState is Unauthenticated) {
      _goToWelcome();
      return;
    }

    // Otherwise listen for state changes
    _authSub = authCubit.stream.listen((state) {
      if (_navigated) return;

      if (state is Authenticated) {
        _onAuthenticated(state);
      } else if (state is Unauthenticated || state is AuthError) {
        _goToWelcome();
      }
    });

    // Safety timeout — if nothing happens in 8 seconds, send to welcome
    Future.delayed(const Duration(seconds: 8), () {
      if (!_navigated && mounted) {
        _goToWelcome();
      }
    });
  }

  void _onAuthenticated(Authenticated state) {
    if (_navigated) return;

    final hydrationCubit = context.read<HydrationCubit>();

    // Trigger hydration data load if not already loading/loaded
    final hState = hydrationCubit.state;
    if (hState is! HydrationLoaded && hState is! HydrationLoading) {
      hydrationCubit.loadData(state.user.uid);
    }

    // If already loaded, go immediately
    if (hydrationCubit.state is HydrationLoaded) {
      _goToHome();
      return;
    }

    // Wait for hydration data
    late final StreamSubscription<HydrationBlocState> hSub;
    hSub = hydrationCubit.stream.listen((hState) {
      if (_navigated) {
        hSub.cancel();
        return;
      }
      if (hState is HydrationLoaded) {
        hSub.cancel();
        _goToHome();
      } else if (hState is HydrationError) {
        hSub.cancel();
        // Still go to home — the home screen shows its own error state
        _goToHome();
      }
    });

    // Timeout for hydration loading
    Future.delayed(const Duration(seconds: 10), () {
      if (!_navigated && mounted) {
        hSub.cancel();
        _goToHome();
      }
    });
  }

  void _goToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed('home');
  }

  void _goToWelcome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.goNamed('welcome');
  }

  @override
  void dispose() {
    try {
      _authSub.cancel();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mascot
              MascotImage(
                assetPath: AppConstants.mascotWave,
                size: 160,
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 20),

              // App name
              Text(
                AppConstants.appName,
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

              const SizedBox(height: 40),

              // Loading indicator
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
