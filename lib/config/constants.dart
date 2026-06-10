import 'package:flutter/material.dart';

const List<String> defaultAccounts = [
  'BCA', 'Mandiri', 'Bank Jago', 'Bank Jago Stockbit', 'GoPay', 'OVO',
  'DANA', 'ShopeePay', 'BSI', 'BRI', 'Tunai',
];

const List<String> incomeCategories = [
  'Gaji', 'Bonus', 'Freelance', 'Investasi', 'Lainnya',
];

const List<String> defaultExpenseCats = [
  'Makan & Minum', 'Transportasi', 'Tagihan', 'Belanja', 'Hiburan',
  'Top Up', 'Health', 'Groceries', 'Biaya Admin', 'Lainnya',
];

// Palet chart: warna retro yang sudah diredam (muted mid-century).
const List<Color> retroColors = [
  Color(0xFF8AA678), Color(0xFFC2877E), Color(0xFF7E96AB), Color(0xFFC99159),
  Color(0xFF9C8AA5), Color(0xFFD4B45E), Color(0xFFBF6B57), Color(0xFF6FA39A),
];

const List<String> daysOfWeek = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

const List<String> investTypes = [
  'Saham', 'Crypto', 'Reksadana', 'Logam Mulia / Emas',
  'Perhiasan', 'Tabungan Bank', 'Lainnya',
];

/// Skema warna "retro minimalism": kertas hangat, tinta pekat,
/// dan aksen pudar ala cetakan lawas. Nama konstanta dipertahankan
/// agar seluruh layar otomatis mengikuti skema baru.
class RetroColor {
  // Dasar
  static const cream = Color(0xFFF5F1E6);   // kertas (latar utama)
  static const paper = cream;
  static const surface = Color(0xFFFBF8F0); // kartu/permukaan
  static const ink = Color(0xFF22201B);     // tinta (border, teks pekat)

  // Mustard (aksen utama)
  static const yellow = Color(0xFFD9A441);
  static const yellow50 = Color(0xFFF7F1DE);
  static const yellow100 = Color(0xFFF3EAD0);
  static const yellow200 = Color(0xFFEDDFB4);
  static const yellow300 = Color(0xFFE2C173);
  static const yellow400 = Color(0xFFD9A441);

  // Hijau lumut (pemasukan)
  static const green50 = Color(0xFFF1F3E8);
  static const green100 = Color(0xFFE7ECD8);
  static const green200 = Color(0xFFD8E0C2);
  static const green300 = Color(0xFFAEC09B);
  static const green400 = Color(0xFF8AA678);
  static const green500 = Color(0xFF6D8C5C);
  static const green600 = Color(0xFF55714A);
  static const green700 = Color(0xFF435A3B);

  // Bata (pengeluaran)
  static const red50 = Color(0xFFF7EEE9);
  static const red100 = Color(0xFFF1E0D8);
  static const red200 = Color(0xFFE7CDC1);
  static const red300 = Color(0xFFD5A091);
  static const red400 = Color(0xFFBF6B57);
  static const red500 = Color(0xFFA85441);
  static const red600 = Color(0xFF8F4536);
  static const red700 = Color(0xFF73392E);

  // Biru pudar (slate)
  static const blue50 = Color(0xFFEFF1ED);
  static const blue100 = Color(0xFFE4E8E4);
  static const blue200 = Color(0xFFD3DBD9);
  static const blue300 = Color(0xFFA9BAC2);
  static const blue400 = Color(0xFF7E96AB);
  static const blue500 = Color(0xFF67809A);
  static const blue600 = Color(0xFF53697F);
  static const blue700 = Color(0xFF44576A);

  // Ungu pudar (mauve)
  static const purple50 = Color(0xFFF3F0F1);
  static const purple100 = Color(0xFFE9E3E8);
  static const purple400 = Color(0xFF9C8AA5);

  // Merah muda tanah liat
  static const pink50 = Color(0xFFF6EFEC);
  static const pink100 = Color(0xFFF0E2DE);
  static const pink400 = Color(0xFFC2877E);

  // Teal redup
  static const teal50 = Color(0xFFEFF3EE);
  static const teal100 = Color(0xFFE0EAE5);
  static const teal400 = Color(0xFF6FA39A);
  static const teal600 = Color(0xFF4D7F76);
  static const teal800 = Color(0xFF3A6058);
  static const teal900 = Color(0xFF2F4F48);

  static const cyan100 = Color(0xFFE0E9E6);

  // Oranye tanah
  static const orange100 = Color(0xFFF2E4D0);
  static const orange400 = Color(0xFFC99159);

  // Indigo redup
  static const indigo100 = Color(0xFFE5E5EA);
  static const indigo700 = Color(0xFF4E5474);
  static const indigo900 = Color(0xFF383D54);

  // Abu hangat
  static const gray100 = Color(0xFFEFEBDF);
  static const gray200 = Color(0xFFE2DDCE);
  static const gray300 = Color(0xFFCBC5B2);
  static const gray400 = Color(0xFF98917F);
  static const gray500 = Color(0xFF6C6557);
}
