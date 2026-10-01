import 'package:absensi/view/splashscreen.dart';
import 'package:flutter/material.dart';

// import 'package:absensi/view/autentikasi/register.dart';
// import 'package:absensi/view/autentikasi/login.dart';
// import 'package:absensi/view/dashboard/dashboard.dart';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  // await PreferenceHandler.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Splash(),
      debugShowCheckedModeBanner: false,
    );
  }
}
