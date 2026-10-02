import 'package:absensi/service/dio_service.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class IzinHasil {
  final bool sukses;
  final String pesan;
  const IzinHasil({required this.sukses, required this.pesan});
}

class IzinService {
  static const String _baseUrl = 'https://absensib1.mobileprojp.com/api';

  // Server tidak punya endpoint izin tersendiri. Izin/sakit dikirim lewat
  // endpoint check-in dengan status "izin" (server meminta data lokasi juga,
  // sama seperti check-in biasa).
  static const String _pathIzin = '/absen/check-in';

  static final Dio _dio = createDioService();

  /// Ambil lokasi saat ini. Mengembalikan pesan error jika gagal.
  static Future<({Position? posisi, String? error})> _ambilLokasi() async {
    try {
      final aktif = await Geolocator.isLocationServiceEnabled();
      if (!aktif) {
        return (
          posisi: null,
          error: 'GPS dinonaktifkan. Aktifkan lokasi lalu coba lagi.',
        );
      }

      var izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        return (
          posisi: null,
          error: 'Izin lokasi ditolak. Aktifkan lewat pengaturan aplikasi.',
        );
      }

      final posisi = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return (posisi: posisi, error: null);
    } catch (e) {
      debugPrint('IZIN LOKASI ERROR: $e');
      return (
        posisi: null,
        error: 'Gagal mengambil lokasi. Pastikan GPS aktif lalu coba lagi.',
      );
    }
  }

  /// Ubah koordinat jadi alamat. Jika gagal, pakai teks koordinat.
  static Future<String> _alamat(double lat, double lng) async {
    try {
      final geocoding = Geocoding();
      final hasil = await geocoding.placemarkFromCoordinates(lat, lng);
      if (hasil.isNotEmpty) {
        final p = hasil.first;
        final bagian = [
          p.street,
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
          p.postalCode,
        ].where((e) => e != null && e.isNotEmpty).toList();
        if (bagian.isNotEmpty) return bagian.join(', ');
      }
    } catch (e) {
      debugPrint('IZIN ALAMAT ERROR: $e');
    }
    return '$lat, $lng';
  }

  /// Kirim keterangan sakit atau izin untuk hari ini.
  /// Teks disimpan dengan awalan "Sakit: " atau "Izin: " supaya bisa dikenali
  /// di Dashboard dan Riwayat.
  static Future<IzinHasil> ajukan({
    required bool sakit,
    required String catatan,
  }) async {
    final lokasi = await _ambilLokasi();
    final posisi = lokasi.posisi;
    if (posisi == null) {
      return IzinHasil(
        sukses: false,
        pesan: lokasi.error ?? 'Lokasi belum tersedia',
      );
    }

    final token = await SimpanToken.getToken();
    final sekarang = DateTime.now();
    final alamat = await _alamat(posisi.latitude, posisi.longitude);

    final data = {
      'attendance_date': DateFormat('yyyy-MM-dd').format(sekarang),
      'check_in': DateFormat('HH:mm').format(sekarang),
      'check_in_lat': posisi.latitude,
      'check_in_lng': posisi.longitude,
      'check_in_location': alamat,
      'check_in_address': alamat,
      'status': 'izin',
      'alasan_izin': '${sakit ? 'Sakit' : 'Izin'}: ${catatan.trim()}',
    };
    debugPrint('IZIN BODY: $data');

    try {
      final res = await _dio.post(
        '$_baseUrl$_pathIzin',
        data: data,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      debugPrint('IZIN: ${res.statusCode} ${res.data}');

      final kode = res.statusCode ?? 0;
      final ok = kode >= 200 && kode < 300;
      final body = res.data;
      final pesan = body is Map && body['message'] != null
          ? body['message'].toString()
          : (ok ? 'Keterangan terkirim' : 'Gagal mengirim keterangan');
      return IzinHasil(sukses: ok, pesan: pesan);
    } on DioException catch (e) {
      debugPrint('IZIN ERROR: ${e.response?.statusCode} ${e.response?.data}');
      return IzinHasil(sukses: false, pesan: _pesanError(e));
    } catch (e) {
      debugPrint('IZIN ERROR: $e');
      return const IzinHasil(sukses: false, pesan: 'Terjadi kesalahan');
    }
  }

  static String _pesanError(DioException e) {
    if (e.response == null) return 'Tidak dapat terhubung ke server';

    String pesan = 'Gagal mengirim keterangan (${e.response?.statusCode})';
    final body = e.response?.data;
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        pesan = (first is List && first.isNotEmpty)
            ? first.first.toString()
            : first.toString();
      } else if (body['message'] != null) {
        pesan = body['message'].toString();
      }
    }
    return pesan;
  }
}
