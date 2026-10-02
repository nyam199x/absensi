import 'package:absensi/service/dio_service.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class HapusHasil {
  final bool sukses;
  final String pesan;
  const HapusHasil({required this.sukses, required this.pesan});
}

class AbsenService {
  static const String _baseUrl = 'https://absensib1.mobileprojp.com/api';

  static final Dio _dio = createDioService();

  /// Hapus satu data absen (DELETE /api/absen/{id}).
  /// Setelah dihapus, check in untuk hari itu bisa dilakukan ulang.
  static Future<HapusHasil> hapus(String id) async {
    final token = await SimpanToken.getToken();

    try {
      final res = await _dio.delete(
        '$_baseUrl/absen/$id',
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );
      debugPrint('HAPUS ABSEN: ${res.statusCode} ${res.data}');

      final kode = res.statusCode ?? 0;
      final ok = kode >= 200 && kode < 300;
      final body = res.data;
      final pesan = body is Map && body['message'] != null
          ? body['message'].toString()
          : (ok ? 'Data absen berhasil dihapus' : 'Gagal menghapus data ($kode)');
      return HapusHasil(sukses: ok, pesan: pesan);
    } on DioException catch (e) {
      debugPrint(
        'HAPUS ABSEN ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      if (e.response == null) {
        return const HapusHasil(
          sukses: false,
          pesan: 'Tidak dapat terhubung ke server',
        );
      }
      final body = e.response?.data;
      String pesan = 'Gagal menghapus data (${e.response?.statusCode})';
      if (body is Map && body['message'] != null) {
        pesan = body['message'].toString();
      }
      return HapusHasil(sukses: false, pesan: pesan);
    } catch (e) {
      debugPrint('HAPUS ABSEN ERROR: $e');
      return const HapusHasil(sukses: false, pesan: 'Terjadi kesalahan');
    }
  }
}