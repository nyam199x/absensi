import 'dart:async';
import 'dart:developer';

import 'package:absensi/service/simpan_token.dart';
import 'package:absensi/view/dashboard/dashboard.dart';
import 'package:absensi/view/autentikasi/login.dart';
import 'package:dio/dio.dart';
import 'package:absensi/service/dio_service.dart';
import 'package:absensi/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

/// Screen Check in / Check out dengan Google Maps dan lokasi pengguna.
/// Bisa dipakai layar penuh (dari tombol Clock In/Out) atau sebagai tab.
class MapsScreen extends StatefulWidget {
  final bool isCheckIn;
  final bool embedded; // true = dipakai sebagai tab (tanpa tombol back)
  final VoidCallback? onSuccess;

  const MapsScreen({
    super.key,
    required this.isCheckIn,
    this.embedded = false,
    this.onSuccess,
  });

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  static const Color _blue = Color(0xFF5B84E8);

  final Geocoding geocoding = Geocoding();
  final TextEditingController _noteController = TextEditingController();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = "Mencari Lokasi...";
  final Set<Marker> _markers = {};
  bool _isLoading = false;
  bool _hasCheckedIn = false;
  late final ApiService _apiService = ApiService(createDioService());
  late Timer _timer;
  String _currentTime = DateFormat('hh:mm a').format(DateTime.now());

  final LatLng _defaultLocation = const LatLng(-6.2000, 108.8166666);

