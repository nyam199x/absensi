/// Model untuk fitur Ubah Profil dan Ubah Kata Sandi.
/// Sesuaikan nama key JSON dengan respons/request API kamu.

/// Data pengguna (dipakai untuk menampilkan & mengisi form Ubah Profil).
class UserProfilModel {
  final int? id;
  final String nama;
  final String email;
  final String? noHp;

  const UserProfilModel({
    this.id,
    required this.nama,
    required this.email,
    this.noHp,
  });

  factory UserProfilModel.fromJson(Map<String, dynamic> json) {
    return UserProfilModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      nama: (json['name'] ?? json['nama'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      noHp: (json['no_hp'] ?? json['phone'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': nama,
        'email': email,
        if (noHp != null) 'no_hp': noHp,
      };

  UserProfilModel copyWith({String? nama, String? email, String? noHp}) {
    return UserProfilModel(
      id: id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
    );
  }
}

/// Body request untuk Ubah Profil.
class UbahProfilRequest {
  final String nama;
  final String email;
  final String? noHp;

  const UbahProfilRequest({
    required this.nama,
    required this.email,
    this.noHp,
  });

  Map<String, dynamic> toJson() => {
        'name': nama,
        'email': email,
        if (noHp != null && noHp!.isNotEmpty) 'no_hp': noHp,
      };

  /// Validasi sederhana di sisi klien. Mengembalikan pesan error, atau null jika valid.
  String? validasi() {
    if (nama.trim().isEmpty) return 'Nama tidak boleh kosong';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email.trim())) return 'Format email tidak valid';
    return null;
  }
}

/// Body request untuk Ubah Kata Sandi.
class UbahKataSandiRequest {
  final String kataSandiLama;
  final String kataSandiBaru;
  final String konfirmasiKataSandi;

  const UbahKataSandiRequest({
    required this.kataSandiLama,
    required this.kataSandiBaru,
    required this.konfirmasiKataSandi,
  });

  Map<String, dynamic> toJson() => {
        'current_password': kataSandiLama,
        'new_password': kataSandiBaru,
        'new_password_confirmation': konfirmasiKataSandi,
      };

  /// Validasi sederhana di sisi klien. Mengembalikan pesan error, atau null jika valid.
  String? validasi() {
    if (kataSandiLama.isEmpty) return 'Kata sandi lama wajib diisi';
    if (kataSandiBaru.length < 6) return 'Kata sandi baru minimal 6 karakter';
    if (kataSandiBaru == kataSandiLama) {
      return 'Kata sandi baru tidak boleh sama dengan yang lama';
    }
    if (kataSandiBaru != konfirmasiKataSandi) {
      return 'Konfirmasi kata sandi tidak cocok';
    }
    return null;
  }
}

/// Respons umum dari API untuk operasi ubah profil / ubah kata sandi.
class AksiResponse {
  final bool sukses;
  final String pesan;
  final UserProfilModel? data;

  const AksiResponse({
    required this.sukses,
    required this.pesan,
    this.data,
  });

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