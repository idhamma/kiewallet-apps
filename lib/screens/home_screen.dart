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
import 'tabs/scan_tab.dart';
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
      case 'scan':
        return const ScanTab();
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
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
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
        border: Border(bottom: BorderSide(color: RetroColor.ink, width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: RetroColor.ink),
                child: const Icon(Icons.videogame_asset,
                    size: 18, color: RetroColor.cream),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('KIEWALLET',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: RetroColor.ink)),
                  Text('jangan boros boros le',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          color: RetroColor.gray500)),
                ],
              ),
            ],
          ),
          RetroButton(
            color: Colors.white,
            onPressed: onLogout,
            shadowOffset: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: const Text('LOGOUT', style: TextStyle(fontSize: 10)),
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
    const tabs = <(String, IconData, String)>[
      ('dashboard', Icons.grid_view, 'Dashboard'),
      ('income', Icons.south_west, '+ Kas'),
      ('expense', Icons.north_east, '- Kas'),
      ('scan', Icons.document_scanner_outlined, 'Scan AI'),
      ('transfer', Icons.swap_horiz, 'Mutasi'),
      ('invest', Icons.show_chart, 'Investasi'),
      ('debt', Icons.people_outline, 'Utang'),
      ('recurring', Icons.repeat, 'Rutin'),
      ('analysis', Icons.bar_chart, 'Analisis'),
      ('data', Icons.inventory_2_outlined, 'Data'),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RetroColor.ink, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final t in tabs) ...[
              _NavButton(
                icon: t.$2,
                label: t.$3,
                active: active == t.$1,
                onTap: () => onTab(t.$1),
              ),
              const SizedBox(width: 6),
            ]
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? RetroColor.cream : RetroColor.ink;
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? RetroColor.ink : Colors.transparent,
          border: Border.all(
            color: active ? RetroColor.ink : RetroColor.gray300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
