import 'package:flutter/material.dart';
import 'dart:async';

import 'package:kq/widgets/onBoardingPage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _containerOpacity = 0.0;
  double _titleOpacity = 0.0;
  double _subtitleOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Fade in the red container
    Timer(const Duration(milliseconds: 300), () {
      setState(() => _containerOpacity = 1.0);
    });

    // Fade in "Kenya Airways" after container
    Timer(const Duration(milliseconds: 1200), () {
      setState(() => _titleOpacity = 1.0);
    });

    // Fade in "Pride of Africa" after title
    Timer(const Duration(milliseconds: 2000), () {
      setState(() => _subtitleOpacity = 1.0);
    });

    // Navigate to OnBoardingPage after 4 seconds
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnBoardingPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: _containerOpacity,
              duration: const Duration(seconds: 1),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedOpacity(
              opacity: _titleOpacity,
              duration: const Duration(seconds: 1),
              child: const Text(
                'Kenya Airways',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 1),
            AnimatedOpacity(
              opacity: _subtitleOpacity,
              duration: const Duration(seconds: 1),
              child: const Text(
                'Pride of Africa',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
