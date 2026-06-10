import 'dart:convert';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';

String buildCsv(List<Tx> transactions) {
  final headers = ['ID', 'Tipe', 'Tanggal', 'Waktu', 'Jumlah', 'Akun', 'Kategori', 'Catatan'];
  final rows = transactions.map((t) {
    final note = t.note.replaceAll('"', '""');
    return '${t.id},${t.type},${t.date},${t.time ?? ''},${t.amount},${t.account},${t.category},"$note"';
  });
  return [headers.join(','), ...rows].join('\n');
}

Future<void> exportCsv(List<Tx> transactions, {String filename = 'KieWallet_Data'}) async {
  final csv = buildCsv(transactions);
  final bytes = utf8.encode(csv);
  await FileSaver.instance.saveFile(
    name: filename,
    bytes: bytes,
    ext: 'csv',
    mimeType: MimeType.csv,
  );
}

class CsvImportResult {
  final List<Tx> transactions;
  final Set<String> expenseCatsSeen;
  final Set<String> accountsSeen;
  CsvImportResult(this.transactions, this.expenseCatsSeen, this.accountsSeen);
}

Future<CsvImportResult?> importCsvPick() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final bytes = result.files.first.bytes;
  if (bytes == null) return null;
  return parseCsv(utf8.decode(bytes));
}

CsvImportResult parseCsv(String text) {
  final lines = text.split(RegExp(r'\r?\n'));
  final txs = <Tx>[];
  final expenseCatsSeen = <String>{};
  final accountsSeen = <String>{};
  for (var i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final cols = _splitCsvLine(line);
    if (cols.length < 7) continue;
    final type = cols[1];
    final acc = cols[5];
    final category = cols[6];
    txs.add(Tx(
      id: DateTime.now().millisecondsSinceEpoch + i,
      type: type,
      date: cols[2],
      time: cols[3].isEmpty ? null : cols[3],
      amount: num.tryParse(cols[4]) ?? 0,
      account: acc,
      category: category,
      note: cols.length > 7 ? cols[7].replaceAll('"', '') : '',
    ));
    if (type == 'expense' && category.isNotEmpty) expenseCatsSeen.add(category);
    if (acc.isNotEmpty) accountsSeen.add(acc);
  }
  return CsvImportResult(txs, expenseCatsSeen, accountsSeen);
}

List<String> _splitCsvLine(String line) {
  final out = <String>[];
  final buf = StringBuffer();
  var inQuote = false;
  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQuote = !inQuote;
      continue;
    }
    if (ch == ',' && !inQuote) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  out.add(buf.toString());
  return out;
}
