import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';
import '../widgets/common/retro.dart';
import '../widgets/common/popup_overlay.dart';
import '../widgets/common/date_filter.dart';

import 'tabs/dashboard_tab.dart';
import 'tabs/cashflow_tab.dart';
import 'tabs/transfer_tab.dart';
import 'tabs/invest_tab.dart';
import 'tabs/debt_tab.dart';
import 'tabs/recurring_tab.dart';
import 'tabs/analysis_tab.dart';
import 'tabs/data_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String activeTab = 'dashboard';
  DateRange dateFilter = DateRange(getStartOfMonth(), getEndOfMonth());

  void _setTab(String t) => setState(() => activeTab = t);

  Widget _body() {
    switch (activeTab) {
      case 'dashboard':
        return DashboardTab(
          dateFilter: dateFilter,
          onDateChanged: (r) => setState(() => dateFilter = r),
          goTransfer: () => _setTab('transfer'),
          goData: () => _setTab('data'),
        );
      case 'income':
        return const CashFlowTab(type: 'income');
      case 'expense':
        return const CashFlowTab(type: 'expense');
      case 'transfer':
        return const TransferTab();
      case 'invest':
        return const InvestTab();
      case 'debt':
        return const DebtTab();
      case 'recurring':
        return const RecurringTab();
      case 'analysis':
        return AnalysisTab(
          dateFilter: dateFilter,
          onDateChanged: (r) => setState(() => dateFilter = r),
        );
      case 'data':
        return const DataTab();
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: RetroColor.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(onLogout: () => state.auth.signOut()),
                _NavTabs(active: activeTab, onTab: _setTab),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: _body(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const PopupOverlay(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onLogout;
  const _Header({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: RetroColor.yellow400,
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                ),
                child: const Icon(Icons.videogame_asset, size: 22),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KieWallet',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Text('Jangan boros boros le',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          RetroButton(
            color: RetroColor.red500,
            textColor: Colors.white,
            onPressed: onLogout,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text('LOGOUT', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _NavTabs extends StatelessWidget {
  final String active;
  final ValueChanged<String> onTab;
  const _NavTabs({required this.active, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final tabs = <(String, IconData, String, Color)>[
      ('dashboard', Icons.list, 'Dashboard', RetroColor.purple400),
      ('income', Icons.trending_up, '+ Kas', RetroColor.green400),
      ('expense', Icons.trending_down, '- Kas', RetroColor.red400),
      ('transfer', Icons.swap_horiz, 'Mutasi', RetroColor.teal400),
      ('invest', Icons.account_balance, 'Investasi', RetroColor.blue400),
      ('debt', Icons.people, 'Utang', RetroColor.orange400),
      ('recurring', Icons.repeat, 'Rutin', RetroColor.pink400),
      ('analysis', Icons.bar_chart, 'Analisis', RetroColor.cyan100),
      ('data', Icons.storage, 'Data', RetroColor.gray400),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in tabs) ...[
              RetroButton(
                onPressed: () => onTab(t.$1),
                color: active == t.$1 ? t.$4 : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.$2, size: 14),
                    const SizedBox(width: 4),
                    Text(t.$3, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ]
          ],
        ),
      ),
    );
  }
}
