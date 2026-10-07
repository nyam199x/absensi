/// Model untuk fitur Ubah Profil dan Ubah Kata Sandi.
/// Sesuaikan nama key JSON dengan respons/request API kamu.
library;

/// Data pengguna (dipakai untuk menampilkan profil & mengisi form Ubah Profil).
class UserProfilModel {
  final int? id;
  final String nama;

  final DateTime? createdAt; // BARU
  final DateTime? updatedAt; // BARU

  const UserProfilModel({
    this.id,
    required this.nama,

    this.createdAt,
    this.updatedAt,
  });

  factory UserProfilModel.fromJson(Map<String, dynamic> json) {
    return UserProfilModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      nama: (json['name'] ?? json['nama'] ?? '').toString(),

      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {if (id != null) 'id': id, 'name': nama};

  UserProfilModel copyWith({String? nama, String? email, String? noHp}) {
    return UserProfilModel(
      id: id,
      nama: nama ?? this.nama,

      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Body request untuk Ubah Profil.
class UbahProfilRequest {
  final String nama;

  const UbahProfilRequest({required this.nama});

  Map<String, dynamic> toJson() => {'name': nama};

  /// Validasi sederhana di sisi klien. Mengembalikan pesan error, atau null jika valid.
  String? validasi() {
    if (nama.trim().isEmpty) return 'Nama tidak boleh kosong';

    return null;
  }
}

/// Respons umum dari API untuk operasi ubah profil / ubah kata sandi.
class AksiResponse {
  final bool sukses;
  final String pesan;
  final UserProfilModel? data;

  const AksiResponse({required this.sukses, required this.pesan, this.data});

  factory AksiResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AksiResponse(
      sukses: json['success'] == true || json['status'] == 'success',
      pesan: (json['message'] ?? json['pesan'] ?? '').toString(),
      data: rawData is Map<String, dynamic>
          ? UserProfilModel.fromJson(rawData)
          : null,
    );
  }
}
