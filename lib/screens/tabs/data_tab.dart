import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/budget.dart';
import '../../state/app_state.dart';
import '../../utils/csv.dart';
import '../../utils/format.dart';
import '../../widgets/common/retro.dart';

class DataTab extends StatelessWidget {
  const DataTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBox(
          color: RetroColor.gray100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('PENGATURAN DATA SERVER',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Status Sinkronisasi:',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                const SizedBox(width: 8),
                Icon(state.user != null ? Icons.check_circle : Icons.storage,
                    size: 14,
                    color: state.user != null ? RetroColor.green600 : RetroColor.red600),
                const SizedBox(width: 4),
                Text(
                  state.user != null ? 'ONLINE (Cloud)' : 'LOKAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: state.user != null ? RetroColor.green600 : RetroColor.red600,
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: RetroButton(
                    color: RetroColor.blue300,
                    onPressed: () async {
                      try {
                        await exportCsv(state.transactions);
                        state.showPopup('Berhasil didownload!');
                      } catch (_) {
                        state.showPopup('Gagal export CSV', type: 'error');
                      }
                    },
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Center(
                        child: Text('BACKUP CSV', style: TextStyle(fontSize: 12))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RetroButton(
                    color: RetroColor.yellow300,
                    onPressed: () async {
                      try {
                        final res = await importCsvPick();
                        if (res == null) return;
                        await state.mergeImported(
                          newTxs: res.transactions,
                          newCats: res.expenseCatsSeen,
                          newAccs: res.accountsSeen,
                        );
                        state.showPopup('Data berhasil diimpor!');
                      } catch (_) {
                        state.showPopup('Gagal import CSV', type: 'error');
                      }
                    },
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Center(
                        child: Text('RESTORE', style: TextStyle(fontSize: 12))),
                  ),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _accountsBox(context, state),
        const SizedBox(height: 12),
        _categoriesBox(context, state),
        const SizedBox(height: 12),
        _budgetsBox(context, state),
      ],
    );
  }

  Widget _accountsBox(BuildContext context, AppState state) {
    return RetroBox(
      color: RetroColor.teal100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('AKUN BANK & DOMPET',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              RetroButton(
                color: Colors.black,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () => _addNameDialog(context, state, 'Akun Baru',
                    'Cth: SeaBank, Cash', (n) => state.addAccount(n)),
                child: const Text('+ BARU', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in state.accounts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                  ),
                  child: Text(a,
                      style:
                          const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoriesBox(BuildContext context, AppState state) {
    return RetroBox(
      color: RetroColor.purple100,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('KATEGORI PENGELUARAN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              RetroButton(
                color: Colors.black,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () => _addNameDialog(context, state, 'Kategori Baru',
                    'Cth: Skincare, Elektronik', (n) => state.addExpenseCat(n)),
                child: const Text('+ BARU', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in state.expenseCats)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                  ),
                  child: Text(c,
                      style:
                          const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgetsBox(BuildContext context, AppState state) {
    return RetroBox(
      color: RetroColor.yellow50,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ATUR KENDALI BUDGET',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              RetroButton(
                color: Colors.black,
                textColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () => _budgetDialog(context, state, null),
                child: const Text('+ BUDGET', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 4),
          if (state.customBudgets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Anda belum memiliki budget khusus.')),
            ),
          for (final b in state.customBudgets) _budgetCard(context, state, b),
        ],
      ),
    );
  }

  Widget _budgetCard(BuildContext context, AppState state, CustomBudget b) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                Text('Mencakup: ${b.categories.join(', ')}',
                    style: const TextStyle(fontSize: 9, color: RetroColor.gray500)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: RetroColor.yellow200,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text('Limit: ${formatRp(b.limit)}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                ),
                if (b.desc.isNotEmpty)
                  Text('"${b.desc}"',
                      style:
                          const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
            onPressed: () => _budgetDialog(context, state, b),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
            onPressed: () async {
              final ok = await confirmDialog(context, 'Yakin hapus budget ${b.name}?');
              if (ok) state.deleteBudget(b.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addNameDialog(BuildContext context, AppState state, String title,
      String hint, Future<bool> Function(String) onSave) async {
    String val = '';
    await showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              color: Colors.transparent,
              child: RetroBox(
                color: RetroColor.purple50,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const Divider(color: Colors.black, thickness: 4),
                    RetroTextField(label: 'Nama', hint: hint, onChanged: (v) => val = v),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: RetroButton(
                          color: RetroColor.green400,
                          onPressed: () async {
                            final ok = await onSave(val);
                            if (ok) {
                              state.showPopup('Berhasil ditambahkan!');
                              if (ctx.mounted) Navigator.pop(ctx);
                            } else {
                              state.showPopup('Sudah ada / nama kosong', type: 'error');
                            }
                          },
                          child: const Center(child: Text('SIMPAN')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RetroButton(
                          color: RetroColor.gray300,
                          onPressed: () => Navigator.pop(ctx),
                          child: const Center(child: Text('BATAL')),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _budgetDialog(
      BuildContext context, AppState state, CustomBudget? existing) async {
    String name = existing?.name ?? '';
    String limit = existing?.limit.toString() ?? '';
    String desc = existing?.desc ?? '';
    final selected = Set<String>.from(existing?.categories ?? const <String>[]);
    final usedByOthers = <String>{
      for (final b in state.customBudgets)
        if (b.id != existing?.id) ...b.categories
    };

    await showDialog(
      context: context,
      builder: (ctx) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(builder: (ctx, setSt) {
                final available =
                    state.expenseCats.where((c) => !usedByOthers.contains(c)).toList();
                return RetroBox(
                  color: RetroColor.yellow50,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(existing == null ? 'BUDGET BARU' : 'EDIT BUDGET',
                          style:
                              const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const Divider(color: Colors.black, thickness: 4),
                      RetroTextField(
                          label: 'Nama Budget',
                          initialValue: name,
                          onChanged: (v) => name = v),
                      const SizedBox(height: 8),
                      const Text('Cakup Pengeluaran Dari:',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      Container(
                        height: 180,
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: available.isEmpty
                            ? const Center(
                                child: Text(
                                    'Semua kategori sudah terpakai di budget lain.',
                                    style: TextStyle(
                                        fontSize: 10, color: RetroColor.gray500)),
                              )
                            : ListView(
                                children: [
                                  for (final c in available)
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      value: selected.contains(c),
                                      title:
                                          Text(c, style: const TextStyle(fontSize: 11)),
                                      onChanged: (v) => setSt(() {
                                        if (v == true) {
                                          selected.add(c);
                                        } else {
                                          selected.remove(c);
                                        }
                                      }),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      RetroTextField(
                        label: 'Limit Bulanan (Rp)',
                        initialValue: limit,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => limit = v,
                      ),
                      const SizedBox(height: 8),
                      RetroTextField(
                          label: 'Deskripsi (opsional)',
                          initialValue: desc,
                          onChanged: (v) => desc = v),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: RetroButton(
                            color: RetroColor.yellow400,
                            onPressed: () async {
                              if (selected.isEmpty) {
                                state.showPopup('Pilih minimal 1 kategori!',
                                    type: 'error');
                                return;
                              }
                              final lim = num.tryParse(limit) ?? 0;
                              if (name.trim().isEmpty || lim <= 0) {
                                state.showPopup('Nama & limit wajib!', type: 'error');
                                return;
                              }
                              final b = CustomBudget(
                                id: existing?.id ??
                                    DateTime.now().millisecondsSinceEpoch,
                                name: name,
                                limit: lim,
                                categories: selected.toList(),
                                desc: desc,
                              );
                              await state.upsertBudget(b);
                              state.showPopup('Budget diperbarui!');
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: const Center(child: Text('SIMPAN')),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RetroButton(
                            color: RetroColor.gray300,
                            onPressed: () => Navigator.pop(ctx),
                            child: const Center(child: Text('BATAL')),
                          ),
                        ),
                      ]),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
