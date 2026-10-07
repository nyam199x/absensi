import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AbsenItem {
  final DateTime? tanggal; // tanggal lokal tanpa jam
  final DateTime? masuk;
  final DateTime? pulang;
  final String? alamatMasuk;
  final String status;

  AbsenItem({
    this.tanggal,
    this.masuk,
    this.pulang,
    this.alamatMasuk,
    this.status = '',
  });

  factory AbsenItem.fromMap(Map m) {
    final masuk = _waktu(m['check_in_time'] ?? m['check_in']);
    final pulang = _waktu(m['check_out_time'] ?? m['check_out']);
    final t = masuk ?? _waktu(m['created_at']);
    return AbsenItem(
      tanggal: t == null ? null : DateTime(t.year, t.month, t.day),
      masuk: masuk,
      pulang: pulang,
      alamatMasuk: m['check_in_address']?.toString(),
      status: (m['status'] ?? '').toString().toLowerCase(),
    );
  }

  bool get hariIni {
    final n = DateTime.now();
    final t = tanggal;
    return t != null && t.year == n.year && t.month == n.month && t.day == n.day;
  }

  /// Waktu dari server dianggap UTC lalu diubah ke zona waktu perangkat.
  static DateTime? _waktu(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    final adaZona =
        iso.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(iso);
    return DateTime.tryParse(adaZona ? iso : '${iso}Z')?.toLocal();
  }
}

String formatJam(DateTime? d) =>
    d == null ? '-- : -- : --' : DateFormat('HH : mm : ss').format(d);

class AbsenCard extends StatelessWidget {
  final AbsenItem item;
  const AbsenCard({super.key, required this.item});

  static const Color _primary = Color.fromARGB(255, 17, 35, 95);

  @override
  Widget build(BuildContext context) {
    final tgl = item.tanggal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDFE3EF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    tgl == null ? '-' : '${tgl.day}',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    tgl == null ? '' : DateFormat('EEEE').format(tgl),
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: _waktu('Check In', formatJam(item.masuk))),
            const VerticalDivider(color: Colors.white, thickness: 1, width: 16),
            Expanded(child: _waktu('Check Out', formatJam(item.pulang))),
          ],
        ),
      ),
    );
  }

  Widget _waktu(String label, String jam) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _primary, fontSize: 14)),
        const SizedBox(height: 8),
        Text(
          jam,
          style: const TextStyle(
            color: _primary,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}