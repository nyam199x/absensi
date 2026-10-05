import 'package:absensi/view/autentikasi/login.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(seconds: 5);
  static const Color _primary = Color.fromARGB(255, 17, 35, 95);

  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    // Controller untuk animasi logo
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Efek pop-up / bounce
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    // Jalankan animasi
    _logoController.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(_splashDuration);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: Stack(
        children: [
          // Logo dengan animasi pop-up
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: ScaleTransition(
                scale: _logoAnimation,
                child: Image.asset(
                  'assets/logo.png',
                  height: 100,
                  width: 400,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Tulisan dan animasi loading
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    Lottie.asset(
                      'assets/animations/loading.json',
                      width: 100,
                      height: 100,
                      repeat: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
