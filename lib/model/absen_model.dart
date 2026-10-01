// Model satu data absen (check-in / check-out).
/// Letakkan di: lib/model/absen_model.dart
class AbsenModel {
  final int? id;
  final String? tanggal;
  final String? jamMasuk;
  final String? jamPulang;
  final double? latMasuk;
  final double? lngMasuk;
  final String? alamatMasuk;
  final double? latPulang;
  final double? lngPulang;
  final String? alamatPulang;
  final String? status;
  final String? alasanIzin;
 
  AbsenModel({
    this.id,
    this.tanggal,
    this.jamMasuk,
    this.jamPulang,
    this.latMasuk,
    this.lngMasuk,
    this.alamatMasuk,
    this.latPulang,
    this.lngPulang,
    this.alamatPulang,
    this.status,
    this.alasanIzin,
  });
 
  factory AbsenModel.fromJson(Map<String, dynamic> json) => AbsenModel(
        id: _toInt(json['id']),
        tanggal: json['attendance_date']?.toString(),
        jamMasuk: json['check_in_time']?.toString(),
        jamPulang: json['check_out_time']?.toString(),
        latMasuk: _toDouble(json['check_in_lat']),
        lngMasuk: _toDouble(json['check_in_lng']),
        alamatMasuk: json['check_in_address']?.toString(),
        latPulang: _toDouble(json['check_out_lat']),
        lngPulang: _toDouble(json['check_out_lng']),
        alamatPulang: json['check_out_address']?.toString(),
        status: json['status']?.toString(),
        alasanIzin: json['alasan_izin']?.toString(),
      );
 
  Map<String, dynamic> toJson() => {
        'id': id,
        'attendance_date': tanggal,
        'check_in_time': jamMasuk,
        'check_out_time': jamPulang,
        'check_in_lat': latMasuk,
        'check_in_lng': lngMasuk,
        'check_in_address': alamatMasuk,
        'check_out_lat': latPulang,
        'check_out_lng': lngPulang,
        'check_out_address': alamatPulang,
        'status': status,
        'alasan_izin': alasanIzin,
      };
}
 
/// Model statistik absen untuk kartu di Dashboard.
class AbsenStat {
  final int totalHadir;
  final int totalTerlambat;
  final int totalIzin;
 
  AbsenStat({
    this.totalHadir = 0,
    this.totalTerlambat = 0,
    this.totalIzin = 0,
  });
 
  factory AbsenStat.fromJson(Map<String, dynamic> json) {
    // Beberapa API membungkus data di dalam key "data".
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
 
    return AbsenStat(
      totalHadir: _toInt(data['total_masuk'] ?? data['total_hadir']) ?? 0,
      totalTerlambat: _toInt(data['total_terlambat']) ?? 0,
      totalIzin: _toInt(data['total_izin']) ?? 0,
    );
  }
 
  Map<String, dynamic> toJson() => {
        'total_hadir': totalHadir,
        'total_terlambat': totalTerlambat,
        'total_izin': totalIzin,
      };
}
 
int? _toInt(dynamic v) =>
    v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
 
double? _toDouble(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));