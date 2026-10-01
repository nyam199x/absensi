import 'package:flutter/material.dart';
 
/// Mengelola tema terang/gelap aplikasi.
/// Letakkan di: lib/service/theme_service.dart
class ThemeService {
  ThemeService._();
 
  /// Nilai tema saat ini. Widget bisa "mendengarkan" perubahannya
  /// lewat ValueListenableBuilder.
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);
 
  /// Ganti tema: terang -> gelap, gelap -> terang.
  static void toggleTheme() {
    themeMode.value =
        themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
 