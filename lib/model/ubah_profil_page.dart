import 'package:absensi/model/profil_model.dart';
import 'package:absensi/service/profil_service.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:flutter/material.dart';

class UbahProfilPage extends StatefulWidget {
  const UbahProfilPage({super.key});

  @override
  State<UbahProfilPage> createState() => _UbahProfilPageState();
}

class _UbahProfilPageState extends State<UbahProfilPage> {
  static const Color _primary = Color.fromARGB(255, 17, 35, 95);

  final _formKey = GlobalKey<FormState>();
  final _namaC = TextEditingController();
  final _emailC = TextEditingController();
  final _noHpC = TextEditingController();

  bool _memuat = true;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  @override
  void dispose() {
    _namaC.dispose();
    _emailC.dispose();
    _noHpC.dispose();
    super.dispose();
  }

  Future<void> _muatProfil() async {
    final profil = await ProfilService.ambilProfil();
    String? namaLokal;
    if (profil == null) {
      namaLokal = await SimpanToken.getUserName();
    }
    if (!mounted) return;
    setState(() {
      _namaC.text = profil?.nama ?? namaLokal ?? '';
      _emailC.text = profil?.email ?? '';
      _noHpC.text = profil?.noHp ?? '';
      _memuat = false;
    });
    if (profil == null) {
      _snack('Gagal memuat data profil dari server');
    }
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final req = UbahProfilRequest(
      nama: _namaC.text.trim(),
      email: _emailC.text.trim(),
      noHp: _noHpC.text.trim(),
    );
    final error = req.validasi();
    if (error != null) {
      _snack(error);
      return;
    }

    setState(() => _menyimpan = true);
    final hasil = await ProfilService.ubahProfil(req);
    if (!mounted) return;
    setState(() => _menyimpan = false);

    _snack(hasil.pesan);
    if (hasil.sukses) {
      // Simpan nama baru supaya header profil ikut berubah
      await SimpanToken.saveUserName(req.nama);
      if (!mounted) return;
      // Kirim nama baru ke halaman sebelumnya
      Navigator.pop(context, req.nama);
    }
  }

  InputDecoration _dekorasi(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Profil'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _namaC,
                      textCapitalization: TextCapitalization.words,
                      decoration: _dekorasi('Nama', Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailC,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _dekorasi('Email', Icons.email_outlined),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noHpC,
                      keyboardType: TextInputType.phone,
                      decoration:
                          _dekorasi('No. HP (opsional)', Icons.phone_outlined),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _menyimpan ? null : _simpan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _menyimpan
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}