  String get _actionLabel => widget.isCheckIn ? 'Check in' : 'Check out';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentTime = DateFormat('hh:mm a').format(DateTime.now());
      });
    });
    _checkPermissionsAndGetLocation();
  }

  @override
  void dispose() {
    _timer.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() {
        _currentAddress = "Layanan lokasi (GPS) dinonaktifkan.";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        setState(() {
          _currentAddress = "Izin akses lokasi ditolak.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() {
        _currentAddress =
            "Izin lokasi ditolak permanen. Aktifkan lewat pengaturan.";
      });
      return;
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });

      log("Posisi user: $position");
      _updateMarkerAndCamera(position);
      await _getAddressFromLatLng(position);
    } catch (e) {
      log("Error getting location: $e");
      if (!mounted) return;
      setState(() {
        _currentAddress = "Gagal mengambil titik lokasi terkini.";
      });
    }
  }

  void _updateMarkerAndCamera(Position position) {
    LatLng currentLatLng = LatLng(position.latitude, position.longitude);
    if (!mounted) return;

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: currentLatLng,
          infoWindow: const InfoWindow(title: "Lokasi Anda"),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: currentLatLng, zoom: 15),
      ),
    );
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final addressParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.postalCode,
        ].where((part) => part != null && part.isNotEmpty).toList();

        if (!mounted) return;
        setState(() {
          _currentAddress = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : "Alamat tidak ditemukan.";
        });
      }
    } catch (e) {
      log("Error getting address: $e");
      if (!mounted) return;
      setState(() {
        _currentAddress = "Gagal mengonversi koordinat ke alamat.";
      });
    }
  }

  /// Kirim data check in / check out ke server.
  Future<dynamic> _kirimAbsen() async {
    final now = DateTime.now();
    final tanggal = DateFormat('yyyy-MM-dd').format(now);
    final jam = DateFormat('HH:mm').format(now);

    final position = _currentPosition;
    if (position == null) {
      throw StateError('Lokasi belum tersedia.');
    }

    final lat = position.latitude;
    final lng = position.longitude;

    log('========== MULAI KIRIM ABSEN ==========');
    log('Tanggal : $tanggal');
    log('Jam     : $jam');
    log('Lat     : $lat');
    log('Lng     : $lng');
    log('Check In? : ${widget.isCheckIn}');

    try {
      if (widget.isCheckIn) {
        final body = {
          'attendance_date': tanggal,
          'check_in': jam,
          'check_in_lat': lat,
          'check_in_lng': lng,
          'check_in_location': _currentAddress,
          'check_in_address': _currentAddress,
          'status': 'masuk',
          'note': _noteController.text.trim(),
        };

        log('CHECK-IN BODY: $body');
        log('MEMANGGIL API /api/absen/check-in ...');

        final res = await _apiService
            .checkIn(body)
            .timeout(const Duration(seconds: 20));

        log('CHECK-IN RESPONSE: $res');
        log('========== CHECK-IN SELESAI ==========');

        return res;
      }

      final body = {
        'attendance_date': tanggal,
        'check_out': jam,
        'check_out_lat': lat,
        'check_out_lng': lng,
        'check_out_location': _currentAddress,
        'check_out_address': _currentAddress,
      };

      log('CHECK-OUT BODY: $body');
      log('MEMANGGIL API /api/absen/check-out ...');

      final res = await _apiService
          .checkOut(body)
          .timeout(const Duration(seconds: 20));

      log('CHECK-OUT RESPONSE: $res');
      log('========== CHECK-OUT SELESAI ==========');

      return res;
    } on TimeoutException {
      log('ABSEN TIMEOUT: server tidak merespons dalam 20 detik');
      throw DioException(
        requestOptions: RequestOptions(
          path: widget.isCheckIn
              ? '/api/absen/check-in'
              : '/api/absen/check-out',
        ),
        type: DioExceptionType.receiveTimeout,
        error: 'Server tidak merespons dalam 20 detik.',
      );
    } catch (e, stack) {
      log('ABSEN API ERROR: $e', stackTrace: stack);
      rethrow;
    }
  }

  bool _isAlreadyCheckedIn(dynamic response) {
    if (response == null) return false;

    final raw = response is Response
        ? response.data.toString()
        : response.toString();

    // Samakan "check-in", "check in", "checkin" supaya mudah dicocokkan
    final text = raw
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('checkin', 'check in');

    final sudahId = text.contains('sudah') && text.contains('check in');
    final sudahEn = text.contains('already') && text.contains('check in');
    return sudahId || sudahEn;
  }

  /// Setelah check-in/check-out berhasil, langsung buka Dashboard.
  /// Tidak bergantung pada embedded atau onSuccess.
  Future<void> _finishAttendance() async {
    if (!mounted) return;

    log('NAVIGATE -> DASHBOARD');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Dashboard()),
      (route) => false,
    );
  }

  /// Sesi tidak ada / tidak sah: tampilkan pesan lalu kembali ke Login.
  void _keLogin(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;

    if (_currentPosition == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi belum ditemukan. Tunggu GPS mendapatkan lokasi.',
          ),
        ),
      );
      return;
    }

    // Kunci tombol sebelum operasi async supaya tidak terkirim berkali-kali.
    setState(() => _isLoading = true);

    try {
      final token = await SimpanToken.getToken();

      debugPrint('TOKEN SAAT ABSEN ADA? ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        _keLogin('Sesi login tidak ditemukan, silakan login ulang');
        return;
      }

      log('TOKEN ADA -> LANJUT KE API');

      final response = await _kirimAbsen();

      log('HASIL ABSEN: $response');

      if (!mounted) return;

      // Server menganggap check-in hari ini sudah ada.
      // Ini bukan alasan untuk tetap di halaman Maps.
      if (widget.isCheckIn && _isAlreadyCheckedIn(response)) {
        setState(() => _hasCheckedIn = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah melakukan check in hari ini'),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        await _finishAttendance();
        return;
      }

      // Request berhasil.
      if (widget.isCheckIn) {
        setState(() => _hasCheckedIn = true);
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Berhasil $_actionLabel')));

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      await _finishAttendance();
    } on DioException catch (e, stack) {
      log(
        'ERROR ABSEN DIO: '
        'status=${e.response?.statusCode}, '
        'data=${e.response?.data}, '
        'type=${e.type}, '
        'error=${e.error}',
        stackTrace: stack,
      );

      if (e.response?.statusCode == 401) {
        await SimpanToken.clearSession();

        if (!mounted) return;

        _keLogin('Sesi berakhir, silakan login ulang');
        return;
      }

      final body = e.response?.data;

      // Duplicate check-in bisa datang sebagai HTTP error.
      if (widget.isCheckIn &&
          (e.response?.statusCode == 409 || _isAlreadyCheckedIn(body))) {
        if (!mounted) return;

        setState(() => _hasCheckedIn = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda sudah melakukan check in hari ini'),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 300));

        if (!mounted) return;

        await _finishAttendance();
        return;
      }

      String pesan = 'Gagal $_actionLabel, coba lagi';

      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        pesan = 'Server tidak merespons. Periksa koneksi internet/API.';
      } else if (body is Map) {
        if (body['message'] != null) {
          pesan = body['message'].toString();
        } else if (body['error'] != null) {
          pesan = body['error'].toString();
        }
      } else if (body != null) {
        pesan = body.toString();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(pesan)));
    } catch (e, stack) {
      log('ERROR ABSEN GENERAL: $e', stackTrace: stack);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal $_actionLabel: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : _defaultLocation,
              zoom: 13.0,
            ),
            padding: const EdgeInsets.only(bottom: 300),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _updateMarkerAndCamera(_currentPosition!);
              }
            },
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  widget.embedded
                      ? const SizedBox(width: 38)
                      : _circleButton(
                          icon: Icons.arrow_back,
                          onTap: () => Navigator.maybePop(context),
                        ),
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                  ),
                  _circleButton(
                    icon: Icons.refresh,
                    onTap: _checkPermissionsAndGetLocation,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 260,
                  decoration: const BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.50),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, -2),
                      ),
                    ],
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
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _actionLabel,
                          style: const TextStyle(
                            color: _blue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Location',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentAddress,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          const Icon(Icons.notes, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                hintText: 'Note(Optional)',
                                isDense: true,
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          const Text(
                            'Status : ',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            widget.isCheckIn
                                ? (_hasCheckedIn
                                      ? 'Sudah Check in'
                                      : 'Belum Check in')
                                : 'Belum Check out',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.isCheckIn ? 'Check In' : 'Check Out',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: _blue,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
