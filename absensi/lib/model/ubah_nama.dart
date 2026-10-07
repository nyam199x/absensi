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

    final req = UbahProfilRequest(nama: _namaC.text.trim());
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
        title: const Text('Ubah Nama'),
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

                    const SizedBox(height: 16),

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
