import 'package:geolocator/geolocator.dart';

/// Kumpulan fungsi utilitas untuk mengelola permission dan pengambilan
/// lokasi user. Dipakai oleh MapsScreen atau fitur absen lain yang
/// membutuhkan koordinat GPS.
class LocationService {
  /// Memastikan GPS aktif dan permission sudah diberikan.
  /// Melempar String error yang bisa langsung ditampilkan ke user
  /// jika salah satu syarat tidak terpenuhi.
  static Future<void> ensureLocationReady() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Layanan lokasi (GPS) tidak aktif. Aktifkan GPS terlebih dahulu.';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Izin lokasi ditolak.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan aplikasi.';
    }
  }

  /// Mengambil posisi user saat ini dengan akurasi tinggi.
  /// Otomatis mengecek permission & GPS lebih dulu lewat [ensureLocationReady].
  static Future<Position> getCurrentPosition() async {
    await ensureLocationReady();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Mendengarkan perubahan posisi user secara realtime (streaming).
  /// Berguna kalau butuh update lokasi terus-menerus, misalnya saat
  /// menunjukkan pergerakan user di peta.
  ///
  /// [distanceFilterMeter] = jarak minimal (meter) sebelum update baru
  /// dikirim, untuk menghemat baterai & bandwidth.
  static Stream<Position> watchPosition({int distanceFilterMeter = 5}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeter,
      ),
    );
  }

  /// Menghitung jarak (dalam meter) antara dua koordinat.
  /// Berguna untuk validasi radius absen, misal user harus berada
  /// dalam radius 100 meter dari kantor.
  static double distanceBetweenMeter({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Cek apakah posisi user saat ini berada dalam radius tertentu
  /// dari titik target (misal lokasi kantor).
  static bool isWithinRadius({
    required Position currentPosition,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusMeter,
  }) {
    final jarak = distanceBetweenMeter(
      startLatitude: currentPosition.latitude,
      startLongitude: currentPosition.longitude,
      endLatitude: targetLatitude,
      endLongitude: targetLongitude,
    );
    return jarak <= radiusMeter;
  }
}