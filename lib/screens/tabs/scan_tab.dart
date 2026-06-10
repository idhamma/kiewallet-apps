import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/transaction.dart';
import '../../services/ai_scan_service.dart';
import '../../state/app_state.dart';
import '../../utils/date_utils.dart';
import '../../utils/format.dart';
import '../../widgets/common/retro.dart';

/// Scan AI: unggah foto struk belanja / pembayaran QRIS / invoice / bukti
/// transfer, lalu AI mengekstrak transaksinya menjadi pemasukan/pengeluaran.
class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  Uint8List? _imageBytes;
  String? _imageName;
  bool _scanning = false;
  AiScanResult? _result;

  // Form review hasil scan
  String _direction = 'expense';
  String _date = getToday();
  String _time = getTimeWIB();
  String? _account;
  String? _category;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final bytes = res?.files.single.bytes;
    if (bytes == null) return;
    setState(() {
      _imageBytes = bytes;
      _imageName = res!.files.single.name;
      _result = null;
    });
  }

  Future<void> _scan(AppState state) async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    setState(() => _scanning = true);
    try {
      final r = await extractTransactionFromImage(
        imageBytes: bytes,
        apiKey: state.aiApiKey,
        today: getToday(),
        accounts: state.accounts,
        expenseCats: state.expenseCats,
        incomeCats: incomeCategories,
      );
      if (!mounted) return;
      setState(() {
        _result = r;
        _direction = r.direction == 'income' ? 'income' : 'expense';
        _date = _validDate(r.date) ? r.date : getToday();
        _time = _validTime(r.time) ? r.time : getTimeWIB();
        _account = state.accounts.contains(r.accountHint)
            ? r.accountHint
            : (state.accounts.isNotEmpty ? state.accounts.first : null);
        final cats = _direction == 'income' ? incomeCategories : state.expenseCats;
        _category = cats.contains(r.category)
            ? r.category
            : (cats.isNotEmpty ? cats.first : null);
        _amountCtrl.text = r.amount > 0 ? r.amount.toStringAsFixed(0) : '';
        _noteCtrl.text =
            r.note.isNotEmpty ? r.note : (r.merchant.isNotEmpty ? r.merchant : '');
      });
      if (r.amount <= 0) {
        state.showPopup('Dokumen terbaca, tapi nominal tidak ditemukan.',
            type: 'error');
      }
    } on AiScanException catch (e) {
      state.showPopup(e.message, type: 'error');
    } catch (e) {
      state.showPopup('Scan gagal: $e', type: 'error');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  bool _validDate(String s) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) return false;
    return DateTime.tryParse(s) != null;
  }

  bool _validTime(String s) => RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s);

  Future<void> _save(AppState state) async {
    final amt = num.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
    if (amt <= 0) {
      state.showPopup('Nominal tidak valid!', type: 'error');
      return;
    }
    if (_account == null || _category == null) return;
    await state.addTransaction(Tx(
      id: DateTime.now().millisecondsSinceEpoch,
      type: _direction,
      date: _date,
      time: _time,
      amount: amt,
      account: _account!,
      category: _category!,
      note: _noteCtrl.text.trim(),
    ));
    state.showPopup('Transaksi hasil scan tersimpan!');
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _result = null;
      _amountCtrl.clear();
      _noteCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RetroBox(
              color: RetroColor.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const RetroSectionTitle('Scan Dokumen AI',
                      icon: Icons.document_scanner_outlined),
                  const Text(
                    'Unggah foto struk belanja, pembayaran QRIS, invoice, atau '
                    'bukti transfer. AI akan membacanya menjadi catatan '
                    'pemasukan / pengeluaran otomatis.',
                    style: TextStyle(fontSize: 11, color: RetroColor.gray500),
                  ),
                  const SizedBox(height: 14),
                  if (state.aiApiKey.isEmpty)
                    _apiKeySetup(state)
                  else ...[
                    _imagePicker(state),
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      _reviewForm(state),
                    ],
                  ],
                ],
              ),
            ),
            if (state.aiApiKey.isNotEmpty) ...[
              const SizedBox(height: 10),
              _apiKeyFooter(state),
            ],
          ],
        ),
      ),
    );
  }

  Widget _apiKeySetup(AppState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RetroColor.yellow50,
        border: Border.all(color: RetroColor.ink, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('SETUP SEKALI: API KEY',
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text(
            'Fitur ini memakai Claude API. Buat API key di '
            'console.anthropic.com lalu tempel di sini. Key tersimpan di akun '
            'Anda dan tersinkron antar perangkat.',
            style: TextStyle(fontSize: 10.5, color: RetroColor.gray500),
          ),
          const SizedBox(height: 10),
          RetroTextField(
            label: 'Anthropic API Key',
            controller: _keyCtrl,
            hint: 'sk-ant-...',
            obscureText: true,
          ),
          const SizedBox(height: 10),
          RetroButton(
            color: RetroColor.ink,
            textColor: RetroColor.cream,
            onPressed: () async {
              final key = _keyCtrl.text.trim();
              if (key.isEmpty) {
                state.showPopup('API key kosong!', type: 'error');
                return;
              }
              await state.setAiApiKey(key);
              _keyCtrl.clear();
              state.showPopup('API key tersimpan!');
            },
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: const Center(child: Text('SIMPAN API KEY')),
          ),
        ],
      ),
    );
  }

  Widget _apiKeyFooter(AppState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('MODEL: $aiScanModel  ·  API KEY TERSIMPAN',
            style: TextStyle(
                fontSize: 9, letterSpacing: 0.5, color: RetroColor.gray400)),
        const SizedBox(width: 8),
        InkWell(
          onTap: () async {
            final ok = await confirmDialog(
                context, 'Hapus API key dari akun ini?');
            if (ok) await state.setAiApiKey('');
          },
          child: const Text('HAPUS',
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.5,
                  color: RetroColor.red500,
                  decoration: TextDecoration.underline)),
        ),
      ],
    );
  }

  Widget _imagePicker(AppState state) {
    final bytes = _imageBytes;
    if (bytes == null) {
      return InkWell(
        onTap: _pickImage,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            color: RetroColor.gray100,
            border: Border.all(color: RetroColor.gray400, width: 1),
          ),
          child: const Column(
            children: [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 36, color: RetroColor.gray500),
              SizedBox(height: 10),
              Text('PILIH GAMBAR DARI GALERI / FILE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: RetroColor.gray500)),
              SizedBox(height: 4),
              Text('JPG · PNG · WEBP',
                  style: TextStyle(fontSize: 9, color: RetroColor.gray400)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: RetroColor.ink, width: 1),
            color: RetroColor.gray100,
          ),
          constraints: const BoxConstraints(maxHeight: 280),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        Text(_imageName ?? '',
            style: const TextStyle(fontSize: 9, color: RetroColor.gray400),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 10),
        if (_scanning)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: RetroColor.ink, width: 1),
              color: RetroColor.yellow50,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: RetroColor.ink),
                ),
                SizedBox(width: 10),
                Text('AI SEDANG MEMBACA DOKUMEN...',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                flex: 2,
                child: RetroButton(
                  color: RetroColor.ink,
                  textColor: RetroColor.cream,
                  onPressed: () => _scan(state),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 13),
                        SizedBox(width: 6),
                        Text('SCAN DENGAN AI'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RetroButton(
                  color: Colors.white,
                  onPressed: _pickImage,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Center(child: Text('GANTI')),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _reviewForm(AppState state) {
    final r = _result!;
    final isIncome = _direction == 'income';
    final cats = isIncome ? incomeCategories : state.expenseCats;
    if (_category == null || !cats.contains(_category)) {
      _category = cats.isNotEmpty ? cats.first : null;
    }
    _account ??= state.accounts.isNotEmpty ? state.accounts.first : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isIncome ? RetroColor.green50 : RetroColor.red50,
        border: Border.all(color: RetroColor.ink, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: RetroColor.ink,
                child: Text(r.docTypeLabel.toUpperCase(),
                    style: const TextStyle(
                        color: RetroColor.cream,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              if (r.merchant.isNotEmpty)
                Expanded(
                  child: Text(r.merchant,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                )
              else
                const Spacer(),
              Text('AKURASI: ${r.confidence.toUpperCase()}',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                      color: r.confidence == 'high'
                          ? RetroColor.green600
                          : r.confidence == 'medium'
                              ? RetroColor.orange400
                              : RetroColor.red500)),
            ],
          ),
          const SizedBox(height: 12),
          RetroDropdown<String>(
            label: 'Jenis Transaksi',
            value: _direction,
            items: const ['expense', 'income'],
            labelOf: (s) =>
                s == 'expense' ? 'Pengeluaran (- Kas)' : 'Pemasukan (+ Kas)',
            onChanged: (v) => setState(() {
              _direction = v ?? 'expense';
              final newCats =
                  _direction == 'income' ? incomeCategories : state.expenseCats;
              _category = newCats.isNotEmpty ? newCats.first : null;
            }),
          ),
          const SizedBox(height: 10),
          _dateTimeRow(),
          const SizedBox(height: 10),
          RetroTextField(
            label: 'Total (Rp)',
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          RetroDropdown<String>(
            label: 'Akun',
            value: _account!,
            items: state.accounts,
            labelOf: (s) => s,
            onChanged: (v) => setState(() => _account = v),
          ),
          const SizedBox(height: 10),
          RetroDropdown<String>(
            label: 'Kategori',
            value: _category!,
            items: cats,
            labelOf: (s) => s,
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 10),
          RetroTextField(label: 'Catatan', controller: _noteCtrl),
          if (r.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: RetroColor.gray300, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('RINCIAN ITEM TERBACA',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                          color: RetroColor.gray500)),
                  const SizedBox(height: 6),
                  for (final it in r.items.take(20))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1.5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${it.qty == 1 ? '' : '${it.qty} x '}${it.name}',
                              style: const TextStyle(fontSize: 10.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(formatRp(it.price),
                              style: const TextStyle(
                                  fontSize: 10.5, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          RetroButton(
            color: isIncome ? RetroColor.green400 : RetroColor.red400,
            textColor: Colors.white,
            onPressed: () => _save(state),
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: const Center(child: Text('SIMPAN TRANSAKSI')),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('TANGGAL',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                        color: RetroColor.gray500)),
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(_date),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _date =
                          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: RetroColor.ink, width: 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, size: 12),
                    const SizedBox(width: 8),
                    Text(_date,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12)),
                  ]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text('JAM',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                        color: RetroColor.gray500)),
              ),
              InkWell(
                onTap: () async {
                  final parts = _time.split(':');
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 0,
                      minute:
                          int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _time =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: RetroColor.ink, width: 1),
                  ),
                  child: Row(children: [
                    const Icon(Icons.access_time, size: 12),
                    const SizedBox(width: 8),
                    Text(_time,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
