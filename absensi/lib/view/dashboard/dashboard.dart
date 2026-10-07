import 'dart:ui';
import 'dart:async';

import 'package:absensi/reusable/app_colors.dart';
import 'package:nav_bar/nav_bar.dart';
import 'package:absensi/service/foto_service.dart';
import 'package:absensi/service/izin_service.dart';
import 'package:absensi/view/profile/profil.dart';
import 'package:absensi/view/widget/absen_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../model/absen_model.dart';
import '../../service/api_service.dart';
import '../../service/dio_service.dart';
import '../../service/simpan_token.dart';

import 'package:absensi/view/maps/maps_screen.dart';
import 'package:absensi/view/riwayat/riwayat.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  // 0 = Home, 1 = Map, 2 = History, 3 = Profile
  int _selectedIndex = 0;

  late final ApiService _apiService = ApiService(createDioService());

  String _userName = '';
  String _today = '';
  String _clock = DateFormat('HH:mm:ss').format(DateTime.now());
  Timer? _clockTimer;
  AbsenStat? _stat;
  bool _isLoadingStat = true;
  int _riwayatRefresh = 0;
  List<AbsenItem> _items = [];
  AbsenItem? _hariIni;
  int _totalSakit = 0;

  @override
  void initState() {
    super.initState();
    _initDate();
    _loadUser();
    _loadStat();
    FotoService.muat();
    _startClock();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      setState(() {
        _clock = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    });
  }

  Future<void> _initDate() async {
    await initializeDateFormatting('id_ID');

    if (!mounted) return;

    setState(() {
      _today = DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now());
    });
  }

  Future<void> _loadUser() async {
    try {
      final name = await SimpanToken.getUserName();

      if (!mounted) return;

      setState(() {
        _userName = (name != null && name.isNotEmpty) ? name : 'Pengguna';
      });
    } catch (e) {
      debugPrint('Gagal load user: $e');

      if (!mounted) return;

      setState(() => _userName = 'Pengguna');
    }
  }

  /// Data absen dianggap "sakit" jika statusnya sakit, atau alasan izinnya
  /// diawali kata "Sakit" (format yang dikirim dari tombol Sakit di Home).
  bool _isSakit(Map m) {
    final status = (m['status'] ?? '').toString().toLowerCase();
    final alasan = (m['alasan_izin'] ?? '').toString().toLowerCase().trim();
    return status.contains('sakit') || alasan.startsWith('sakit');
  }

  Future<void> _loadStat() async {
    try {
      final now = DateTime.now();
      final fmt = DateFormat('yyyy-MM-dd');

      final start = fmt.format(DateTime(now.year, now.month, 1));

      final end = fmt.format(now);

      final result = await _apiService.getAbsenHistory(start, end);

      final list = result is List
          ? result
          : (result is Map && result['data'] is List)
          ? result['data'] as List
          : <dynamic>[];

      final sakit = list.whereType<Map>().where(_isSakit).length;

      final items =
          list
              .whereType<Map>()
              .map(AbsenItem.fromMap)
              .where(
                (e) =>
                    e.tanggal != null &&
                    e.tanggal!.year == now.year &&
                    e.tanggal!.month == now.month,
              )
              .toList()
            ..sort(
              (a, b) =>
                  (b.masuk ?? b.tanggal!).compareTo(a.masuk ?? a.tanggal!),
            );

      if (!mounted) return;

      final dasar = _hitungStat(items);

      setState(() {
        _items = items;
        _hariIni = items.where((e) => e.hariIni).firstOrNull;
        _totalSakit = sakit;
        // Sakit dihitung terpisah, jadi dikeluarkan dari hitungan Izin
        _stat = AbsenStat(
          totalHadir: dasar.totalHadir,
          totalTerlambat: dasar.totalTerlambat,
          totalIzin: dasar.totalIzin > sakit ? dasar.totalIzin - sakit : 0,
        );
        _isLoadingStat = false;
      });
    } catch (e) {
      debugPrint('Gagal load statistik: $e');

      if (!mounted) return;

      setState(() => _isLoadingStat = false);
    }
  }

  AbsenStat _hitungStat(List<AbsenItem> items) {
    int hadir = 0;
    int terlambat = 0;
    int izin = 0;

    for (final item in items) {
      if (item.status.contains('izin')) {
        izin++;
        continue;
      }

      hadir++;

      if (item.status.contains('telat') ||
          item.status.contains('terlambat') ||
          item.status == 'late') {
        terlambat++;
      }
    }

    return AbsenStat(
      totalHadir: hadir,
      totalTerlambat: terlambat,
      totalIzin: izin,
    );
  }

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';

    return 'Selamat Malam';
  }

  Future<void> _onAbsenBerhasil() async {
    if (!mounted) return;

    setState(() {
      _isLoadingStat = true;
      _riwayatRefresh++;
    });

    await _loadStat();
  }

  /// Dipakai tombol Clock In / Clock Out di kartu Home
  Future<void> _goToAbsen({required bool isCheckIn}) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => MapsScreen(isCheckIn: isCheckIn)),
    );

    if (berhasil == true) {
      await _onAbsenBerhasil();
    }
  }

  /// Buka form keterangan sakit. Jika terkirim, muat ulang statistik dan
  /// riwayat supaya keterangannya langsung tampil.
  Future<void> _bukaFormSakit() async {
    final berhasil = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _IzinSheet(),
    );

    if (berhasil == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan berhasil dikirim')),
      );
      // Pindah ke tab Riwayat, lalu muat ulang datanya
      _onNavTap(2);
      await _onAbsenBerhasil();
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // ============================================================
  // GLASSMORPHISM HELPER
  // HANYA DIGUNAKAN UNTUK HOME
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
            color: AppColors.glassBackground,
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.glassBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.glassShadow,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            height: double.infinity,

            // PENTING:
            // Jangan beri gradient di sini.
            // History dan Profile tetap menggunakan
            // background dari file masing-masing.
            color: AppColors.textWhite,

            child: IndexedStack(
              index: _selectedIndex,
              sizing: StackFit.expand,

              children: [
                // HOME
                _buildHomeContent(),

                // MAP
                // Tetap menggunakan desain MapsScreen.
                _selectedIndex == 1 ? _buildMapTab() : const SizedBox.shrink(),

                // HISTORY
                // Desain tetap berada di riwayat.dart
                RiwayatPage(refreshKey: _riwayatRefresh, onChanged: _loadStat),

                // PROFILE
                // Desain tetap berada di profil.dart
                const ProfilPage(),
              ],
            ),
          ),
        ),

        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNav() {
    return FuturisticNavBar(
      selectedIndex: _selectedIndex,
      onItemSelected: _onNavTap,
      style: NavBarStyle.obsidian,
      blurSigma: 15.0,
      theme: FuturisticTheme.molten(),
      items: [
        NavBarItem(icon: Icons.home_outlined, label: 'Home'),
        NavBarItem(icon: Icons.map_outlined, label: 'Map'),
        NavBarItem(icon: Icons.access_time, label: 'History'),
        NavBarItem(icon: Icons.person_outline, label: 'Profile'),
      ],
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMapTab() {
    return MapsScreen(
      isCheckIn: _hariIni?.masuk == null,
      embedded: true,
      onSuccess: _onAbsenBerhasil,
    );
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHomeContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.backgroundTop,
            AppColors.backgroundMiddle,
            AppColors.backgroundBottom,
          ],
        ),
      ),

      child: RefreshIndicator(
        onRefresh: _loadStat,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              // ==================================================
              // HEADER HOME
              // ==================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [
                    _buildProfileRow(),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _today,
                            style: const TextStyle(
                              color: AppColors.textWhite70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _clock,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _buildTodayCard(),

                    // Tombol keterangan sakit / izin
                    const SizedBox(height: 12),
                    _buildSakitButton(),
                  ],
                ),
              ),

              // ==================================================
              // STATISTICS
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),

                child: _buildStatCards(),
              ),

              // ==================================================
              // HISTORY TITLE
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),

                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Riwayat Kehadiran',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () => _onNavTap(2),

                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(color: AppColors.textWhite),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // HISTORY LIST
              // ==================================================
              if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),

                  child: Text(
                    'Belum ada data absen bulan ini',
                    textAlign: TextAlign.center,

                    style: TextStyle(color: AppColors.textWhite70),
                  ),
                )
              else
                ..._items
                    .take(5)
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

                        child: AbsenCard(item: e),
                      ),
                    ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE ROW
  // ============================================================

  Widget _buildProfileRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textWhite38, width: 2),
            ),
            child: ValueListenableBuilder<Uint8List?>(
              valueListenable: FotoService.foto,
              builder: (context, foto, child) {
                return CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.avatarBackground,
                  backgroundImage: foto != null ? MemoryImage(foto) : null,
                  child: foto == null
                      ? const Icon(
                          Icons.person,
                          size: 34,
                          color: AppColors.textWhite,
                        )
                      : null,
                );
              },
            ),
          ),

          const SizedBox(width: 14),

          // Nama dan sapaan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TODAY CARD
  // ============================================================

  Widget _buildTodayCard() {
    final masuk = _hariIni?.masuk;
    final pulang = _hariIni?.pulang;
    final alamat = _hariIni?.alamatMasuk;

    return _glassContainer(
      padding: const EdgeInsets.all(14),

      borderRadius: BorderRadius.circular(22),

      child: Column(
        children: [
          // Lokasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textWhite,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  (alamat != null && alamat.isNotEmpty)
                      ? alamat
                      : 'Lokasi akan tercatat saat check in',

                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Check In / Check Out
          ClipRRect(
            borderRadius: BorderRadius.circular(15),

            child: Container(
              decoration: BoxDecoration(
                color: AppColors.glassLight,

                border: Border.all(color: AppColors.buttonBackground),

                borderRadius: BorderRadius.circular(15),
              ),

              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _slotWaktu(
                        label: 'Check In',

                        jam: formatJam(masuk),

                        aksi: masuk == null
                            ? _aksiButton(
                                'Check In',
                                () => _goToAbsen(isCheckIn: true),
                              )
                            : null,
                      ),
                    ),

                    VerticalDivider(
                      color: AppColors.textWhite30,

                      thickness: 1,

                      width: 1,
                    ),

                    Expanded(
                      child: _slotWaktu(
                        label: 'Check Out',

                        jam: formatJam(pulang),

                        aksi: (masuk != null && pulang == null)
                            ? _aksiButton(
                                'Check Out',
                                () => _goToAbsen(isCheckIn: false),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOMBOL KETERANGAN SAKIT
  // ============================================================

  Widget _buildSakitButton() {
    return GestureDetector(
      onTap: _bukaFormSakit,
      behavior: HitTestBehavior.opaque,
      child: _glassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(18),
        child: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.sakit),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Sakit / Izin? Ajukan keterangan',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textWhite),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIME SLOT
  // ============================================================

  Widget _slotWaktu({
    required String label,
    required String jam,
    Widget? aksi,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,

            style: const TextStyle(
              color: AppColors.textWhite70,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            jam,

            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (aksi != null) ...[const SizedBox(height: 10), aksi],
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTON
  // ============================================================

  Widget _aksiButton(String text, VoidCallback onTap) {
    return SizedBox(
      height: 30,

      child: ElevatedButton(
        onPressed: onTap,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBackground,

          foregroundColor: AppColors.buttonText,

          elevation: 0,

          padding: const EdgeInsets.symmetric(horizontal: 12),

          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),

            side: BorderSide(color: AppColors.textWhite30),
          ),
        ),

        child: Text(text),
      ),
    );
  }

  // ============================================================
  // STAT CARDS
  // ============================================================

  Widget _buildStatCards() {
    final hadir = _stat?.totalHadir ?? 0;

    final izin = _stat?.totalIzin ?? 0;

    Widget statCard(String label, int value, Color color) {
      return Expanded(
        child: _glassContainer(
          padding: const EdgeInsets.symmetric(vertical: 14),

          borderRadius: BorderRadius.circular(16),

          child: Column(
            children: [
              _isLoadingStat
                  ? const SizedBox(
                      height: 20,
                      width: 20,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textWhite,
                      ),
                    )
                  : Text(
                      '$value',

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),

              const SizedBox(height: 4),

              Text(
                label,

                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textWhite70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        statCard('Hadir', hadir, AppColors.hadir),

        const SizedBox(width: 10),

        statCard('Sakit', _totalSakit, AppColors.sakit),

        const SizedBox(width: 10),

        statCard('Izin', izin, AppColors.izin),
      ],
    );
  }
}

// ==============================================================
// FORM KETERANGAN SAKIT / IZIN (bottom sheet)
// ==============================================================

class _IzinSheet extends StatefulWidget {
  const _IzinSheet();

  @override
  State<_IzinSheet> createState() => _IzinSheetState();
}

class _IzinSheetState extends State<_IzinSheet> {
  final TextEditingController _catatanC = TextEditingController();
  bool _sakit = true; // true = Sakit, false = Izin
  bool _mengirim = false;
  String? _error;

  @override
  void dispose() {
    _catatanC.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final catatan = _catatanC.text.trim();
    if (catatan.length < 3) {
      setState(() => _error = 'Tulis keterangan minimal 3 karakter');
      return;
    }

    setState(() {
      _mengirim = true;
      _error = null;
    });

    final hasil = await IzinService.ajukan(sakit: _sakit, catatan: catatan);
    if (!mounted) return;

    if (hasil.sukses) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _mengirim = false;
        _error = hasil.pesan;
      });
    }
  }

  Widget _pilihan(String label, bool nilaiSakit) {
    final dipilih = _sakit == nilaiSakit;
    return ChoiceChip(
      label: Text(label),
      selected: dipilih,
      showCheckmark: false,
      onSelected: _mengirim ? null : (_) => setState(() => _sakit = nilaiSakit),
      selectedColor: AppColors.choiceChipBackground,
      backgroundColor: AppColors.choiceChipBackground,
      side: BorderSide(
        color: dipilih ? AppColors.textWhite : AppColors.choiceChipBorder,
      ),
      labelStyle: TextStyle(
        color: AppColors.textWhite,
        fontWeight: dipilih ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundTop,
              AppColors.backgroundMiddle,
              AppColors.backgroundBottom,
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textWhite38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keterangan Sakit / Izin',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.now()),
              style: const TextStyle(
                color: AppColors.textWhite70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _pilihan('Sakit', true),
                const SizedBox(width: 10),
                _pilihan('Izin', false),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _catatanC,
              maxLines: 4,
              minLines: 3,
              enabled: !_mengirim,
              cursorColor: AppColors.textWhite,
              style: const TextStyle(color: AppColors.textWhite),
              decoration: InputDecoration(
                hintText: _sakit
                    ? 'Contoh: demam dan flu, istirahat di rumah'
                    : 'Contoh: keperluan keluarga',
                hintStyle: const TextStyle(color: AppColors.textWhite54),
                filled: true,
                fillColor: AppColors.glassLight,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.textWhite30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.textWhite),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.textWhite24),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _mengirim ? null : _kirim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textWhite,
                  foregroundColor: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _mengirim
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Kirim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
