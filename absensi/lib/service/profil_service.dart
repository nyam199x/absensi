import 'package:absensi/model/profil_model.dart';
import 'package:absensi/service/dio_service.dart';
import 'package:absensi/service/simpan_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ProfilService {
  // Base URL sama dengan ApiService (baseUrl + prefix /api)
  static const String _baseUrl = 'https://absensib1.mobileprojp.com/api';

  // TODO: cocokkan path ini dengan dokumentasi/Postman backend
  static const String _pathProfil = '/profile';

  static final Dio _dio = createDioService();

  static Future<Options> _options() async {
    final token = await SimpanToken.getToken();
    return Options(
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  /// Ambil pesan error dari respons server, atau pesan bawaan.
  static String _pesanError(DioException e) {
    final body = e.response?.data;
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
      if (body['message'] != null) return body['message'].toString();
    }
    if (e.response == null) return 'Tidak dapat terhubung ke server';
    return 'Terjadi kesalahan (${e.response?.statusCode})';
  }

  static AksiResponse _sukses(Response res, String pesanBawaan) {
    final body = res.data;
    if (body is Map<String, dynamic>) {
      final parsed = AksiResponse.fromJson(body);
      return AksiResponse(
        sukses: true,
        pesan: parsed.pesan.isNotEmpty ? parsed.pesan : pesanBawaan,
        data: parsed.data,
      );
    }
    return AksiResponse(sukses: true, pesan: pesanBawaan);
  }

  /// Ambil data profil saat ini. Mengembalikan null jika gagal.
  static Future<UserProfilModel?> ambilProfil() async {
    try {
      final res = await _dio.get(
        '$_baseUrl$_pathProfil',
        options: await _options(),
      );
      final body = res.data;
      debugPrint('PROFIL RESPONSE: $body');
      if (body is! Map) return null;
      final data = body['data'] ?? body['user'] ?? body;
      if (data is! Map<String, dynamic>) return null;
      return UserProfilModel.fromJson(data);
    } catch (e) {
      debugPrint('Gagal ambil profil: $e');
      return null;
    }
  }

  static Future<AksiResponse> ubahProfil(UbahProfilRequest req) async {
    try {
      final res = await _dio.put(
        '$_baseUrl$_pathProfil',
        data: req.toJson(),
        options: await _options(),
      );
      return _sukses(res, 'Profil berhasil diperbarui');
    } on DioException catch (e) {
      debugPrint(
        'Gagal ubah profil: ${e.response?.statusCode} ${e.response?.data} $e',
      );
      return AksiResponse(sukses: false, pesan: _pesanError(e));
    } catch (e) {
      debugPrint('Gagal ubah profil: $e');
      return const AksiResponse(sukses: false, pesan: 'Terjadi kesalahan');
    }
  }
}
