import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../state/app_state.dart';
import '../../models/transaction.dart';
import '../../utils/format.dart';
import '../../widgets/common/retro.dart';
import '../../widgets/common/date_filter.dart';
import '../../widgets/charts/advanced_cash_flow.dart';

class DashboardTab extends StatelessWidget {
  final DateRange dateFilter;
  final ValueChanged<DateRange> onDateChanged;
  final VoidCallback goTransfer;
  final VoidCallback goData;

  const DashboardTab({
    super.key,
    required this.dateFilter,
    required this.onDateChanged,
    required this.goTransfer,
    required this.goData,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = state.filteredBy(dateFilter.start, dateFilter.end);
    final summary = state.summaryFor(filtered);
    final liquid = state.totalLiquidCash;
    final networth = state.totalNetWorth;

    final chartPoints = _buildChartPoints(filtered, dateFilter);
    final expByCat = _expensesByCategory(filtered);
    final liquidByAcc = state.liquidBalances.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RetroBox(
          color: RetroColor.blue100,
          child: GlobalDateFilter(value: dateFilter, onChanged: onDateChanged),
        ),
        const SizedBox(height: 12),
        _summaryGrid(context, state, summary, liquid, networth),
        const SizedBox(height: 12),
        RetroBox(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RetroSectionTitle('Grafik Cash Flow', icon: Icons.show_chart),
              AdvancedCashFlow(
                data: chartPoints,
                hideIncome: state.hideIncome,
                hideExpense: state.hideExpense,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RetroBox(
          color: RetroColor.pink100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RetroSectionTitle(
                'Kas Pegangan (Liquid)',
                trailing: RetroButton(
                  onPressed: goTransfer,
                  color: Colors.white,
                  shadowOffset: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: const Text('DETAIL MUTASI', style: TextStyle(fontSize: 9)),
                ),
              ),
              if (liquidByAcc.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Belum ada saldo liquid.')),
                ),
              for (final e in liquidByAcc)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      Text(
                        displayRp(e.value, hidden: state.hideLiquid),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: e.value < 0 ? RetroColor.red600 : RetroColor.green700,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RetroSectionTitle('Top Pengeluaran'),
              if (expByCat.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Belum ada pengeluaran')),
                ),
              for (var i = 0; i < expByCat.length; i++)
                _expensesBar(expByCat[i], expByCat.first.amount, state.hideExpense, i),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _historyTable(context, state, filtered),
      ],
    );
  }

  Widget _summaryGrid(BuildContext ctx, AppState s,
      ({num income, num expense, num balance}) sum, num liquid, num networth) {
    Widget card(String label, num value, Color bg, Color fg, bool hidden, String hideKey) {
      return RetroBox(
        color: bg,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: RetroColor.gray500)),
                ),
                InkWell(
                  onTap: () => s.toggleHide(hideKey),
                  child: Icon(hidden ? Icons.visibility_off : Icons.visibility, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              displayRp(value, hidden: hidden),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(builder: (ctx, c) {
      final wide = c.maxWidth >= 700;
      final cards = [
        card('Pemasukan', sum.income, Colors.white, RetroColor.green700, s.hideIncome, 'income'),
        card('Pengeluaran', sum.expense, Colors.white, RetroColor.red700, s.hideExpense, 'expense'),
        card('Kas Pegangan', liquid, RetroColor.teal100, RetroColor.teal900, s.hideLiquid, 'liquid'),
        card('Saldo Periode', sum.balance, RetroColor.yellow200,
            sum.balance < 0 ? RetroColor.red700 : RetroColor.ink, s.hidePeriod, 'period'),
      ];
      return Column(children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: wide ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: wide ? 2.4 : 1.6,
          children: cards,
        ),
        const SizedBox(height: 12),
        RetroBox(
          color: RetroColor.indigo100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                        child: Text('Kekayaan Bersih Total (Net Worth)',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: RetroColor.indigo900)),
                      ),
                      InkWell(
                        onTap: () => s.toggleHide('networth'),
                        child: Icon(
                            s.hideNetWorth ? Icons.visibility_off : Icons.visibility,
                            size: 14),
                      ),
                    ]),
                    const Text('Liquid Kas + Investasi & Tabungan + Piutang - Utang',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              Text(
                displayRp(networth, hidden: s.hideNetWorth),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: networth < 0 ? RetroColor.red600 : RetroColor.blue700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ]);
    });
  }

  Widget _expensesBar(({String name, num amount}) item, num max, bool hidden, int idx) {
    final pct = ((item.amount / max) * 100).clamp(5, 100).toDouble();
    final colors = [RetroColor.pink400, RetroColor.purple400, RetroColor.orange400, RetroColor.gray400];
    final bar = colors[idx >= 3 ? 3 : idx];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
              ),
              Text(displayRp(item.amount, hidden: hidden),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
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
              widthFactor: pct / 100,
              child: Container(color: bar),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyTable(BuildContext ctx, AppState state, List<Tx> txs) {
    return RetroBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RetroSectionTitle('History Transaksi'),
          if (txs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Tidak ada transaksi di rentang ini')),
            ),
          for (final t in txs.take(40))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: RetroColor.ink,
                    child: Text(t.account,
                        style: const TextStyle(
                            color: RetroColor.cream, fontSize: 9, letterSpacing: 0.5)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.category.isEmpty ? t.type.toUpperCase() : t.category,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                        Text('${t.date}${t.time != null ? '  ${t.time} WIB' : ''}',
                            style: const TextStyle(fontSize: 10, color: RetroColor.gray500)),
                      ],
                    ),
                  ),
                  Text(
                    '${t.isInflow ? '+' : '-'}${formatRp(t.amount)}',
                    style: TextStyle(
                      color: t.isInflow ? RetroColor.green600 : RetroColor.red600,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: RetroColor.red500),
                    onPressed: () async {
                      final ok = await confirmDialog(ctx, 'Yakin menghapus transaksi ini?');
                      if (ok) state.deleteTransaction(t.id);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

List<CashFlowPoint> _buildChartPoints(List<Tx> txs, DateRange range) {
  final start = DateTime.parse(range.start);
  final end = DateTime.parse(range.end);
  final diffDays = end.difference(start).inDays;

  if (diffDays == 0) {
    final inc = List<double>.filled(24, 0);
    final exp = List<double>.filled(24, 0);
    for (final t in txs) {
      if ((t.type == 'income' || t.type == 'expense') && t.time != null) {
        final h = int.tryParse(t.time!.substring(0, 2));
        if (h == null || h < 0 || h > 23) continue;
        if (t.type == 'income') {
          inc[h] += t.amount.toDouble();
        } else {
          exp[h] += t.amount.toDouble();
        }
      }
    }
    return [for (var i = 0; i < 24; i++)
      CashFlowPoint(i.toString().padLeft(2, '0'),
          '${i.toString().padLeft(2, '0')}:00', inc[i], exp[i])];
  } else if (diffDays <= 31) {
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final isWeek = diffDays <= 7;
    final out = <CashFlowPoint>[];
    for (var i = 0; i <= diffDays; i++) {
      final d = start.add(Duration(days: i));
      final iso = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      double inc = 0, exp = 0;
      for (final t in txs) {
        if (t.date != iso) continue;
        if (t.type == 'income') inc += t.amount.toDouble();
        if (t.type == 'expense') exp += t.amount.toDouble();
      }
      out.add(CashFlowPoint(iso, isWeek ? days[d.weekday % 7] : d.day.toString(), inc, exp));
    }
    return out;
  } else {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    final inc = List<double>.filled(12, 0);
    final exp = List<double>.filled(12, 0);
    for (final t in txs) {
      final m = DateTime.parse(t.date).month - 1;
      if (t.type == 'income') inc[m] += t.amount.toDouble();
      if (t.type == 'expense') exp[m] += t.amount.toDouble();
    }
    return [for (var i = 0; i < 12; i++) CashFlowPoint(i.toString(), months[i], inc[i], exp[i])];
  }
}

List<({String name, num amount})> _expensesByCategory(List<Tx> txs) {
  final map = <String, num>{};
  for (final t in txs) {
    if (t.type == 'expense') {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
  }
  final out = map.entries.map((e) => (name: e.key, amount: e.value)).toList();
  out.sort((a, b) => b.amount.compareTo(a.amount));
  return out;
}
