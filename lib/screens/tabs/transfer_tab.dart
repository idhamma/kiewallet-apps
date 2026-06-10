import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common/retro.dart';
import '../../widgets/charts/pie_distribution.dart';

class TransferTab extends StatefulWidget {
  const TransferTab({super.key});

  @override
  State<TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<TransferTab> {
  String date = getToday();
  String time = getTimeWIB();
  String amount = '';
  String adminFee = '';
  String note = '';
  String? from;
  String? to;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.accounts.isEmpty) return const SizedBox.shrink();
    from ??= state.accounts.first;
    to ??= state.accounts.length > 1 ? state.accounts[1] : state.accounts.first;

    final liquid = state.liquidBalances.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = state.totalLiquidCash;

    final slices = [
      for (var i = 0; i < liquid.length; i++)
        PieSlice(liquid[i].key, liquid[i].value, retroColors[i % retroColors.length]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBox(
          color: RetroColor.teal50,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DISTRIBUSI UANG PEGANGAN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const Divider(color: Colors.black, thickness: 4),
              Center(child: PieDistribution(slices: slices, size: 200)),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    const Text('Total Kas Pegangan',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                    Text(displayRp(total, hidden: state.hideLiquid),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < liquid.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: retroColors[i % retroColors.length],
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(liquid[i].key,
                              style: const TextStyle(fontWeight: FontWeight.w900)),
                        ]),
                        Text(displayRp(liquid[i].value, hidden: state.hideLiquid),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                color: RetroColor.green700)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RetroBox(
          color: RetroColor.indigo100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('MUTASI / TRANSFER ANTAR AKUN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const Divider(color: Colors.black, thickness: 4),
              const Text(
                'Catat pemindahan uang dari bank ke e-wallet tanpa mempengaruhi laporan untung-rugi bulan ini!',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              RetroDropdown<String>(
                label: 'Dari Akun (Keluar)',
                value: from!,
                items: state.accounts,
                labelOf: (a) =>
                    '$a (Kas: ${displayRp(state.liquidBalances[a] ?? 0, hidden: state.hideLiquid)})',
                onChanged: (v) => setState(() {
                  from = v;
                  if (from == to) {
                    to = state.accounts
                        .firstWhere((a) => a != from, orElse: () => from!);
                  }
                }),
              ),
              const SizedBox(height: 12),
              RetroDropdown<String>(
                label: 'Ke Akun (Masuk)',
                value: to!,
                items: state.accounts.where((a) => a != from).toList(),
                labelOf: (s) => s,
                onChanged: (v) => setState(() => to = v),
              ),
              const SizedBox(height: 12),
              RetroTextField(
                label: 'Nominal Mutasi (Rp)',
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = v,
              ),
              const SizedBox(height: 12),
              RetroTextField(
                label: 'Biaya Admin (Rp) - Opsional',
                hint: 'Misal: 2500',
                keyboardType: TextInputType.number,
                onChanged: (v) => adminFee = v,
              ),
              const SizedBox(height: 12),
              RetroTextField(label: 'Catatan (opsional)', onChanged: (v) => note = v),
              const SizedBox(height: 16),
              RetroButton(
                color: RetroColor.teal400,
                onPressed: () => _doTransfer(state),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Center(
                  child: Text('LAKUKAN MUTASI', style: TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _doTransfer(AppState state) async {
    if (from == to) {
      state.showPopup('Akun asal dan tujuan tidak boleh sama!', type: 'error');
      return;
    }
    final amt = num.tryParse(amount) ?? 0;
    final admin = num.tryParse(adminFee) ?? 0;
    if (amt <= 0) {
      state.showPopup('Jumlah tidak valid!', type: 'error');
      return;
    }
    final ok = await confirmDialog(
      context, 'Yakin mutasi ${formatRp(amt)} dari $from ke $to?',
    );
    if (!ok) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final txs = <Tx>[
      Tx(id: now, type: 'transfer_out', date: date, time: time, amount: amt,
          account: from!, category: 'Transfer/Mutasi',
          note: 'Transfer ke $to${note.isNotEmpty ? ' - $note' : ''}'),
      Tx(id: now + 1, type: 'transfer_in', date: date, time: time, amount: amt,
          account: to!, category: 'Transfer/Mutasi',
          note: 'Terima dari $from${note.isNotEmpty ? ' - $note' : ''}'),
    ];
    if (admin > 0) {
      txs.add(Tx(id: now + 2, type: 'expense', date: date, time: time, amount: admin,
          account: from!, category: 'Biaya Admin',
          note: 'Biaya admin transfer ke $to'));
    }
    await state.addTransactions(txs);
    state.showPopup('Mutasi Berhasil!');
    setState(() {
      amount = '';
      adminFee = '';
      note = '';
      time = getTimeWIB();
    });
  }
}
