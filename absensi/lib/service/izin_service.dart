import 'package:absensi/service/dio_service.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class IzinHasil {
  final bool sukses;
  final String pesan;
  const IzinHasil({required this.sukses, required this.pesan});
}

class IzinService {
  static const String _baseUrl = 'https://absensib1.mobileprojp.com/api';

  // TODO: cocokkan path dan nama field dengan dokumentasi/Postman backend
  static const String _pathIzin = '/izin';

  static final Dio _dio = createDioService();

  /// Kirim keterangan sakit atau izin untuk hari ini.
  /// Teks disimpan dengan awalan "Sakit: " atau "Izin: " supaya bisa dikenali
  /// di Dashboard dan Riwayat tanpa perlu tipe khusus dari server.
  static Future<IzinHasil> ajukan({
    required bool sakit,
    required String catatan,
  }) async {
    final token = await SimpanToken.getToken();
    final tanggal = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final res = await _dio.post(
        '$_baseUrl$_pathIzin',
        data: {
          'date': tanggal,
          'alasan_izin': '${sakit ? 'Sakit' : 'Izin'}: ${catatan.trim()}',
        },
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

      final ok = (res.statusCode ?? 0) >= 200 && (res.statusCode ?? 0) < 300;
      final body = res.data;
      final pesan = body is Map && body['message'] != null
          ? body['message'].toString()
          : (ok ? 'Keterangan sakit terkirim' : 'Gagal mengirim keterangan');
      return IzinHasil(sukses: ok, pesan: pesan);
    } on DioException catch (e) {
      debugPrint(
        'IZIN ERROR: ${e.response?.statusCode} ${e.response?.data} $e',
      );
      final body = e.response?.data;
      String pesan = 'Tidak dapat terhubung ke server';
      if (e.response != null) {
        pesan = 'Gagal mengirim keterangan (${e.response?.statusCode})';
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
      }
      return IzinHasil(sukses: false, pesan: pesan);
    } catch (e) {
      debugPrint('IZIN ERROR: $e');
      return const IzinHasil(sukses: false, pesan: 'Terjadi kesalahan');
    }
  }
}
