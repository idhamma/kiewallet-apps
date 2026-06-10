import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/debt.dart';
import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common/retro.dart';

class DebtTab extends StatefulWidget {
  const DebtTab({super.key});

  @override
  State<DebtTab> createState() => _DebtTabState();
}

class _DebtTabState extends State<DebtTab> {
  String person = '';
  String type = 'piutang';
  String amount = '';
  String? account;
  String dueDate = getToday();

  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.accounts.isEmpty) return const SizedBox.shrink();
    account ??= state.accounts.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBox(
          color: RetroColor.orange100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('CATAT UTANG/PIUTANG BARU',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const Divider(color: Colors.black, thickness: 4),
              RetroTextField(
                label: 'Nama Orang',
                controller: _personCtrl,
                onChanged: (v) => person = v,
              ),
              const SizedBox(height: 8),
              RetroDropdown<String>(
                label: 'Jenis Transaksi',
                value: type,
                items: const ['piutang', 'utang'],
                labelOf: (s) => s == 'piutang'
                    ? 'Saya Meminjamkan Uang (Kas Berkurang)'
                    : 'Saya Pinjam Uang (Kas Bertambah)',
                onChanged: (v) => setState(() => type = v!),
                background: RetroColor.yellow50,
              ),
              const SizedBox(height: 8),
              RetroTextField(
                label: 'Jumlah (Rp)',
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = v,
              ),
              const SizedBox(height: 8),
              RetroDropdown<String>(
                label: 'Akun Masuk/Keluar',
                value: account!,
                items: state.accounts,
                labelOf: (s) => s,
                onChanged: (v) => setState(() => account = v),
              ),
              const SizedBox(height: 12),
              RetroButton(
                color: Colors.black,
                textColor: Colors.white,
                onPressed: () => _addDebt(state),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Center(child: Text('+ TAMBAH', style: TextStyle(fontSize: 13))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RetroBox(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DAFTAR UTANG / PIUTANG',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const Divider(color: Colors.black, thickness: 4),
              if (state.debts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Tidak ada catatan utang/piutang.')),
                ),
              for (final d in state.debts) _debtRow(d, state),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addDebt(AppState state) async {
    final amt = num.tryParse(amount) ?? 0;
    if (person.trim().isEmpty || amt <= 0) {
      state.showPopup('Nama & nominal wajib!', type: 'error');
      return;
    }
    final id = DateTime.now().millisecondsSinceEpoch;
    final txType = type == 'utang' ? 'utang_in' : 'piutang_out';
    await state.addTransaction(Tx(
      id: id, type: txType, date: dueDate, time: getTimeWIB(),
      amount: amt, account: account!, category: 'Utang/Piutang',
      note: type == 'utang' ? 'Pinjam dari $person' : 'Peminjaman ke $person',
    ));
    await state.addDebt(Debt(
      id: id + 1, person: person, type: type, amount: amt,
      account: account!, dueDate: dueDate,
    ));
    state.showPopup('Data Utang/Piutang ditambahkan!');
    setState(() {
      person = '';
      amount = '';
      _personCtrl.clear();
      _amountCtrl.clear();
    });
  }

  Widget _debtRow(Debt d, AppState state) {
    final isUtang = d.type == 'utang';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.person,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUtang ? RetroColor.red200 : RetroColor.green200,
                      border: Border.all(
                          color: isUtang ? RetroColor.red600 : RetroColor.green600,
                          width: 1),
                    ),
                    child: Text(
                      isUtang ? 'UTANG (Saya Pinjam)' : 'PIUTANG (Sy Meminjamkan)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                        color: isUtang ? RetroColor.red700 : RetroColor.green700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(formatRp(d.amount),
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Text(d.status == 'paid' ? 'LUNAS' : 'BELUM LUNAS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: d.status == 'paid' ? RetroColor.green600 : RetroColor.red600,
                )),
            const Spacer(),
            if (d.status == 'unpaid')
              RetroButton(
                color: RetroColor.green400,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                onPressed: () async {
                  final acc = d.account;
                  final txType = d.type == 'utang' ? 'utang_out' : 'piutang_in';
                  await state.addTransaction(Tx(
                    id: DateTime.now().millisecondsSinceEpoch,
                    type: txType, date: getToday(), time: getTimeWIB(),
                    amount: d.amount, account: acc, category: 'Utang/Piutang',
                    note: 'Pelunasan ${d.type} ${d.person}',
                  ));
                  await state.updateDebt(d.copyWith(status: 'paid'));
                  state.showPopup('Utang lunas!');
                },
                child: const Text('LUNAS!', style: TextStyle(fontSize: 10)),
              ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              onPressed: () async {
                final ok = await confirmDialog(
                    context, 'Yakin menghapus riwayat ${d.type} ${d.person}?');
                if (ok) state.deleteDebt(d.id);
              },
            ),
          ]),
        ],
      ),
    );
  }
}
