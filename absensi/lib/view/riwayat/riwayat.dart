import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:absensi/reusable/app_colors.dart';

import '../../service/absen_service.dart';
import '../../service/api_service.dart';
import '../../service/dio_service.dart';

class RiwayatPage extends StatefulWidget {
  /// Naikkan nilainya dari luar untuk memuat ulang riwayat (mis. setelah check in).
  final int refreshKey;

  /// Dipanggil setelah data absen dihapus, supaya Home ikut dimuat ulang.
  final VoidCallback? onChanged;
  const RiwayatPage({super.key, this.refreshKey = 0, this.onChanged});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _AbsenItem {
  final String? id;
  final DateTime? tanggal;
  final String masuk;
  final String pulang;
  final String? keterangan;
  final bool sakit;
  _AbsenItem({
    this.id,
    this.tanggal,
    required this.masuk,
    required this.pulang,
    this.keterangan,
    this.sakit = false,
  });
}

class _RiwayatPageState extends State<RiwayatPage> {
  static const List<String> _bulan = [
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

  late final ApiService _apiService = ApiService(createDioService());
  final ScrollController _chipController = ScrollController();

  final int _year = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = true;
  bool _menghapus = false;
  String? _error;
  List<_AbsenItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
    // Chip bulan berakhir di bulan ini, jadi langsung geser ke ujung kanan.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chipController.hasClients) {
        _chipController.jumpTo(_chipController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(covariant RiwayatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) _load();
  }

  @override
  void dispose() {
    _chipController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final fmt = DateFormat('yyyy-MM-dd');
    final start = fmt.format(DateTime(_year, _selectedMonth, 1));
    final end = fmt.format(DateTime(_year, _selectedMonth + 1, 0));

    try {
      final result = await _apiService.getAbsenHistory(start, end);
      debugPrint('RIWAYAT: $result');

      final list = result is List
          ? result
          : (result is Map && result['data'] is List)
          ? result['data'] as List
          : <dynamic>[];

      final items =
          list
              .whereType<Map>()
              .map(_parse)
              .where(
                (e) =>
                    e.tanggal == null ||
                    (e.tanggal!.month == _selectedMonth &&
                        e.tanggal!.year == _year),
              )
              .toList()
            ..sort(
              (a, b) => (b.tanggal ?? DateTime(0)).compareTo(
                a.tanggal ?? DateTime(0),
              ),
            );

      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on DioException catch (e) {
      final body = e.response?.data;
      final pesan = body is Map && body['message'] != null
          ? body['message'].toString()
          : 'Gagal memuat riwayat (${e.response?.statusCode ?? "tanpa koneksi"})';
      if (!mounted) return;
      setState(() {
        _error = pesan;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error riwayat: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan saat memuat riwayat';
        _isLoading = false;
      });
    }
  }

  _AbsenItem _parse(Map m) {
    final masuk = _keWaktuLokal(m['check_in_time'] ?? m['check_in']);
    final pulang = _keWaktuLokal(m['check_out_time'] ?? m['check_out']);
    final tgl =
        masuk ??
        _parseTanggal(m['attendance_date']) ??
        _keWaktuLokal(m['created_at']);

    final alasan = (m['alasan_izin'] ?? '').toString().trim();
    final status = (m['status'] ?? '').toString().toLowerCase();
    final izin = status.contains('izin') || alasan.isNotEmpty;
    final sakit =
        alasan.toLowerCase().startsWith('sakit') || status.contains('sakit');

    final idRaw = m['id']?.toString();

    return _AbsenItem(
      id: (idRaw == null || idRaw.isEmpty) ? null : idRaw,
      tanggal: tgl == null ? null : DateTime(tgl.year, tgl.month, tgl.day),
      masuk: izin ? _fmtJam(null) : _fmtJam(masuk),
      pulang: izin ? _fmtJam(null) : _fmtJam(pulang),
      keterangan: alasan.isEmpty ? null : alasan,
      sakit: sakit,
    );
  }

  /// Tanggal murni (yyyy-MM-dd) dibaca sebagai tanggal lokal, tanpa konversi zona.
  DateTime? _parseTanggal(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    if (s.length == 10) return DateTime.tryParse(s);
    return _keWaktuLokal(s);
  }

  /// Waktu dari server dianggap UTC lalu diubah ke zona waktu perangkat.
  DateTime? _keWaktuLokal(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final iso = s.contains('T') ? s : s.replaceFirst(' ', 'T');
    final adaZona =
        iso.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(iso);
    return DateTime.tryParse(adaZona ? iso : '${iso}Z')?.toLocal();
  }

  String _fmtJam(DateTime? d) =>
      d == null ? '-- : -- : --' : DateFormat('HH : mm : ss').format(d);

  Future<void> _konfirmasiHapus(_AbsenItem item) async {
    if (_menghapus || item.id == null) return;

    final tgl = item.tanggal;
    final label = tgl == null ? 'ini' : '${tgl.day}/${tgl.month}/${tgl.year}';

    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus data absen'),
        content: Text(
          'Hapus data absen tanggal $label? '
          'Setelah dihapus, kamu bisa check in ulang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    setState(() => _menghapus = true);
    final hasil = await AbsenService.hapus(item.id!);
    if (!mounted) return;
    setState(() => _menghapus = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(hasil.pesan)));

    if (hasil.sukses) {
      await _load();
      widget.onChanged?.call();
    }
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
            color: AppColors.historyGlassBackground,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.historyGlassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.historyGlassShadow,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.historyBackgroundTop,
            AppColors.historyBackgroundMiddle,
            AppColors.historyBackgroundBottom,
          ],
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat Kehadiran',
                style: TextStyle(
                  color: AppColors.historyText,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: AppColors.historyDivider,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.historyPrimary,
              backgroundColor: AppColors.historyText,
              onRefresh: _load,
              child: _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return _glassContainer(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          controller: _chipController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: DateTime.now().month,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final bulan = i + 1;
            final selected = bulan == _selectedMonth;
            return GestureDetector(
              onTap: () {
                if (selected) return;
                setState(() => _selectedMonth = bulan);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.historySelectedChipBackground
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: selected
                        ? AppColors.historySelectedChipBorder
                        : AppColors.historyUnselectedChipBorder,
                  ),
                ),
                child: Text(
                  _bulan[i],
                  style: TextStyle(
                    color: AppColors.historyText,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildList() {
    const physics = AlwaysScrollableScrollPhysics();

    if (_isLoading) {
      return ListView(
        physics: physics,
        children: const [
          SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(color: AppColors.historyText),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: physics,
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.historyTextSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.historyTextSecondary),
          ),
          TextButton(
            onPressed: _load,
            child: const Text(
              'Coba lagi',
              style: TextStyle(color: AppColors.historyText),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: physics,
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          const Icon(
            Icons.event_busy,
            size: 48,
            color: AppColors.historyTextSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada data absen di bulan ${_bulan[_selectedMonth - 1]}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.historyTextSecondary),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: physics,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _items.length,
      itemBuilder: (_, i) => _buildCard(_items[i]),
    );
  }

  Widget _buildCard(_AbsenItem item) {
    final tgl = item.tanggal;
    final ket = item.keterangan;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _glassContainer(
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 84,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.historyDateBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.historyDateBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          tgl == null ? '-' : '${tgl.day}',
                          style: const TextStyle(
                            color: AppColors.historyText,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tgl == null ? '' : DateFormat('EEEE').format(tgl),
                          style: const TextStyle(
                            color: AppColors.historyText,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _waktu('Check In', item.masuk)),
                  VerticalDivider(
                    color: AppColors.historyTimeDivider,
                    thickness: 1,
                    width: 16,
                  ),
                  Expanded(child: _waktu('Check Out', item.pulang)),
                ],
              ),
            ),
            if (ket != null && ket.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.historyNoteBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.historyNoteBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      item.sakit
                          ? Icons.medical_services_outlined
                          : Icons.edit_note,
                      size: 18,
                      color: item.sakit
                          ? AppColors.historySickIcon
                          : AppColors.historyNoteIcon,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ket,
                        style: const TextStyle(
                          color: AppColors.historyText,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (item.id != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _menghapus ? null : () => _konfirmasiHapus(item),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.historyDelete,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
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
        Text(
          label,
          style: const TextStyle(
            color: AppColors.historyTextSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          jam,
          style: const TextStyle(
            color: AppColors.historyText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
