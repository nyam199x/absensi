import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menyimpan foto profil di perangkat (SharedPreferences, format base64).
/// [foto] adalah notifier yang dipakai halaman Profil dan Dashboard,
/// sehingga keduanya otomatis berubah saat foto diganti.
class FotoService {
  static const String _key = 'foto_profil';

  static final ValueNotifier<Uint8List?> foto = ValueNotifier<Uint8List?>(null);

  /// Baca foto tersimpan ke [foto]. Panggil saat Dashboard dibuka.
  static Future<void> muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString(_key);
      foto.value = (b64 == null || b64.isEmpty) ? null : base64Decode(b64);
    } catch (e) {
      debugPrint('Gagal muat foto profil: $e');
      foto.value = null;
    }
  }

  static Future<void> simpan(Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, base64Encode(bytes));
    foto.value = bytes;
  }

  static Future<void> hapus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    foto.value = null;
  }
}