import 'dart:ui';

import 'package:nav_bar/nav_bar.dart';
import 'package:absensi/service/theme_services.dart';
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
  static const Color _primaryColor = Color.fromARGB(255, 17, 35, 95);

  // 0 = Home, 1 = Map, 2 = History, 3 = Profile
  int _selectedIndex = 0;

  late final ApiService _apiService = ApiService(createDioService());

  String _userName = '';
  String _today = '';
  AbsenStat? _stat;
  bool _isLoadingStat = true;
  int _riwayatRefresh = 0;
  List<AbsenItem> _items = [];
  AbsenItem? _hariIni;

  @override
  void initState() {
    super.initState();
    _initDate();
    _loadUser();
    _loadStat();
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

      setState(() {
        _items = items;
        _hariIni = items.where((e) => e.hariIni).firstOrNull;
        _stat = _hitungStat(items);
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _primaryColor,

        body: SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            height: double.infinity,

            // PENTING:
            // Jangan beri gradient di sini.
            // History dan Profile tetap menggunakan
            // background dari file masing-masing.
            color: Colors.white,

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
                RiwayatPage(refreshKey: _riwayatRefresh),

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
          colors: [Color(0xFF0D246B), Color(0xFF193E9A), Color(0xFF4169C1)],
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

                    Text(
                      _today,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildAttendanceBar(),

                    const SizedBox(height: 14),

                    _buildTodayCard(),
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
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () => _onNavTap(2),

                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(color: Colors.white),
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

                    style: TextStyle(color: Colors.white70),
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
    return Row(
      children: [
        // Avatar
        Container(
          padding: const EdgeInsets.all(2),

          decoration: BoxDecoration(
            shape: BoxShape.circle,

            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
          ),

          child: const CircleAvatar(
            radius: 30,

            backgroundColor: Color(0xFFF6D544),

            child: Icon(Icons.person, size: 34, color: Colors.white),
          ),
        ),

        const SizedBox(width: 14),

        // Nama
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                _greeting,

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _userName,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ],
          ),
        ),

        // Dark / Light Mode
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService.themeMode,

          builder: (context, mode, _) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),

                shape: BoxShape.circle,

                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),

              child: IconButton(
                icon: Icon(
                  mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,

                  color: Colors.white,
                ),

                onPressed: ThemeService.toggleTheme,
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // ATTENDANCE BAR
  // ============================================================

  Widget _buildAttendanceBar() {
    return GestureDetector(
      onTap: () => _onNavTap(1),

      child: _glassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        borderRadius: BorderRadius.circular(18),

        child: const Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: Colors.white),

            SizedBox(width: 16),

            Expanded(
              child: Text(
                'Take attendance today',

                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Icon(Icons.access_time, color: Colors.white),
          ],
        ),
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
                color: Colors.white,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  (alamat != null && alamat.isNotEmpty)
                      ? alamat
                      : 'Lokasi akan tercatat saat check in',

                  style: const TextStyle(fontSize: 12, color: Colors.white),
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
                color: Colors.white.withValues(alpha: 0.12),

                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),

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
                      color: Colors.white.withValues(alpha: 0.3),

                      thickness: 1,

                      width: 1,
                    ),

                    Expanded(
                      child: _slotWaktu(
                        label: 'Check Out',

                        jam: formatJam(pulang),

                        aksi: (masuk != null && pulang == null)
                            ? _aksiButton(
                                'Clock Out',
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
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            jam,

            style: const TextStyle(
              color: Colors.white,
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
          backgroundColor: Colors.white.withValues(alpha: 0.18),

          foregroundColor: Colors.white,

          elevation: 0,

          padding: const EdgeInsets.symmetric(horizontal: 12),

          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),

            side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
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

    final terlambat = _stat?.totalTerlambat ?? 0;

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
                        color: Colors.white,
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

                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        statCard('Hadir', hadir, Colors.greenAccent),

        const SizedBox(width: 10),

        statCard('Terlambat', terlambat, Colors.orangeAccent),

        const SizedBox(width: 10),

        statCard('Izin', izin, Colors.lightBlueAccent),
      ],
    );
  }
}
