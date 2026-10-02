import 'package:shared_preferences/shared_preferences.dart';

class SimpanToken {
  static const _keyToken = 'token';
  static const _keyName = 'user_name';

  static Future<void> saveSession({required String token, String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (name != null) await prefs.setString(_keyName, name);
  }

  /// Simpan nama saja (dipakai setelah Ubah Profil berhasil),
  /// tanpa menyentuh token.
  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove('foto_profil');
  }
}
