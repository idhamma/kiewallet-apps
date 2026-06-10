import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/portfolio.dart';
import '../../models/transaction.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/common/retro.dart';

class InvestTab extends StatefulWidget {
  const InvestTab({super.key});

  @override
  State<InvestTab> createState() => _InvestTabState();
}

class _InvestTabState extends State<InvestTab> {
  String type = investTypes.first;
  String name = '';
  String amount = '';
  String buyPrice = '';
  String currentPrice = '';
  String marketSymbol = '';
  String? account;
  bool isDeduct = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.accounts.isEmpty) return const SizedBox.shrink();
    account ??= state.accounts.first;
    final inv = state.investSummary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBox(
          color: RetroColor.blue100,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RetroSectionTitle(
                'Ringkasan Aset',
                icon: Icons.show_chart,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => state.toggleHide('invest'),
                      child: Icon(
                          state.hideInvest ? Icons.visibility_off : Icons.visibility,
                          size: 16),
                    ),
                    const SizedBox(width: 8),
                    RetroButton(
                      onPressed: state.marketLoading
                          ? null
                          : () async {
                              final r = await state.refreshMarketPrices();
                              state.showPopup(
                                  'Refresh: ${r.ok} OK, ${r.failed} gagal',
                                  type: r.failed > 0 && r.ok == 0 ? 'error' : 'success');
                            },
                      color: RetroColor.yellow400,
                      shadowOffset: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(state.marketLoading ? Icons.hourglass_top : Icons.refresh,
                            size: 12),
                        const SizedBox(width: 4),
                        const Text('REFRESH', style: TextStyle(fontSize: 9)),
                      ]),
                    ),
                  ],
                ),
              ),
              _summaryCard('Tabungan di Bank', inv.savings, RetroColor.blue700,
                  state.hideInvest),
              const SizedBox(height: 8),
              _summaryCard('Total Nilai Investasi (Saat Ini)', inv.investments,
                  RetroColor.purple400, state.hideInvest),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RetroBox(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RetroSectionTitle('Tambah Aset / Tabungan Baru'),
              RetroDropdown<String>(
                label: 'Jenis Aset',
                value: type,
                items: investTypes,
                labelOf: (s) => s,
                onChanged: (v) => setState(() => type = v!),
                background: RetroColor.yellow50,
              ),
              const SizedBox(height: 8),
              RetroTextField(
                label: 'Nama Emiten / Deskripsi',
                hint: type == 'Saham' ? 'Contoh: BBCA' : 'Contoh: Emas Antam 5g',
                onChanged: (v) => name = v,
              ),
              if (type == 'Tabungan Bank') ...[
                const SizedBox(height: 8),
                RetroDropdown<String>(
                  label: 'Lokasi Bank/Dompet',
                  value: account!,
                  items: state.accounts,
                  labelOf: (s) => s,
                  onChanged: (v) => setState(() => account = v),
                ),
                const SizedBox(height: 8),
                RetroTextField(
                  label: 'Total Saldo Disisihkan (Rp)',
                  hint: 'Akan memotong uang pegangan',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => buyPrice = v,
                ),
              ] else ...[
                const SizedBox(height: 8),
                RetroTextField(
                  label: type == 'Saham' ? 'Kuantitas (Lot)' : 'Kuantitas',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => amount = v,
                ),
                const SizedBox(height: 8),
                RetroTextField(
                  label: type == 'Saham'
                      ? 'Harga Beli Rata-rata (/Lembar)'
                      : 'Harga Beli Rata-rata (Rp)',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => buyPrice = v,
                ),
                const SizedBox(height: 8),
                RetroTextField(
                  label: 'Harga Pasar Saat Ini (Rp) - Opsional',
                  hint: 'Kosongkan jika belum ingin update',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => currentPrice = v,
                  background: RetroColor.blue50,
                ),
                const SizedBox(height: 8),
                RetroTextField(
                  label: 'Market Symbol (auto-fetch opsional)',
                  hint: 'BTC / BBCA / dst',
                  onChanged: (v) => marketSymbol = v,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RetroColor.green50,
                    border: Border.all(color: RetroColor.ink, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Checkbox(
                          value: isDeduct,
                          onChanged: (v) => setState(() => isDeduct = v ?? false),
                        ),
                        const Expanded(
                          child: Text('Potong Saldo Kas untuk Pembelian Aset?',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      ]),
                      if (isDeduct)
                        RetroDropdown<String>(
                          label: 'Pilih Sumber Dana (Akun)',
                          value: account!,
                          items: state.accounts,
                          labelOf: (s) => s,
                          onChanged: (v) => setState(() => account = v),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              RetroButton(
                color: RetroColor.blue400,
                onPressed: () => _save(state),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Center(
                  child: Text('+ SIMPAN KE PORTOFOLIO', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _portfolioTable(state),
      ],
    );
  }

  Widget _summaryCard(String label, num value, Color fg, bool hidden) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: RetroColor.ink, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: RetroColor.gray500)),
          Text(displayRp(value, hidden: hidden),
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: fg,
                  fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Future<void> _save(AppState state) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      state.showPopup('Nama aset wajib diisi!', type: 'error');
      return;
    }
    final bp = num.tryParse(buyPrice) ?? 0;
    if (bp <= 0) {
      state.showPopup('Harga beli/saldo tidak valid!', type: 'error');
      return;
    }
    final qty = type == 'Tabungan Bank' ? 1 : (num.tryParse(amount) ?? 0);
    if (type != 'Tabungan Bank' && qty <= 0) {
      state.showPopup('Kuantitas tidak valid!', type: 'error');
      return;
    }
    final cp = currentPrice.trim().isEmpty ? bp : (num.tryParse(currentPrice) ?? bp);
    final id = DateTime.now().millisecondsSinceEpoch;
    final ok = await confirmDialog(context, 'Simpan $cleanName ke Portofolio?');
    if (!ok) return;

    await state.addPortfolio(PortfolioItem(
      id: id, type: type, name: cleanName,
      amount: qty, buyPrice: bp, currentPrice: cp,
      account: account ?? '', isDeduct: isDeduct, marketSymbol: marketSymbol,
    ));

    if (type != 'Tabungan Bank' && isDeduct) {
      final multiplier = type == 'Saham' ? 100 : 1;
      final totalCost = qty * multiplier * bp;
      await state.addTransaction(Tx(
        id: id + 1, type: 'expense', date: getToday(), time: getTimeWIB(),
        amount: totalCost, account: account ?? '', category: 'Investasi',
        note: 'Beli Aset: $cleanName',
      ));
    }
    state.showPopup('Aset berhasil ditambahkan!');
    setState(() {
      name = '';
      amount = '';
      buyPrice = '';
      currentPrice = '';
      marketSymbol = '';
      isDeduct = false;
    });
  }

  Widget _portfolioTable(AppState state) {
    return RetroBox(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RetroSectionTitle('Daftar Portofolio & Tabungan'),
          if (state.portfolio.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Belum ada portofolio investasi.')),
            ),
          for (final p in state.portfolio) _portfolioRow(p, state),
        ],
      ),
    );
  }

  Widget _portfolioRow(PortfolioItem p, AppState state) {
    final multiplier = p.type == 'Saham' ? 100 : 1;
    final initial =
        p.type == 'Tabungan Bank' ? p.buyPrice : (p.amount * multiplier * p.buyPrice);
    final cur = p.type == 'Tabungan Bank'
        ? p.buyPrice
        : (p.amount * multiplier * (p.currentPrice ?? p.buyPrice));
    final pl = cur - initial;
    final plPct = initial > 0 ? (pl / initial) * 100 : 0;
    final hide = state.hideInvest;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border.all(color: RetroColor.ink, width: 1)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: RetroColor.ink,
                        child: Text(
                          '${p.type}${p.account.isNotEmpty ? " - ${p.account}" : ""}',
                          style: const TextStyle(
                              color: RetroColor.cream, fontSize: 9, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(displayRp(cur, hidden: hide),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: RetroColor.blue700,
                            fontFamily: 'monospace',
                            fontSize: 12)),
                    Text(
                      '${pl > 0 ? '+' : ''}${displayRp(pl, hidden: hide)} (${plPct > 0 ? '+' : ''}${plPct.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: pl < 0 ? RetroColor.red600 : RetroColor.green600,
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Modal: ${displayRp(initial, hidden: hide)}',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                if (p.type != 'Tabungan Bank') ...[
                  const SizedBox(width: 8),
                  Text('Qty: ${p.amount} ${p.type == "Saham" ? "Lot" : ""}',
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                ],
                const Spacer(),
                if (p.type != 'Tabungan Bank')
                  RetroButton(
                    color: RetroColor.green400,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onPressed: () => _sellDialog(p, state),
                    child: const Text('JUAL', style: TextStyle(fontSize: 10)),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: RetroColor.red500),
                  onPressed: () async {
                    final ok = await confirmDialog(
                        context, 'Yakin hapus ${p.name} dari portofolio?');
                    if (ok) state.deletePortfolio(p.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sellDialog(PortfolioItem p, AppState state) async {
    String sellQty = p.amount.toString();
    String sellPrice = (p.currentPrice ?? p.buyPrice).toString();
    String sellAcc = state.accounts.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(builder: (ctx, setSt) {
                  final mult = p.type == 'Saham' ? 100 : 1;
                  final est = (num.tryParse(sellQty) ?? 0) *
                      mult *
                      (num.tryParse(sellPrice) ?? 0);
                  return RetroBox(
                    color: RetroColor.green50,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RetroSectionTitle('Jual: ${p.name}'),
                        RetroTextField(
                          label: 'Kuantitas Dijual',
                          initialValue: sellQty,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => setSt(() => sellQty = v),
                        ),
                        const SizedBox(height: 8),
                        RetroTextField(
                          label: 'Harga Jual (Rp)',
                          initialValue: sellPrice,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setSt(() => sellPrice = v),
                        ),
                        const SizedBox(height: 8),
                        RetroDropdown<String>(
                          label: 'Terima Dana di Akun',
                          value: sellAcc,
                          items: state.accounts,
                          labelOf: (s) => s,
                          onChanged: (v) => setSt(() => sellAcc = v!),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: RetroColor.yellow100,
                            border: Border.all(color: RetroColor.ink, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ESTIMASI PEMASUKAN',
                                  style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w700,
                                      color: RetroColor.gray500)),
                              Text(formatRp(est),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: RetroColor.green700,
                                      fontFamily: 'monospace')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: RetroButton(
                              color: RetroColor.green400,
                              onPressed: () async {
                                final q = num.tryParse(sellQty) ?? 0;
                                final pr = num.tryParse(sellPrice) ?? 0;
                                if (q <= 0 || q > p.amount) {
                                  state.showPopup('Kuantitas tidak valid!',
                                      type: 'error');
                                  return;
                                }
                                final ok = await confirmDialog(ctx,
                                    'Yakin menjual $q ${p.type == "Saham" ? "Lot" : "Unit"} ${p.name}?');
                                if (!ok) return;
                                final m = p.type == 'Saham' ? 100 : 1;
                                final total = q * m * pr;
                                await state.addTransaction(Tx(
                                  id: DateTime.now().millisecondsSinceEpoch,
                                  type: 'income',
                                  date: getToday(),
                                  time: getTimeWIB(),
                                  amount: total,
                                  account: sellAcc,
                                  category: 'Investasi',
                                  note:
                                      'Jual Aset: ${p.name} ($q ${p.type == "Saham" ? "Lot" : "Unit"})',
                                ));
                                if (q >= p.amount) {
                                  await state.deletePortfolio(p.id);
                                } else {
                                  await state.updatePortfolio(
                                      p.copyWith(amount: p.amount - q));
                                }
                                state.showPopup('Penjualan berhasil!');
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                              child: const Center(child: Text('JUAL ASET')),
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
        );
      },
    );
  }
}
