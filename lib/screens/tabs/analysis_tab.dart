import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common/retro.dart';
import '../../widgets/common/date_filter.dart';

class AnalysisTab extends StatefulWidget {
  final DateRange dateFilter;
  final ValueChanged<DateRange> onDateChanged;
  const AnalysisTab({super.key, required this.dateFilter, required this.onDateChanged});

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  String analysisType = 'expense';
  Set<String> analysisCats = {};
  String analysisAccount = 'Semua';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cats = analysisType == 'expense' ? state.expenseCats : incomeCategories;
    final txs = state.filteredBy(widget.dateFilter.start, widget.dateFilter.end);

    num total = 0;
    final breakdown = <String, num>{};
    for (final t in txs) {
      if (t.type == analysisType && analysisCats.contains(t.category)) {
        if (analysisAccount == 'Semua' || t.account == analysisAccount) {
          total += t.amount;
          breakdown[t.category] = (breakdown[t.category] ?? 0) + t.amount;
        }
      }
    }
    final breakdownList = breakdown.entries
        .map((e) => (name: e.key, amount: e.value))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBox(
          color: RetroColor.cyan100,
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bar_chart, size: 14),
                SizedBox(width: 6),
                Text('ANALISIS KEUANGAN',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.5)),
              ]),
              GlobalDateFilter(value: widget.dateFilter, onChanged: widget.onDateChanged),
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
              const RetroSectionTitle('Pilih Parameter'),
              RetroDropdown<String>(
                label: 'Tipe Transaksi',
                value: analysisType,
                items: const ['expense', 'income'],
                labelOf: (s) => s == 'expense' ? 'Pengeluaran (-)' : 'Pemasukan (+)',
                onChanged: (v) => setState(() {
                  analysisType = v!;
                  analysisCats = {};
                }),
              ),
              const SizedBox(height: 8),
              RetroDropdown<String>(
                label: 'Filter Akun',
                value: analysisAccount,
                items: ['Semua', ...state.accounts],
                labelOf: (s) => s,
                onChanged: (v) => setState(() => analysisAccount = v!),
              ),
              const SizedBox(height: 8),
              const Text('PILIH KATEGORI UNTUK DIANALISIS',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                      color: RetroColor.gray500)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: RetroColor.gray100,
                  border: Border.all(color: RetroColor.ink, width: 1),
                ),
                child: Column(
                  children: [
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: analysisCats.length == cats.length,
                      title: const Text('Pilih Semua',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      onChanged: (v) => setState(() {
                        analysisCats = v == true ? cats.toSet() : {};
                      }),
                    ),
                    for (final c in cats)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: analysisCats.contains(c),
                        title: Text(c, style: const TextStyle(fontSize: 11)),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            analysisCats.add(c);
                          } else {
                            analysisCats.remove(c);
                          }
                        }),
                      ),
                  ],
                ),
              ),
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
              RetroSectionTitle(
                'Hasil Analisis (${analysisType == "expense" ? "Pengeluaran" : "Pemasukan"})',
              ),
              if (analysisCats.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: RetroColor.gray300, width: 1),
                  ),
                  child: const Center(
                    child: Text(
                      'Silakan pilih minimal 1 kategori untuk melihat hasil analisis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: RetroColor.gray400, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: analysisType == 'expense' ? RetroColor.red100 : RetroColor.green100,
                    border: Border.all(color: RetroColor.ink, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL ${analysisType == "expense" ? "PENGELUARAN" : "PEMASUKAN"}',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: RetroColor.gray500),
                      ),
                      Text(formatRp(total),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              color: analysisType == 'expense'
                                  ? RetroColor.red700
                                  : RetroColor.green700)),
                      Text(
                        'Rentang: ${widget.dateFilter.start} s/d ${widget.dateFilter.end}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('RINCIAN PER KATEGORI',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        letterSpacing: 0.8,
                        color: RetroColor.gray500)),
                const SizedBox(height: 8),
                if (breakdownList.isEmpty)
                  const Text('Tidak ada transaksi yang ditemukan.',
                      style: TextStyle(fontSize: 11, color: RetroColor.gray500))
                else
                  for (final b in breakdownList)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${b.name} (${((b.amount / total) * 100).toStringAsFixed(1)}%)',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ),
                              Text(formatRp(b.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: RetroColor.gray200,
                              border: Border.all(color: RetroColor.ink, width: 1),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: (b.amount / total).clamp(0, 1).toDouble(),
                              child: Container(
                                color: analysisType == 'expense'
                                    ? RetroColor.red400
                                    : RetroColor.green400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
