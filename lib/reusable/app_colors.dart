import 'package:flutter/material.dart';

class AppColors {
  // ============================================================
  // WARNA DASHBOARD
  // ============================================================

  // BACKGROUND DASHBOARD
  static const Color backgroundTop = Color(0xFF0D246B);
  static const Color backgroundMiddle = Color(0xFF193E9A);
  static const Color backgroundBottom = Color(0xFF4169C1);
  static const Color background = Color(0xFF11235F);

  // GLASSMORPHISM / KACA DASHBOARD
  static Color get glassBackground => Colors.white.withValues(alpha: 0.13);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.25);
  static Color get glassBorderLight => Colors.white.withValues(alpha: 0.18);
  static Color get glassLight => Colors.white.withValues(alpha: 0.12);
  static Color get buttonBackground => Colors.white.withValues(alpha: 0.18);
  static Color get glassShadow => Colors.black.withValues(alpha: 0.09);

  // TEXT & ICON DASHBOARD
  static const Color textWhite = Colors.white;
  static const Color textWhite70 = Color.fromRGBO(255, 255, 255, 0.70);
  static const Color textWhite54 = Color.fromRGBO(255, 255, 255, 0.54);
  static const Color textWhite38 = Color.fromRGBO(255, 255, 255, 0.38);
  static const Color textWhite30 = Color.fromRGBO(255, 255, 255, 0.30);
  static const Color textWhite24 = Color.fromRGBO(255, 255, 255, 0.24);
  static const Color iconWhite = Colors.white;

  // STATISTICS DASHBOARD
  static const Color hadir = Colors.greenAccent;
  static const Color sakit = Colors.pinkAccent;
  static const Color izin = Colors.lightBlueAccent;

  // AVATAR DASHBOARD
  static const Color avatarBackground = Color(0xFFF6D544);

  // ACTION / BUTTON DASHBOARD
  static const Color buttonText = Colors.white;

  // ERROR / WARNING DASHBOARD
  static const Color error = Colors.orangeAccent;

  // CHOICE CHIP DASHBOARD
  static const Color choiceChipBackground = Colors.black;
  static const Color choiceChipBorder = Colors.red;

  // ============================================================
  // WARNA HALAMAN MAPS_SCREEN
  // ============================================================

  // WARNA HALAMAN MAPS_SCREEN

  static const Color button = Color(0x20FFFFFF);
  static Color get mapsBackground => Color(0xFF4169C1);
  

  // TEXT
  static const Color mapsTextPrimary = Colors.white;
  static const Color mapsTextSecondary = Colors.white;
  static const Color textabsen = Colors.white;
  static const Color mapsAddressText = Colors.white;
  static const Color mapsInputHint = Colors.white;
  // Text status check in / check out
  static const Color mapsStatusText = Colors.white;

  // ICON
  static const Color mapsIcon = Colors.white;
  static const Color mapsNoteIcon = Colors.white;

  // BUTTON
  static const Color mapsButtonText = Colors.white;
  static const Color mapsButtonLoading = Colors.white;

  // TIME TEXT SHADOW
  static const Color mapsTimeShadow = Colors.black54;

  // PANEL HANDLE
  static const Color mapsHandle = Color(0xFFBDBDBD);

  // INPUT
  static const Color mapsInputText = Color(0xFF212121);

  // ============================================================
  // WARNA HALAMAN PROFIL
  // ============================================================

  // WARNA UTAMA PROFIL
  static const Color profilePrimary = Color(0xFF11235F);

  // BACKGROUND AVATAR PROFIL
  static const Color profileAvatarBackground = Color(0xFFF6D544);

  // BORDER FOTO PROFIL
  static Color get profileAvatarBorder => Colors.white.withValues(alpha: 0.40);

  // BACKGROUND TOMBOL KAMERA
  static const Color profileCameraBackground = Colors.white;

  // BAYANGAN TOMBOL KAMERA
  static Color get profileCameraShadow => Colors.black.withValues(alpha: 0.20);

  // BACKGROUND IKON MENU PROFIL
  static Color get profileIconBackground =>
      Colors.white.withValues(alpha: 0.90);

  // WARNA IKON MENU PROFIL
  static const Color profileEditIcon = Color(0xFF4034AE);
  static const Color profilePasswordIcon = Colors.green;
  static const Color profileLogoutIcon = Colors.red;

  // WARNA HAPUS FOTO PROFIL
  static const Color profileDelete = Color(0xFFFFB4B4);

  // BACKGROUND GRADIENT PROFIL
  static const Color profileBackgroundTop = Color(0xFF0D246B);
  static const Color profileBackgroundMiddle = Color(0xFF193E9A);
  static const Color profileBackgroundBottom = Color(0xFF4169C1);

  // CONTAINER KACA PROFIL
  static Color get profileGlassBackground =>
      Colors.white.withValues(alpha: 0.13);
  static Color get profileGlassBorder => Colors.white.withValues(alpha: 0.25);
  static Color get profileGlassShadow => Colors.black.withValues(alpha: 0.12);

  // TEXT & ICON PROFIL
  static const Color profileText = Colors.white;

  // HANDLE BOTTOM SHEET FOTO PROFIL
  static const Color profileHandle = Colors.white38;

  // ============================================================
  // WARNA HALAMAN RIWAYAT
  // ============================================================

  // WARNA UTAMA RIWAYAT
  static const Color historyPrimary = Color(0xFF11235F);

  // CHIP BULAN TERPILIH
  static Color get historySelectedChipBackground =>
      Colors.white.withValues(alpha: 0.28);
  static const Color historySelectedChipBorder = Colors.white;

  // CHIP BULAN TIDAK TERPILIH
  static const Color historyUnselectedChipBorder = Colors.white54;

  // DIVIDER RIWAYAT
  static const Color historyDivider = Colors.white24;

  // BACKGROUND TANGGAL KARTU RIWAYAT
  static Color get historyDateBackground =>
      Colors.white.withValues(alpha: 0.18);
  static Color get historyDateBorder => Colors.white.withValues(alpha: 0.30);

  // DIVIDER WAKTU CHECK IN / CHECK OUT
  static Color get historyTimeDivider => Colors.white.withValues(alpha: 0.30);

  // BACKGROUND KETERANGAN RIWAYAT
  static Color get historyNoteBackground =>
      Colors.white.withValues(alpha: 0.12);
  static Color get historyNoteBorder => Colors.white.withValues(alpha: 0.20);

  // IKON KETERANGAN RIWAYAT
  static const Color historySickIcon = Colors.pinkAccent;
  static const Color historyNoteIcon = Colors.lightBlueAccent;

  // TOMBOL HAPUS RIWAYAT
  static const Color historyDelete = Color(0xFFFFB4B4);

  // CONTAINER KACA RIWAYAT
  static Color get historyGlassBackground =>
      Colors.white.withValues(alpha: 0.13);
  static Color get historyGlassBorder => Colors.white.withValues(alpha: 0.25);
  static Color get historyGlassShadow => Colors.black.withValues(alpha: 0.12);

  // BACKGROUND GRADIENT RIWAYAT
  static const Color historyBackgroundTop = Color(0xFF0D246B);
  static const Color historyBackgroundMiddle = Color(0xFF193E9A);
  static const Color historyBackgroundBottom = Color(0xFF4169C1);

  // TEXT RIWAYAT
  static const Color historyText = Colors.white;
  static const Color historyTextSecondary = Color.fromRGBO(255, 255, 255, 0.70);
}
