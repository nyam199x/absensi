import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:absensi/service/simpan_token.dart';

Dio? _dioInstance;

/// Menghasilkan atau mengembalikan instance Dio yang sudah dikonfigurasi.
Dio createDioService() {
  if (_dioInstance != null) {
    return _dioInstance!;
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://absensib1.mobileprojp.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = (await SimpanToken.getToken())?.trim();
        final adaToken = token != null && token.isNotEmpty;

        if (adaToken) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }

        log(
          '${options.method} ${options.path} | token: ${adaToken ? "ADA" : "KOSONG"}',
          name: 'AUTH',
        );
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // Hanya dicatat. Token TIDAK dihapus otomatis, supaya satu request
        // yang gagal tidak membuat request berikutnya kehilangan sesi.
        if (error.response?.statusCode == 401) {
          log(
            '401 pada ${error.requestOptions.path}: ${error.response?.data}',
            name: 'AUTH',
          );
        }
        return handler.next(error);
      },
    ),
  );

  // LogInterceptor hanya aktif saat mode debug
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => log(obj.toString(), name: 'DIO'),
      ),
    );
  }

  _dioInstance = dio;
  return _dioInstance!;
}

/// Me-reset instance Dio jika diperlukan.
void resetDioService() {
  _dioInstance = null;
}