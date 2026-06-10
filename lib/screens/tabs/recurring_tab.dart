import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/recurring.dart';
import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common/retro.dart';

class RecurringTab extends StatefulWidget {
  const RecurringTab({super.key});

  @override
  State<RecurringTab> createState() => _RecurringTabState();
}

class _RecurringTabState extends State<RecurringTab> {
  String name = '';
  String amount = '';
  String category = 'Tagihan';
  String periodType = 'monthly';
  int dayOfMonth = 1;
  String dayOfWeek = 'Senin';
  String? account;

  final _nameCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.accounts.isEmpty) return const SizedBox.shrink();
    account ??= state.accounts.first;
    final cats = state.expenseCats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBox(
          color: RetroColor.pink100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('TAGIHAN RUTIN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const Divider(color: Colors.black, thickness: 4),
              RetroTextField(
                label: 'Nama Tagihan',
                controller: _nameCtrl,
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 8),
              RetroDropdown<String>(
                label: 'Kategori',
                value: cats.contains(category) ? category : cats.first,
                items: cats,
                labelOf: (s) => s,
                onChanged: (v) => setState(() => category = v!),
              ),
              const SizedBox(height: 8),
              RetroDropdown<String>(
                label: 'Periode',
                value: periodType,
                items: const ['monthly', 'weekly'],
                labelOf: (s) => s == 'monthly' ? 'Bulanan' : 'Mingguan',
                onChanged: (v) => setState(() => periodType = v!),
              ),
              const SizedBox(height: 8),
              if (periodType == 'monthly')
                RetroTextField(
                  label: 'Tanggal (1-31)',
                  initialValue: dayOfMonth.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => dayOfMonth = int.tryParse(v) ?? 1,
                )
              else
                RetroDropdown<String>(
                  label: 'Hari',
                  value: dayOfWeek,
                  items: daysOfWeek,
                  labelOf: (s) => s,
                  onChanged: (v) => setState(() => dayOfWeek = v!),
                ),
              const SizedBox(height: 8),
              RetroTextField(
                label: 'Nominal (Rp)',
                controller: _amtCtrl,
                keyboardType: TextInputType.number,
                onChanged: (v) => amount = v,
              ),
              const SizedBox(height: 8),
              RetroDropdown<String>(
                label: 'Akun Default',
                value: account!,
                items: state.accounts,
                labelOf: (s) => s,
                onChanged: (v) => setState(() => account = v),
              ),
              const SizedBox(height: 12),
              RetroButton(
                color: Colors.black,
                textColor: Colors.white,
                onPressed: () => _save(state),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: const Center(
                    child: Text('+ SIMPAN TAGIHAN', style: TextStyle(fontSize: 13))),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state.recurring.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text('Belum ada tagihan rutin disetel.',
                    style: TextStyle(
                        color: RetroColor.gray400, fontWeight: FontWeight.w700))),
          ),
        for (final r in state.recurring) _recurringCard(r, state),
      ],
    );
  }

  Future<void> _save(AppState state) async {
    final amt = num.tryParse(amount) ?? 0;
    if (name.trim().isEmpty || amt <= 0) {
      state.showPopup('Nama & nominal wajib!', type: 'error');
      return;
    }
    await state.addRecurring(Recurring(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name, amount: amt, account: account!, category: category,
      periodType: periodType, dayOfMonth: dayOfMonth, dayOfWeek: dayOfWeek,
    ));
    state.showPopup('Tagihan Rutin Tersimpan!');
    setState(() {
      name = '';
      amount = '';
      _nameCtrl.clear();
      _amtCtrl.clear();
    });
  }

  Widget _recurringCard(Recurring r, AppState state) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    Text(
                      '${r.periodType == "weekly" ? "Tiap ${r.dayOfWeek}" : "Tiap Tgl ${r.dayOfMonth}"} • ${r.category}',
                      style: const TextStyle(fontSize: 10, color: RetroColor.gray500),
                    ),
                    Text(formatRp(r.amount),
                        style: const TextStyle(
                            color: RetroColor.red600,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                onPressed: () async {
                  final ok = await confirmDialog(
                      context, 'Yakin menghapus tagihan ${r.name}?');
                  if (ok) state.deleteRecurring(r.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          RetroButton(
            color: RetroColor.yellow400,
            onPressed: () async {
              await state.addTransaction(Tx(
                id: DateTime.now().millisecondsSinceEpoch,
                type: 'expense', date: getToday(), time: getTimeWIB(),
                amount: r.amount, account: r.account, category: r.category,
                note: 'Tagihan Rutin: ${r.name}',
              ));
              state.showPopup('Tagihan ${r.name} berhasil dicatat!');
            },
            child: const Center(child: Text('BAYAR SEKARANG')),
          ),
        ],
      ),
    );
  }
}
