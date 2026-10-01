import 'package:absensi/model/profil_model.dart';
import 'package:absensi/service/profil_service.dart';
import 'package:flutter/material.dart';

class UbahKataSandiPage extends StatefulWidget {
  const UbahKataSandiPage({super.key});

  @override
  State<UbahKataSandiPage> createState() => _UbahKataSandiPageState();
}

class _UbahKataSandiPageState extends State<UbahKataSandiPage> {
  static const Color _primary = Color.fromARGB(255, 17, 35, 95);

  final _formKey = GlobalKey<FormState>();
  final _lamaC = TextEditingController();
  final _baruC = TextEditingController();
  final _konfirmasiC = TextEditingController();

  bool _lihatLama = false;
  bool _lihatBaru = false;
  bool _lihatKonfirmasi = false;
  bool _menyimpan = false;

  @override
  void dispose() {
    _lamaC.dispose();
    _baruC.dispose();
    _konfirmasiC.dispose();
    super.dispose();
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    final req = UbahKataSandiRequest(
      kataSandiLama: _lamaC.text,
      kataSandiBaru: _baruC.text,
      konfirmasiKataSandi: _konfirmasiC.text,
    );

    setState(() => _menyimpan = true);
    final hasil = await ProfilService.ubahKataSandi(req);
    if (!mounted) return;
    setState(() => _menyimpan = false);

    _snack(hasil.pesan);
    if (hasil.sukses) Navigator.pop(context, true);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required bool lihat,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !lihat,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(lihat ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                controller: _lamaC,
                label: 'Kata sandi lama',
                lihat: _lihatLama,
                onToggle: () => setState(() => _lihatLama = !_lihatLama),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Kata sandi lama wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _baruC,
                label: 'Kata sandi baru',
                lihat: _lihatBaru,
                onToggle: () => setState(() => _lihatBaru = !_lihatBaru),
                validator: (v) {
                  if (v == null || v.length < 6) {
                    return 'Minimal 6 karakter';
                  }
                  if (v == _lamaC.text) {
                    return 'Tidak boleh sama dengan kata sandi lama';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                controller: _konfirmasiC,
                label: 'Konfirmasi kata sandi baru',
                lihat: _lihatKonfirmasi,
                onToggle: () =>
                    setState(() => _lihatKonfirmasi = !_lihatKonfirmasi),
                validator: (v) =>
                    v != _baruC.text ? 'Konfirmasi tidak cocok' : null,
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
                      : const Text('Ubah Kata Sandi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}