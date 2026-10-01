import 'dart:ui';

import 'package:absensi/service/simpan_token.dart';
import 'package:absensi/view/autentikasi/login.dart';
import 'package:absensi/model/ubah_kata_sandi_page.dart';
import 'package:absensi/model/ubah_profil_page.dart';
import 'package:flutter/material.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String _nama = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final name = await SimpanToken.getUserName();
      if (!mounted) return;
      setState(() {
        _nama = (name != null && name.isNotEmpty) ? name : 'Pengguna';
      });
    } catch (e) {
      debugPrint('Gagal load user: $e');
      if (!mounted) return;
      setState(() => _nama = 'Pengguna');
    }
  }

  Future<void> _bukaUbahProfil() async {
    final namaBaru = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const UbahProfilPage()),
    );
    // Jika profil berhasil diubah, muat ulang nama di header
    if (namaBaru != null && mounted) _loadUser();
  }

  void _bukaUbahKataSandi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UbahKataSandiPage()),
    );
  }

  Future<void> _konfirmasiKeluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    await SimpanToken.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(showLogoutMessage: true),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // GLASSMORPHISM HELPER (sama dengan gaya Home dan Riwayat)
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D246B), Color(0xFF193E9A), Color(0xFF4169C1)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _menuItem(
              icon: Icons.manage_accounts_outlined,
              iconColor: const Color(0xFF4034AE),
              label: 'Ubah Profil',
              onTap: _bukaUbahProfil,
            ),
            _menuItem(
              icon: Icons.lock_outline,
              iconColor: Colors.green,
              label: 'Ubah Kata Sandi',
              onTap: _bukaUbahKataSandi,
            ),
            _menuItem(
              icon: Icons.logout,
              iconColor: Colors.red,
              label: 'Keluar',
              onTap: _konfirmasiKeluar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 36),
      child: _glassContainer(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
          bottomLeft: Radius.circular(90),
          bottomRight: Radius.circular(90),
        ),
        padding: const EdgeInsets.only(top: 32, bottom: 48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFFF6D544),
                child: Icon(Icons.person, size: 64, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _nama,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: _glassContainer(
          borderRadius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Ikon tetap berwarna aslinya, diletakkan di atas kotak terang
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}