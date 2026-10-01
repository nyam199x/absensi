class HistoryAbsenModel {
  final int id;
  final String? attendanceDate;
  final String? checkIn;
  final String? checkOut;
  final String? checkInAddress;
  final String? checkOutAddress;
  final String? status;
  final String? alasanIzin;

  HistoryAbsenModel({
    required this.id,
    this.attendanceDate,
    this.checkIn,
    this.checkOut,
    this.checkInAddress,
    this.checkOutAddress,
    this.status,
    this.alasanIzin,
  });

  factory HistoryAbsenModel.fromJson(Map<String, dynamic> json) {
    return HistoryAbsenModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      attendanceDate: json['attendance_date']?.toString(),
      checkIn: json['check_in_time']?.toString() ?? json['check_in']?.toString(),
      checkOut: json['check_out_time']?.toString() ?? json['check_out']?.toString(),
      checkInAddress: json['check_in_address']?.toString(),
      checkOutAddress: json['check_out_address']?.toString(),
      status: json['status']?.toString(),
      alasanIzin: json['alasan_izin']?.toString(),
    );
  }

  /// Ambil list dari respons {"data": [...]} atau langsung [...].
  static List<HistoryAbsenModel> listFromResponse(dynamic body) {
    final raw = (body is Map && body['data'] is List) ? body['data'] : body;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => HistoryAbsenModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// Pembungkus respons {"message": "...", "data": [...]}.
class HistoryAbsenResponse {
  final String? message;
  final List<HistoryAbsenModel> data;

  HistoryAbsenResponse({this.message, required this.data});

  factory HistoryAbsenResponse.fromJson(Map<String, dynamic> json) {
    return HistoryAbsenResponse(
      message: json['message']?.toString(),
      data: HistoryAbsenModel.listFromResponse(json),
    );
  }
}