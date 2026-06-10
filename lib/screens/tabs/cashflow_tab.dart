import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/transaction.dart';
import '../../models/debt.dart';
import '../../state/app_state.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common/retro.dart';

class CashFlowTab extends StatefulWidget {
  final String type;
  const CashFlowTab({super.key, required this.type});

  @override
  State<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends State<CashFlowTab> {
  String date = getToday();
  String time = getTimeWIB();
  String amount = '';
  String note = '';
  String? account;
  String? category;

  bool splitEnabled = false;
  String myShare = '';
  String friendName = '';

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _myShareCtrl = TextEditingController();
  final _friendCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _myShareCtrl.dispose();
    _friendCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isIncome = widget.type == 'income';
    final cats = isIncome ? incomeCategories : state.expenseCats;
    account ??= state.accounts.isNotEmpty ? state.accounts.first : null;
    category ??= cats.isNotEmpty ? cats.first : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: RetroBox(
          color: isIncome ? RetroColor.green50 : RetroColor.red50,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RetroSectionTitle(
                'CATAT ${isIncome ? "PEMASUKAN" : "PENGELUARAN"}',
                icon: isIncome ? Icons.south_west : Icons.north_east,
              ),
              if (!isIncome) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RetroColor.orange100,
                    border: Border.all(color: RetroColor.ink, width: 1),
                  ),
                  child: Row(children: [
                    Checkbox(
                      value: splitEnabled,
                      onChanged: (v) => setState(() => splitEnabled = v ?? false),
                    ),
                    const Icon(Icons.call_split, size: 14),
                    const SizedBox(width: 4),
                    const Text('Mode Split Bill (Patungan)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ]),
                ),
                const SizedBox(height: 12),
              ],
              _datePicker(),
              const SizedBox(height: 12),
              RetroTextField(
                label: splitEnabled ? 'Total Tagihan (Rp)' : 'Jumlah (Rp)',
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = v,
              ),
              if (splitEnabled) ...[
                const SizedBox(height: 8),
                RetroTextField(
                  label: 'Bagian Saya (Rp)',
                  controller: _myShareCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (v) => myShare = v,
                  background: RetroColor.yellow200,
                ),
                const SizedBox(height: 8),
                RetroTextField(
                  label: 'Nama Teman (Utang)',
                  controller: _friendCtrl,
                  hint: 'Misal: Budi',
                  onChanged: (v) => friendName = v,
                  background: RetroColor.yellow200,
                ),
              ],
              const SizedBox(height: 12),
              RetroDropdown<String>(
                label: 'Akun Sumber Dana',
                value: account!,
                items: state.accounts,
                labelOf: (s) => s,
                onChanged: (v) => setState(() => account = v),
              ),
              const SizedBox(height: 12),
              RetroDropdown<String>(
                label: 'Kategori',
                value: cats.contains(category) ? category! : cats.first,
                items: cats,
                labelOf: (s) => s,
                onChanged: (v) => setState(() => category = v),
              ),
              const SizedBox(height: 12),
              RetroTextField(label: 'Catatan', controller: _noteCtrl, onChanged: (v) => note = v),
              const SizedBox(height: 16),
              RetroButton(
                color: isIncome ? RetroColor.green400 : RetroColor.red500,
                textColor: isIncome ? RetroColor.ink : Colors.white,
                onPressed: () => _save(state),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Center(
                  child: Text('+ SIMPAN DATA', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.parse(date),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  date =
                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: RetroColor.ink, width: 1),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today, size: 13),
                const SizedBox(width: 8),
                Text(date, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () async {
              final parts = time.split(':');
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: int.tryParse(parts[0]) ?? 0,
                  minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
                ),
              );
              if (picked != null) {
                setState(() {
                  time =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: RetroColor.ink, width: 1),
              ),
              child: Row(children: [
                const Icon(Icons.access_time, size: 13),
                const SizedBox(width: 8),
                Text(time, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save(AppState state) async {
    final total = num.tryParse(amount) ?? 0;
    if (total <= 0) {
      state.showPopup('Jumlah tidak valid!', type: 'error');
      return;
    }
    if (account == null || category == null) return;

    if (widget.type == 'expense' && splitEnabled) {
      final mine = num.tryParse(myShare) ?? 0;
      final friend = total - mine;
      if (mine < 0 || mine >= total) {
        state.showPopup('Bagian Anda tidak valid!', type: 'error');
        return;
      }
      if (friendName.trim().isEmpty) {
        state.showPopup('Nama teman wajib diisi!', type: 'error');
        return;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      await state.addTransactions([
        Tx(id: now, type: 'expense', date: date, time: time, amount: mine,
            account: account!, category: category!, note: '$note (Porsi Saya)'),
        Tx(id: now + 1, type: 'piutang_out', date: date, time: time, amount: friend,
            account: account!, category: 'Split Bill',
            note: 'Ditalangin untuk $friendName'),
      ]);
      await state.addDebt(Debt(
        id: now + 2, person: friendName, type: 'piutang', amount: friend,
        account: account!, dueDate: date,
      ));
    } else {
      await state.addTransaction(Tx(
        id: DateTime.now().millisecondsSinceEpoch,
        type: widget.type, date: date, time: time, amount: total,
        account: account!, category: category!, note: note,
      ));
    }
    state.showPopup('Data berhasil disimpan!');
    setState(() {
      amount = '';
      note = '';
      time = getTimeWIB();
      splitEnabled = false;
      myShare = '';
      friendName = '';
      _amountCtrl.clear();
      _noteCtrl.clear();
      _myShareCtrl.clear();
      _friendCtrl.clear();
    });
  }
}
