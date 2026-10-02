import 'dart:typed_data';
import 'dart:ui';

import 'package:absensi/service/foto_service.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:absensi/view/autentikasi/login.dart';
import 'package:absensi/model/ubah_kata_sandi_page.dart';
import 'package:absensi/model/ubah_profil_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  static const Color _primary = Color.fromARGB(255, 17, 35, 95);

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

  void _snack(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  // ============================================================
  // FOTO PROFIL
  // ============================================================

  Future<void> _pilihFoto() async {
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPilihanFoto(ctx),
    );
    if (pilihan == null) return;

    if (pilihan == 'hapus') {
      await FotoService.hapus();
      if (!mounted) return;
      _snack('Foto profil dihapus');
      return;
    }

    try {
      final file = await ImagePicker().pickImage(
        source: pilihan == 'kamera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
      if (file == null) return; // dibatalkan

      final bytes = await file.readAsBytes();
      await FotoService.simpan(bytes);
      if (!mounted) return;
      _snack('Foto profil diperbarui');
    } catch (e) {
      debugPrint('Gagal ambil foto: $e');
      if (!mounted) return;
      _snack('Gagal mengambil foto. Coba lagi.');
    }
  }

  Widget _buildPilihanFoto(BuildContext ctx) {
    Widget item(IconData icon, String label, String nilai, {Color? warna}) {
      return ListTile(
        leading: Icon(icon, color: warna ?? Colors.white),
        title: Text(label, style: TextStyle(color: warna ?? Colors.white)),
        onTap: () => Navigator.pop(ctx, nilai),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D246B), Color(0xFF193E9A), Color(0xFF4169C1)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              item(
                Icons.photo_camera_outlined,
                'Ambil foto (kamera)',
                'kamera',
              ),
              item(Icons.photo_library_outlined, 'Pilih dari galeri', 'galeri'),
              if (FotoService.foto.value != null)
                item(
                  Icons.delete_outline,
                  'Hapus foto',
                  'hapus',
                  warna: const Color(0xFFFFB4B4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGASI MENU
  // ============================================================

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
            // Avatar: ketuk untuk mengganti foto
            GestureDetector(
              onTap: _pilihFoto,
              child: Stack(
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
                    child: ValueListenableBuilder<Uint8List?>(
                      valueListenable: FotoService.foto,
                      builder: (context, foto, child) {
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFF6D544),
                          backgroundImage: foto != null
                              ? MemoryImage(foto)
                              : null,
                          child: foto == null
                              ? const Icon(
                                  Icons.person,
                                  size: 64,
                                  color: Colors.white,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
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
