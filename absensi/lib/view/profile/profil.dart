import 'dart:typed_data';
import 'dart:ui';

import 'package:absensi/reusable/app_colors.dart';
import 'package:absensi/service/foto_service.dart';
import 'package:absensi/service/profil_service.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:absensi/view/autentikasi/login.dart';

import 'package:absensi/model/profil_model.dart';
import 'package:absensi/model/ubah_nama.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String _nama = '';
  UserProfilModel? _profil;
  bool _isLoadingProfil = true;
  bool _gagalMuat = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadProfil();
  }

  /// Nama cepat dari penyimpanan lokal (untuk header).
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

  /// Data lengkap profil dari API lewat ProfilService
  /// (nama, email, id, tanggal dibuat/diperbarui).
  Future<void> _loadProfil() async {
    setState(() {
      _isLoadingProfil = true;
      _gagalMuat = false;
    });

    final profil = await ProfilService.ambilProfil();
    if (!mounted) return;

    setState(() {
      _isLoadingProfil = false;
      if (profil == null) {
        _gagalMuat = true;
      } else {
        _profil = profil;
        if (profil.nama.isNotEmpty) _nama = profil.nama;
      }
    });
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  String _formatTanggal(DateTime? d) {
    if (d == null) return '-';
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final l = d.toLocal();
    final jam = l.hour.toString().padLeft(2, '0');
    final menit = l.minute.toString().padLeft(2, '0');
    return '${l.day.toString().padLeft(2, '0')} ${bulan[l.month - 1]} ${l.year}, $jam:$menit';
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
        leading: Icon(icon, color: warna ?? AppColors.profileText),
        title: Text(
          label,
          style: TextStyle(color: warna ?? AppColors.profileText),
        ),
        onTap: () => Navigator.pop(ctx, nilai),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.profileBackgroundTop,
            AppColors.profileBackgroundMiddle,
            AppColors.profileBackgroundBottom,
          ],
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
                  color: AppColors.profileHandle,
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
                  warna: AppColors.profileDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGASI
  // ============================================================

  /// Dibuka dari ikon pensil di samping Nama.
  Future<void> _bukaUbahProfil() async {
    final namaBaru = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const UbahProfilPage()),
    );
    // Jika profil berhasil diubah, muat ulang data profil
    if (namaBaru != null && mounted) {
      _loadUser();
      _loadProfil();
    }
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
  // GLASSMORPHISM HELPER
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
            color: AppColors.profileGlassBackground,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.profileGlassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.profileGlassShadow,
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
          colors: [
            AppColors.profileBackgroundTop,
            AppColors.profileBackgroundMiddle,
            AppColors.profileBackgroundBottom,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

            // ===== Kartu data profil (menggantikan menu "Ubah Profil") =====
            _infoCard(
              label: 'Nama',
              value: _profil?.nama.isNotEmpty == true ? _profil!.nama : _nama,
              onEdit: _bukaUbahProfil,
            ),

            _infoCard(label: 'ID Pengguna', value: _profil?.id?.toString()),
            _infoCard(
              label: 'Dibuat Pada',
              value: _profil == null
                  ? null
                  : _formatTanggal(_profil!.createdAt),
            ),
            _infoCard(
              label: 'Terakhir Diperbarui',
              value: _profil == null
                  ? null
                  : _formatTanggal(_profil!.updatedAt),
            ),

            if (_gagalMuat)
              TextButton.icon(
                onPressed: _loadProfil,
                icon: const Icon(Icons.refresh, color: AppColors.profileText),
                label: const Text(
                  'Gagal memuat data profil. Ketuk untuk coba lagi.',
                  style: TextStyle(color: AppColors.profileText),
                ),
              ),

            const SizedBox(height: 6),

            // ===== Keluar (dipertahankan) =====
            _menuItem(
              icon: Icons.logout,
              iconColor: AppColors.profileLogoutIcon,
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
                        color: AppColors.profileAvatarBorder,
                        width: 2,
                      ),
                    ),
                    child: ValueListenableBuilder<Uint8List?>(
                      valueListenable: FotoService.foto,
                      builder: (context, foto, child) {
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.profileAvatarBackground,
                          backgroundImage: foto != null
                              ? MemoryImage(foto)
                              : null,
                          child: foto == null
                              ? const Icon(
                                  Icons.person,
                                  size: 64,
                                  color: AppColors.profileText,
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
                        color: AppColors.profileCameraBackground,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.profileCameraShadow,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: AppColors.profilePrimary,
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
                color: AppColors.profileText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu informasi profil (label kecil + nilai tebal, opsional ikon pensil).
  Widget _infoCard({
    required String label,
    required String? value,
    VoidCallback? onEdit,
  }) {
    final tampil = _isLoadingProfil && (value == null || value.isEmpty)
        ? 'Memuat...'
        : ((value == null || value.isEmpty) ? '-' : value);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: _glassContainer(
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.profileText.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tampil,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.profileText,
                    ),
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.profileText,
                  size: 20,
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
                  color: AppColors.profileIconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.profileText,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.profileText),
            ],
          ),
        ),
      ),
    );
  }
}
