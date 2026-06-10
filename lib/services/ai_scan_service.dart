import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Ekstraksi transaksi dari gambar (struk belanja, QRIS, invoice, bukti
/// transfer) memakai Claude API (vision + structured output).
///
/// Dipanggil via raw HTTP karena belum ada SDK resmi Anthropic untuk Dart.

const String aiScanModel = 'claude-opus-4-8';
const String _apiUrl = 'https://api.anthropic.com/v1/messages';

class AiScanException implements Exception {
  final String message;
  AiScanException(this.message);
  @override
  String toString() => message;
}

class AiScanItem {
  final String name;
  final num qty;
  final num price;
  AiScanItem({required this.name, required this.qty, required this.price});

  factory AiScanItem.fromMap(Map<String, dynamic> m) => AiScanItem(
        name: m['name'] as String? ?? '',
        qty: (m['qty'] as num?) ?? 1,
        price: (m['price'] as num?) ?? 0,
      );
}

class AiScanResult {
  final String docType;    // struk_belanja | qris_payment | invoice | transfer | lainnya
  final String direction;  // expense | income
  final String merchant;
  final String date;       // YYYY-MM-DD, '' jika tidak terbaca
  final String time;       // HH:MM 24 jam, '' jika tidak terbaca
  final num amount;        // total akhir dalam Rupiah
  final String accountHint;
  final String category;
  final String note;
  final List<AiScanItem> items;
  final String confidence; // high | medium | low

  AiScanResult({
    required this.docType,
    required this.direction,
    required this.merchant,
    required this.date,
    required this.time,
    required this.amount,
    required this.accountHint,
    required this.category,
    required this.note,
    required this.items,
    required this.confidence,
  });

  factory AiScanResult.fromMap(Map<String, dynamic> m) => AiScanResult(
        docType: m['doc_type'] as String? ?? 'lainnya',
        direction: m['direction'] as String? ?? 'expense',
        merchant: m['merchant'] as String? ?? '',
        date: m['date'] as String? ?? '',
        time: m['time'] as String? ?? '',
        amount: (m['amount'] as num?) ?? 0,
        accountHint: m['account_hint'] as String? ?? '',
        category: m['category'] as String? ?? '',
        note: m['note'] as String? ?? '',
        items: ((m['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => AiScanItem.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        confidence: m['confidence'] as String? ?? 'low',
      );

  String get docTypeLabel => switch (docType) {
        'struk_belanja' => 'Struk Belanja',
        'qris_payment' => 'Pembayaran QRIS',
        'invoice' => 'Invoice',
        'transfer' => 'Bukti Transfer',
        _ => 'Dokumen Lain',
      };
}

/// Resize + kompres JPEG agar hemat token vision dan di bawah limit 5MB API.
/// Top-level agar bisa dijalankan lewat [compute] di isolate terpisah.
Uint8List compressImageForScan(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  var out = img.bakeOrientation(decoded); // terapkan rotasi EXIF foto kamera
  const maxSide = 1568;
  if (out.width > maxSide || out.height > maxSide) {
    out = out.width >= out.height
        ? img.copyResize(out, width: maxSide)
        : img.copyResize(out, height: maxSide);
  }
  return Uint8List.fromList(img.encodeJpg(out, quality: 82));
}

Map<String, dynamic> _outputSchema() => {
      'type': 'object',
      'additionalProperties': false,
      'required': [
        'doc_type', 'direction', 'merchant', 'date', 'time', 'amount',
        'account_hint', 'category', 'note', 'items', 'confidence',
      ],
      'properties': {
        'doc_type': {
          'type': 'string',
          'enum': ['struk_belanja', 'qris_payment', 'invoice', 'transfer', 'lainnya'],
        },
        'direction': {
          'type': 'string',
          'enum': ['expense', 'income'],
          'description': 'expense = uang pemilik keluar, income = uang pemilik masuk',
        },
        'merchant': {
          'type': 'string',
          'description': 'Nama toko/merchant/pengirim, "" jika tidak ada',
        },
        'date': {
          'type': 'string',
          'description': 'Tanggal transaksi format YYYY-MM-DD, "" jika tidak terbaca',
        },
        'time': {
          'type': 'string',
          'description': 'Jam transaksi format HH:MM 24 jam, "" jika tidak terbaca',
        },
        'amount': {
          'type': 'number',
          'description': 'Total akhir yang dibayar/diterima dalam Rupiah (angka saja)',
        },
        'account_hint': {
          'type': 'string',
          'description': 'Akun pembayaran dari daftar akun user, "" jika tidak yakin',
        },
        'category': {
          'type': 'string',
          'description': 'Satu kategori paling cocok dari daftar kategori user',
        },
        'note': {
          'type': 'string',
          'description': 'Catatan singkat transaksi (maks ~80 karakter)',
        },
        'items': {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': ['name', 'qty', 'price'],
            'properties': {
              'name': {'type': 'string'},
              'qty': {'type': 'number'},
              'price': {'type': 'number', 'description': 'harga total baris dalam Rupiah'},
            },
          },
        },
        'confidence': {
          'type': 'string',
          'enum': ['high', 'medium', 'low'],
        },
      },
    };

String _systemPrompt({
  required String today,
  required List<String> accounts,
  required List<String> expenseCats,
  required List<String> incomeCats,
}) =>
    '''
Kamu adalah asisten pencatat keuangan pribadi Indonesia. Tugasmu membaca gambar
dokumen finansial (struk belanja, screenshot pembayaran QRIS, invoice, bukti
transfer bank/e-wallet) lalu mengekstrak SATU transaksi untuk dicatat.

Aturan:
- Semua nominal dalam Rupiah; tulis sebagai angka murni tanpa pemisah ribuan
  (contoh: "Rp 25.500" -> 25500). Waspadai format Indonesia: titik = ribuan,
  koma = desimal.
- "amount" adalah TOTAL AKHIR yang benar-benar dibayar/diterima (setelah pajak,
  service charge, diskon, dan biaya admin).
- direction dilihat dari sisi PEMILIK dokumen: struk belanja, pembayaran QRIS,
  dan tagihan yang dia bayar = expense. Uang masuk, gaji, transfer diterima,
  atau invoice yang dia terbitkan untuk menagih orang lain = income.
- Tanggal hari ini: $today. Jika tahun tidak tertulis, asumsikan tahun berjalan.
- account_hint HARUS salah satu dari daftar akun berikut (atau "" jika tidak
  yakin). Cocokkan dari metode pembayaran di gambar, misal pembayaran GoPay ->
  "GoPay", kartu/transfer BCA -> "BCA", tunai -> "Tunai":
  ${accounts.join(', ')}
- Jika direction = expense, category HARUS salah satu dari:
  ${expenseCats.join(', ')}
- Jika direction = income, category HARUS salah satu dari:
  ${incomeCats.join(', ')}
- note: ringkas, format "Merchant - info penting" jika memungkinkan.
- items: daftar belanjaan pada struk (maksimal 20 baris); kosongkan jika tidak ada.
- Jika gambar bukan dokumen finansial, set doc_type "lainnya", amount 0,
  confidence "low".
''';

Future<AiScanResult> extractTransactionFromImage({
  required Uint8List imageBytes,
  required String apiKey,
  required String today,
  required List<String> accounts,
  required List<String> expenseCats,
  required List<String> incomeCats,
}) async {
  if (apiKey.trim().isEmpty) {
    throw AiScanException('API key belum diatur.');
  }

  final compressed = await compute(compressImageForScan, imageBytes);

  final body = jsonEncode({
    'model': aiScanModel,
    'max_tokens': 8000,
    'system': _systemPrompt(
      today: today,
      accounts: accounts,
      expenseCats: expenseCats,
      incomeCats: incomeCats,
    ),
    'messages': [
      {
        'role': 'user',
        'content': [
          {
            'type': 'image',
            'source': {
              'type': 'base64',
              'media_type': 'image/jpeg',
              'data': base64Encode(compressed),
            },
          },
          {
            'type': 'text',
            'text':
                'Ekstrak transaksi dari dokumen ini sesuai skema yang diminta.',
          },
        ],
      },
    ],
    'output_config': {
      'format': {'type': 'json_schema', 'schema': _outputSchema()},
    },
  });

  http.Response res;
  try {
    res = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {
            'content-type': 'application/json',
            'x-api-key': apiKey.trim(),
            'anthropic-version': '2023-06-01',
            // Wajib agar API mengizinkan request langsung dari browser
            // (Flutter Web). Aman karena key milik user sendiri.
            'anthropic-dangerous-direct-browser-access': 'true',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 120));
  } catch (e) {
    throw AiScanException('Gagal terhubung ke API: $e');
  }

  if (res.statusCode == 401) {
    throw AiScanException('API key tidak valid. Periksa kembali key Anda.');
  }
  if (res.statusCode == 429) {
    throw AiScanException('Rate limit tercapai. Coba lagi sebentar.');
  }
  if (res.statusCode == 529) {
    throw AiScanException('Server AI sedang sibuk. Coba lagi sebentar.');
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    String detail = 'HTTP ${res.statusCode}';
    try {
      final err = jsonDecode(utf8.decode(res.bodyBytes));
      detail = (err['error']?['message'] as String?) ?? detail;
    } catch (_) {}
    throw AiScanException('Scan gagal: $detail');
  }

  final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;

  final stopReason = data['stop_reason'] as String?;
  if (stopReason == 'refusal') {
    throw AiScanException('Model menolak memproses gambar ini.');
  }

  final content = (data['content'] as List?) ?? const [];
  final textBlock = content.whereType<Map>().firstWhere(
        (b) => b['type'] == 'text',
        orElse: () => const {},
      );
  final text = textBlock['text'] as String?;
  if (text == null || text.isEmpty) {
    throw AiScanException('Respons AI kosong. Coba ulangi scan.');
  }

  try {
    final parsed = jsonDecode(text) as Map<String, dynamic>;
    return AiScanResult.fromMap(parsed);
  } catch (_) {
    throw AiScanException('Gagal membaca hasil ekstraksi. Coba ulangi scan.');
  }
}
