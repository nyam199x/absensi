import 'package:absensi/service/simpan_token.dart';
import 'package:absensi/view/autentikasi/login.dart';
import 'package:absensi/view/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(seconds: 3);
  static const Color _primary = Color.fromARGB(255, 17, 35, 95);

  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;

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

    _logoController.forward();

    _checkSession();
  }

  /// Tunggu splash selesai (sambil membaca token), lalu:
  /// - sudah pernah login (token tersimpan) -> langsung ke dashboard
  /// - belum / sudah logout -> ke halaman login
  Future<void> _checkSession() async {
    final results = await Future.wait([
      SimpanToken.getToken(),
      Future.delayed(_splashDuration),
    ]);
    if (!mounted) return;

    final token = results.first as String?;
    final isLoggedIn = token != null && token.isNotEmpty;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn ? const Dashboard() : const Login(),
      ),
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
            child: ScaleTransition(
              scale: _logoAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/logo.png',
                  width: 280,
                  fit: BoxFit.contain, // jangan gepeng/terpotong
                ),
              ),
            ),
          ),

          // Animasi loading
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 100,
                  height: 100,
                  repeat: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
