import 'package:absensi/view/autentikasi/login.dart';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  static const Duration _splashDuration = Duration(seconds: 5);
  static const Color _primary = Color.fromARGB(255, 17, 35, 95);

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      body: Stack(
        children: [
          // Logo tepat di tengah layar
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: Image.asset(
                'assets/logo_absen.png',
                height: 300,
                width: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Tulisan dan animasi di bagian bawah
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Absensi PPKDJU',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
